[CmdletBinding()]
param(
    [string]$OutputDirectory = (Join-Path (Split-Path $PSScriptRoot -Parent) 'dist')
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path $PSScriptRoot -Parent
. (Join-Path $PSScriptRoot 'lib/mods.ps1')

$mods = @(Get-ModInventory -RepositoryRoot $repositoryRoot)

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$artifacts = @()

foreach ($mod in $mods) {
    $source = Join-Path (Join-Path $repositoryRoot 'mods') $mod.Source
    $descriptorPath = Join-Path $source 'descriptor.mod'
    if (-not (Test-Path $descriptorPath)) {
        throw "Missing source descriptor: $descriptorPath"
    }

    $descriptor = Get-Content $descriptorPath -Raw
    $versionMatch = [regex]::Match($descriptor, '(?m)^version\s*=\s*"([^"]+)"')
    if (-not $versionMatch.Success) {
        throw "Missing version in $descriptorPath"
    }
    if ($descriptor -match 'DEV_VERSION' -or $descriptor -match '(?m)^\s*path\s*=') {
        throw "Source descriptor contains DEV-only metadata: $descriptorPath"
    }

    $artifactName = $mod.Artifact + '-v' + $versionMatch.Groups[1].Value
    $stagingDirectory = Join-Path $OutputDirectory ($artifactName + '-staging')
    $archivePath = Join-Path $OutputDirectory ($artifactName + '.zip')

    if (Test-Path $stagingDirectory) {
        Remove-Item $stagingDirectory -Recurse -Force
    }
    if (Test-Path $archivePath) {
        Remove-Item $archivePath -Force
    }
    New-Item -ItemType Directory -Path $stagingDirectory -Force | Out-Null

    Get-ChildItem $source -Recurse -File -Force |
        Where-Object { $_.FullName -notmatch '[\\/]\.vscode[\\/]' } |
        ForEach-Object {
            $relative = $_.FullName.Substring($source.Length + 1)
            $destination = Join-Path $stagingDirectory $relative
            New-Item -ItemType Directory -Path (Split-Path $destination) -Force | Out-Null
            Copy-Item $_.FullName $destination -Force
        }

    Compress-Archive -Path (Join-Path $stagingDirectory '*') -DestinationPath $archivePath -CompressionLevel Optimal
    Remove-Item $stagingDirectory -Recurse -Force

    $archive = [IO.Compression.ZipFile]::OpenRead($archivePath)
    try {
        $entries = @($archive.Entries | ForEach-Object { $_.FullName.Replace('\', '/') })
        if ('descriptor.mod' -notin $entries) {
            throw "Archive does not contain descriptor.mod at its root: $archivePath"
        }

        $forbidden = @($entries | Where-Object {
            $_ -match '(^|/)\.vscode/' -or
            $_ -match '(^|/)(\.env(?:\..*)?|local\.env|steam-creds[^/]*)$' -or
            $_ -match '(^|/)steamcmd/' -or
            $_ -match '(^|/)(build|dist)/'
        })
        if ($forbidden.Count -gt 0) {
            throw "Archive contains forbidden local content: $($forbidden -join ', ')"
        }
    }
    finally {
        $archive.Dispose()
    }

    $archiveInfo = Get-Item $archivePath
    $artifacts += [pscustomobject][ordered]@{
        artifact = $archiveInfo.Name
        mod = "mods/$($mod.Source)"
        workshopId = $mod.WorkshopId
        version = $versionMatch.Groups[1].Value
        size = $archiveInfo.Length
        sha256 = (Get-FileHash $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
    }
    Write-Host "Built $archivePath"
}

$manifestPath = Join-Path $OutputDirectory 'release-checksums.json'
$manifest = [pscustomobject][ordered]@{
    schemaVersion = 1
    artifacts = $artifacts
}
[IO.File]::WriteAllText(
    $manifestPath,
    ($manifest | ConvertTo-Json -Depth 5) + "`n",
    [Text.UTF8Encoding]::new($false)
)
Write-Host "Wrote $manifestPath"