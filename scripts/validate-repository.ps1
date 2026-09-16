[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path $PSScriptRoot -Parent
. (Join-Path $PSScriptRoot 'lib/mods.ps1')
$failures = [Collections.Generic.List[string]]::new()
$warnings = [Collections.Generic.List[string]]::new()

function Get-RelativePath {
    param([Parameter(Mandatory)][string]$Path)

    return [IO.Path]::GetRelativePath($repositoryRoot, $Path).Replace('\', '/')
}

function Add-ValidationFailure {
    param(
        [Parameter(Mandatory)][string]$Message,
        [string]$Path
    )

    $failures.Add($Message)
    if ($Path) {
        Write-Host "::error file=$Path::$Message"
    }
    else {
        Write-Host "::error::$Message"
    }
}

function Add-ValidationWarning {
    param(
        [Parameter(Mandatory)][string]$Message,
        [string]$Path
    )

    $warnings.Add($Message)
    if ($Path) {
        Write-Host "::warning file=$Path::$Message"
    }
    else {
        Write-Host "::warning::$Message"
    }
}

$modDirectories = @(Get-ModInventory -RepositoryRoot $repositoryRoot | ForEach-Object { "$($_.Root)/$($_.Source)" })

foreach ($relativeModDirectory in $modDirectories) {
    $descriptorPath = Join-Path $repositoryRoot $relativeModDirectory 'descriptor.mod'
    $relativeDescriptorPath = "$relativeModDirectory/descriptor.mod"

    if (-not (Test-Path -LiteralPath $descriptorPath -PathType Leaf)) {
        Add-ValidationFailure -Message "Missing descriptor: $relativeDescriptorPath" -Path $relativeDescriptorPath
        continue
    }

    $descriptor = Get-Content -LiteralPath $descriptorPath -Raw
    if ($descriptor -notmatch '(?m)^version\s*=\s*"[^"]+"\s*$') {
        Add-ValidationFailure -Message 'Descriptor has no valid version field.' -Path $relativeDescriptorPath
    }
    if ($descriptor -notmatch '(?m)^supported_version\s*=\s*"[^"]+"\s*$') {
        Add-ValidationFailure -Message 'Descriptor has no valid supported_version field.' -Path $relativeDescriptorPath
    }
    if ($descriptor -match 'DEV_VERSION') {
        Add-ValidationFailure -Message 'Source descriptor contains DEV_VERSION.' -Path $relativeDescriptorPath
    }
    if ($descriptor -match '(?m)^\s*path\s*=') {
        Add-ValidationFailure -Message 'Source descriptor contains a local path field.' -Path $relativeDescriptorPath
    }
}

$modsRoots = @('eoe-mods', 'other_mods') | ForEach-Object { Join-Path $repositoryRoot $_ }
$forbiddenEntries = foreach ($root in $modsRoots) {
    Get-ChildItem -LiteralPath $root -Recurse -Force | Where-Object {
        $_.PSIsContainer -and $_.Name -in @('.vscode', 'steamcmd') -or
        -not $_.PSIsContainer -and (
            $_.Name -match '^\.env(?:\..*)?$' -or
            $_.Name -eq 'local.env' -or
            $_.Name -like 'steam-creds*'
        )
    }
}
foreach ($entry in $forbiddenEntries) {
    $relativePath = Get-RelativePath -Path $entry.FullName
    Add-ValidationFailure -Message 'Forbidden local-only content under eoe-mods/ or other_mods/.' -Path $relativePath
}

$localizationFiles = foreach ($root in $modsRoots) {
    Get-ChildItem -LiteralPath $root -Recurse -File -Filter '*.yml' |
        Where-Object { $_.FullName -match '[\\/]localization[\\/]' }
}
$strictUtf8 = [Text.UTF8Encoding]::new($false, $true)

foreach ($file in $localizationFiles) {
    $relativePath = Get-RelativePath -Path $file.FullName
    $bytes = [IO.File]::ReadAllBytes($file.FullName)
    $hasBom = $bytes.Length -ge 3 -and
        $bytes[0] -eq 0xEF -and
        $bytes[1] -eq 0xBB -and
        $bytes[2] -eq 0xBF

    if (-not $hasBom) {
        Add-ValidationFailure -Message 'Localization file must start with a UTF-8 BOM.' -Path $relativePath
        continue
    }

    try {
        $content = $strictUtf8.GetString($bytes, 3, $bytes.Length - 3)
    }
    catch {
        Add-ValidationFailure -Message 'Localization file contains invalid UTF-8.' -Path $relativePath
        continue
    }

    $lines = $content -split "`r?`n"
    if ($lines.Count -eq 0 -or $lines[0] -notmatch '^l_[a-z_]+:\s*$') {
        Add-ValidationFailure -Message 'Localization file has an invalid language header.' -Path $relativePath
    }

    $keys = foreach ($line in $lines) {
        if ($line -match '^\s+([^\s#:]+):(?:\d+)?\s') {
            $Matches[1]
        }
    }
    $duplicateKeys = @($keys | Group-Object | Where-Object Count -gt 1 | Select-Object -ExpandProperty Name)
    if ($duplicateKeys.Count -gt 0) {
        $preview = ($duplicateKeys | Select-Object -First 10) -join ', '
        if ($duplicateKeys.Count -gt 10) {
            $preview += ", and $($duplicateKeys.Count - 10) more"
        }
        Add-ValidationWarning -Message "Duplicate localization keys: $preview" -Path $relativePath
    }
}

$trackedPaths = @(& git -C $repositoryRoot ls-files)
if ($LASTEXITCODE -ne 0) {
    Add-ValidationFailure -Message 'Unable to list tracked files with git.'
}
else {
    $caseCollisions = $trackedPaths |
        Group-Object { $_.ToLowerInvariant() } |
        Where-Object Count -gt 1

    foreach ($collision in $caseCollisions) {
        Add-ValidationFailure -Message "Tracked paths differ only by case: $($collision.Group -join ', ')"
    }
}

Write-Host "Checked $($modDirectories.Count) descriptors and $($localizationFiles.Count) localization files."
Write-Host "Validation completed with $($failures.Count) error(s) and $($warnings.Count) warning(s)."

if ($failures.Count -gt 0) {
    exit 1
}