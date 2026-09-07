[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$ModDirectory = (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Paradox Interactive\Crusader Kings III\mod'),
    [switch]$Clean
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path $PSScriptRoot -Parent

function Get-FileHashMap {
    param(
        [Parameter(Mandatory)]
        [string]$Root,

        [string[]]$Exclude = @()
    )

    $hashes = @{}
    Get-ChildItem $Root -Recurse -File -Force | ForEach-Object {
        $relative = [IO.Path]::GetRelativePath($Root, $_.FullName).Replace('\', '/')
        if ($relative -notin $Exclude) {
            $hashes[$relative] = (Get-FileHash $_.FullName -Algorithm SHA256).Hash
        }
    }
    return $hashes
}

function Assert-MatchingFiles {
    param(
        [Parameter(Mandatory)]
        [string]$Source,

        [Parameter(Mandatory)]
        [string]$Destination
    )

    $sourceHashes = Get-FileHashMap -Root $Source -Exclude 'descriptor.mod'
    $destinationHashes = Get-FileHashMap -Root $Destination -Exclude 'descriptor.mod'
    $allPaths = @($sourceHashes.Keys) + @($destinationHashes.Keys) | Sort-Object -Unique
    $mismatches = @($allPaths | Where-Object {
        -not $sourceHashes.ContainsKey($_) -or
        -not $destinationHashes.ContainsKey($_) -or
        $sourceHashes[$_] -ne $destinationHashes[$_]
    })

    if ($mismatches.Count -gt 0) {
        $preview = ($mismatches | Select-Object -First 10) -join ', '
        throw "DEV deployment differs from source at $($mismatches.Count) path(s): $preview. Redeploy with -Clean if stale files remain."
    }
}

function Assert-DevDescriptors {
    param(
        [Parameter(Mandatory)]
        [string]$InternalDescriptor,

        [Parameter(Mandatory)]
        [string]$ExternalDescriptor,

        [Parameter(Mandatory)]
        [string]$DisplayName,

        [Parameter(Mandatory)]
        [string]$DevName
    )

    $internal = Get-Content $InternalDescriptor -Raw
    $external = Get-Content $ExternalDescriptor -Raw
    $expectedName = 'name="' + $DisplayName + '"'
    $expectedPath = 'path="mod/' + $DevName + '"'

    if ($internal -match '(?m)^\s*remote_file_id\s*=' -or $external -match '(?m)^\s*remote_file_id\s*=') {
        throw "DEV descriptor still contains remote_file_id: $DevName"
    }
    if ($internal -notmatch ('(?m)^' + [regex]::Escape($expectedName) + '\r?$')) {
        throw "Internal DEV descriptor has an unexpected name: $InternalDescriptor"
    }
    if ($external -notmatch ('(?m)^' + [regex]::Escape($expectedName) + '\r?$')) {
        throw "External DEV descriptor has an unexpected name: $ExternalDescriptor"
    }
    if ($external -notmatch ('(?m)^' + [regex]::Escape($expectedPath) + '\r?$')) {
        throw "External DEV descriptor has an unexpected path: $ExternalDescriptor"
    }
}

$mods = @(
    @{
        Source = 'mods\eoe-main'
        DevName = 'EoE_Dev'
        DisplayName = 'Embers of Empire - A Roman Restoration DEV_VERSION'
    },
    @{
        Source = 'mods\eoe-compat-epe'
        DevName = 'EoE_EPE_Dev'
        DisplayName = 'EoE + EPE DEV_VERSION'
    },
    @{
        Source = 'mods\eoe-compat-it'
        DevName = 'EoE_IT_Dev'
        DisplayName = 'EoE + Immersive Toponyms DEV_VERSION'
    },
    @{
        Source = 'mods\eoe-compat-ce'
        DevName = 'EoE_CE_Dev'
        DisplayName = 'EoE + CE Flavour Patch DEV_VERSION'
    }
)

if (-not (Test-Path $ModDirectory)) {
    if ($PSCmdlet.ShouldProcess($ModDirectory, 'Create CK3 mod directory')) {
        New-Item -ItemType Directory -Path $ModDirectory -Force | Out-Null
    }
}

foreach ($mod in $mods) {
    $source = Join-Path $repositoryRoot $mod.Source
    $destination = Join-Path $ModDirectory $mod.DevName
    $externalDescriptor = Join-Path $ModDirectory ($mod.DevName + '.mod')

    if (-not (Test-Path (Join-Path $source 'descriptor.mod'))) {
        throw "Missing source descriptor: $source"
    }

    if ($Clean -and (Test-Path $destination)) {
        $resolvedModDirectory = [IO.Path]::GetFullPath($ModDirectory).TrimEnd('\')
        $resolvedDestination = [IO.Path]::GetFullPath($destination)
        if (-not $resolvedDestination.StartsWith($resolvedModDirectory + '\', [StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to clean outside the CK3 mod directory: $destination"
        }
        if ($PSCmdlet.ShouldProcess($destination, 'Remove existing DEV copy')) {
            Remove-Item $destination -Recurse -Force
        }
    }

    if ($PSCmdlet.ShouldProcess($destination, "Deploy $($mod.Source)")) {
        New-Item -ItemType Directory -Path $destination -Force | Out-Null
        Get-ChildItem $source -Force | Copy-Item -Destination $destination -Recurse -Force

        $internalDescriptorPath = Join-Path $destination 'descriptor.mod'
        $descriptor = Get-Content $internalDescriptorPath -Raw
        $descriptor = [regex]::Replace($descriptor, '(?m)^\s*remote_file_id\s*=.*(?:\r?\n)?', '')
        $descriptor = [regex]::Replace($descriptor, '(?m)^name\s*=\s*"[^"]*"', 'name="' + $mod.DisplayName + '"')
        [IO.File]::WriteAllText($internalDescriptorPath, $descriptor, [Text.UTF8Encoding]::new($false))

        $external = $descriptor.TrimEnd() + "`r`npath=`"mod/$($mod.DevName)`"`r`n"
        [IO.File]::WriteAllText($externalDescriptor, $external, [Text.UTF8Encoding]::new($false))

        Assert-MatchingFiles -Source $source -Destination $destination
        Assert-DevDescriptors `
            -InternalDescriptor $internalDescriptorPath `
            -ExternalDescriptor $externalDescriptor `
            -DisplayName $mod.DisplayName `
            -DevName $mod.DevName

        Write-Host "Prepared and verified $($mod.DisplayName) at $destination"
    }
}