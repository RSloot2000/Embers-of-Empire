# Shared mod-discovery helper for the EoE build/deploy/validate scripts.
#
# Scans <repoRoot>/mods for folders that contain a descriptor.mod and merges
# them with the per-mod config in scripts/mod-config.json.
#
# Fields that can be derived from the folder + descriptor are read directly.
# Fields that live nowhere in the repo (workshopId, devName, artifact override,
# dependencies) come from the config map. A mod missing from the config still
# works for scripts that do not need those fields; the missing fields are null.

function Get-ModConfig {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot
    )

    $configPath = Join-Path $RepositoryRoot 'scripts/mod-config.json'
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
        return @{}
    }

    $raw = Get-Content -LiteralPath $configPath -Raw
    $parsed = $raw | ConvertFrom-Json
    if ($null -eq $parsed.mods) {
        return @{}
    }

    # Convert the JSON object into a hashtable so callers can use .Contains()
    # and index by mod folder name.
    $asHashtable = @{}
    foreach ($property in $parsed.mods.PSObject.Properties) {
        $asHashtable[$property.Name] = $property.Value
    }
    return $asHashtable
}

function Get-DescriptorField {
    param(
        [Parameter(Mandatory)][string]$Descriptor,
        [Parameter(Mandatory)][string]$Field
    )

    $match = [regex]::Match($Descriptor, "(?m)^$Field\s*=\s*""([^""]+)""")
    if ($match.Success) {
        return $match.Groups[1].Value
    }
    return $null
}

function Get-ModInventory {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot
    )

    $modsRoot = Join-Path $RepositoryRoot 'mods'
    if (-not (Test-Path -LiteralPath $modsRoot -PathType Container)) {
        return @()
    }

    $config = Get-ModConfig -RepositoryRoot $RepositoryRoot
    $inventory = [Collections.Generic.List[object]]::new()

    $modFolders = Get-ChildItem -LiteralPath $modsRoot -Directory |
        Sort-Object -Property Name

    foreach ($folder in $modFolders) {
        $source = $folder.Name
        $descriptorPath = Join-Path $folder.FullName 'descriptor.mod'
        if (-not (Test-Path -LiteralPath $descriptorPath -PathType Leaf)) {
            continue
        }

        $descriptor = Get-Content -LiteralPath $descriptorPath -Raw
        $displayName = Get-DescriptorField -Descriptor $Descriptor -Field 'name'
        $version = Get-DescriptorField -Descriptor $Descriptor -Field 'version'
        $supportedVersion = Get-DescriptorField -Descriptor $Descriptor -Field 'supported_version'
        $descriptorWorkshopId = Get-DescriptorField -Descriptor $Descriptor -Field 'remote_file_id'

        $modConfig = $null
        if ($config.Contains($source)) {
            $modConfig = $config[$source]
        }

        # workshopId: prefer the descriptor's remote_file_id, fall back to config.
        $workshopId = $descriptorWorkshopId
        if (-not $workshopId -and $modConfig -and $modConfig.workshopId) {
            $workshopId = [string]$modConfig.workshopId
        }

        $devName = $null
        if ($modConfig -and $modConfig.devName) {
            $devName = [string]$modConfig.devName
        }

        $artifact = $source
        if ($modConfig -and $modConfig.artifact) {
            $artifact = [string]$modConfig.artifact
        }

        $dependencies = @()
        if ($modConfig -and $modConfig.dependencies) {
            $dependencies = @($modConfig.dependencies)
        }

        $inventory.Add([pscustomobject][ordered]@{
            Source           = $source
            DisplayName      = $displayName
            Version          = $version
            SupportedVersion = $supportedVersion
            WorkshopId       = $workshopId
            DevName          = $devName
            Artifact         = $artifact
            Dependencies     = $dependencies
        })
    }

    return @($inventory)
}
