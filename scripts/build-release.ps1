[CmdletBinding()]
param(
    [string]$OutputDirectory = (Join-Path (Split-Path $PSScriptRoot -Parent) 'dist'),
    [switch]$Force,
    [switch]$NonInteractive
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path $PSScriptRoot -Parent
. (Join-Path $PSScriptRoot 'lib/mods.ps1')

# Compare dot-separated version strings numerically (e.g. 1.18.4 vs 1.18.10).
# Returns >0 if $Left is newer, <0 if older, 0 if equal.
function Compare-ModVersion {
    param([string]$Left, [string]$Right)
    $parts = {
        param([string]$Version)
        @($Version -split '[.\-]' | ForEach-Object {
            $m = [regex]::Match($_, '^\d+')
            if ($m.Success) { [int]$m.Value } else { 0 }
        })
    }
    $l = & $parts $Left
    $r = & $parts $Right
    $n = [Math]::Max($l.Count, $r.Count)
    for ($i = 0; $i -lt $n; $i++) {
        $lv = if ($i -lt $l.Count) { $l[$i] } else { 0 }
        $rv = if ($i -lt $r.Count) { $r[$i] } else { 0 }
        if ($lv -ne $rv) { return ($lv - $rv) }
    }
    return 0
}

$mods = @(Get-ModInventory -RepositoryRoot $repositoryRoot)

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$artifacts = @()
$syncNeeded = @()

foreach ($mod in $mods) {
    $source = Join-Path (Join-Path $repositoryRoot $mod.Root) $mod.Source
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

    $version = $versionMatch.Groups[1].Value
    $artifactName = $mod.Artifact + '-v' + $version
    $stagingDirectory = Join-Path $OutputDirectory ($artifactName + '-staging')
    $archivePath = Join-Path $OutputDirectory ($artifactName + '.zip')

    # If dist already contains a NEWER version of this artifact (committed by another
    # author), keep it and skip the build — never downgrade dist.
    $existingZips = @(Get-ChildItem $OutputDirectory -Filter "$($mod.Artifact)-v*.zip" -File)
    $newestExisting = $null
    foreach ($existing in $existingZips) {
        $existingVersion = [regex]::Match($existing.Name, 'v(.+)\.zip$').Groups[1].Value
        if ($null -eq $newestExisting -or (Compare-ModVersion $existingVersion $newestExisting) -gt 0) {
            $newestExisting = $existingVersion
        }
    }

    # Effective version = the newer of local and what's already in dist.
    # Never downgrade: if another author committed a newer version, keep it.
    $effectiveVersion = $version
    if ($null -ne $newestExisting -and (Compare-ModVersion $newestExisting $version) -gt 0) {
        $effectiveVersion = $newestExisting
    }

    # Remove all versioned zips older than the effective version
    $oldZips = $existingZips | Where-Object {
        $oldVersion = [regex]::Match($_.Name, 'v(.+)\.zip$').Groups[1].Value
        (Compare-ModVersion $oldVersion $effectiveVersion) -lt 0
    }
    foreach ($old in $oldZips) {
        Remove-Item $old.FullName -Force
        Write-Host "Removed old zip: $($old.Name)"
    }

    # If dist already has a newer version (committed by another author), offer to
    # sync it back into the local mod source so the repo stays consistent.
    if ($effectiveVersion -ne $version) {
        Write-Host ""
        Write-Host "=== $($mod.Artifact): dist has newer version $effectiveVersion (local $version) ==="
        $existingZip = Get-Item (Join-Path $OutputDirectory "$($mod.Artifact)-v$effectiveVersion.zip")

        # Extract the dist zip to a temp dir for comparison
        $extractDir = Join-Path $env:TEMP "eoe-dist-sync-$($mod.Artifact)"
        if (Test-Path $extractDir) { Remove-Item $extractDir -Recurse -Force }
        Expand-Archive -Path $existingZip.FullName -DestinationPath $extractDir

        # Generate a unified diff (patch) of local source vs dist contents
        $patchDir = Join-Path $repositoryRoot 'patches'
        New-Item -ItemType Directory -Path $patchDir -Force | Out-Null
        $patchPath = Join-Path $patchDir "$($mod.Artifact)-v$effectiveVersion.patch"
        & git diff --no-index $source $extractDir > $patchPath 2>$null
        if ($LASTEXITCODE -gt 1) { throw "git diff failed for $($mod.Artifact) (exit $LASTEXITCODE)" }

        # Summarize changed files from the patch
        $changedFiles = @()
        foreach ($line in (Get-Content $patchPath)) {
            if ($line -match '^diff --git \S+ b/(\S+)') { $changedFiles += $Matches[1] }
        }
        Write-Host "Changed files ($($changedFiles.Count)) — full patch: $patchPath"
        foreach ($f in $changedFiles) { Write-Host "  - $f" }

        $synced = $false
        if ($Force) {
            $synced = $true
        } elseif ($NonInteractive) {
            # CI mode: don't sync, just record that this mod needs syncing
            $syncNeeded += [pscustomobject][ordered]@{
                artifact = $mod.Artifact
                mod = "$($mod.Root)/$($mod.Source)"
                localVersion = $version
                distVersion = $effectiveVersion
                patch = (Resolve-Path $patchPath).Path.Substring($repositoryRoot.Length + 1)
            }
        } else {
            $answer = Read-Host "Overwrite local $($mod.Artifact) source with dist v$effectiveVersion? (y/N)"
            if ($answer -eq 'y' -or $answer -eq 'Y') { $synced = $true }
        }

        if ($synced) {
            Get-ChildItem $extractDir -Recurse -File | ForEach-Object {
                $rel = $_.FullName.Substring($extractDir.Length + 1)
                $dest = Join-Path $source $rel
                New-Item -ItemType Directory -Path (Split-Path $dest) -Force | Out-Null
                Copy-Item $_.FullName $dest -Force
            }
            Remove-Item $extractDir -Recurse -Force
            Write-Host "Synced $($mod.Artifact) source to v$effectiveVersion — rebuilding"
            # Local source now matches dist; continue with a normal build at the new version
            $version = $effectiveVersion
            $artifactName = $mod.Artifact + '-v' + $version
            $stagingDirectory = Join-Path $OutputDirectory ($artifactName + '-staging')
            $archivePath = Join-Path $OutputDirectory ($artifactName + '.zip')
        } else {
            Remove-Item $extractDir -Recurse -Force
            Write-Host "Skipped sync for $($mod.Artifact) — keeping dist v$effectiveVersion as-is"
            $artifacts += [pscustomobject][ordered]@{
                artifact = $existingZip.Name
                mod = "$($mod.Root)/$($mod.Source)"
                workshopId = $mod.WorkshopId
                version = $effectiveVersion
                size = $existingZip.Length
                sha256 = (Get-FileHash $existingZip.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
            }
            continue
        }
    }

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
        mod = "$($mod.Root)/$($mod.Source)"
        workshopId = $mod.WorkshopId
        version = $version
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

# Write sync-needed.json so CI can detect mods where dist is newer than source
$syncNeededPath = Join-Path $OutputDirectory 'sync-needed.json'
if ($syncNeeded.Count -gt 0) {
    [IO.File]::WriteAllText($syncNeededPath, ($syncNeeded | ConvertTo-Json -Depth 5) + "`n", [Text.UTF8Encoding]::new($false))
    Write-Host "Wrote $syncNeededPath ($($syncNeeded.Count) mod(s) need syncing)"
} else {
    if (Test-Path $syncNeededPath) { Remove-Item $syncNeededPath -Force }
    Write-Host "No mods need syncing"
}