[CmdletBinding()]
param(
    [string]$OutputPath = (Join-Path (Split-Path $PSScriptRoot -Parent) 'workshop\current-metadata.json')
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path $PSScriptRoot -Parent
. (Join-Path $PSScriptRoot 'lib/mods.ps1')
$detailsEndpoint = 'https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/'

# Only published mods (those with a WorkshopId) have public Steam metadata.
# Unpublished submods are skipped here; they are still covered by the other scripts.
$mods = @(Get-ModInventory -RepositoryRoot $repositoryRoot | Where-Object { $_.WorkshopId })

$body = @{ itemcount = $mods.Count }
for ($index = 0; $index -lt $mods.Count; $index++) {
    $body["publishedfileids[$index]"] = $mods[$index].WorkshopId
}

$response = Invoke-RestMethod -Method Post -Uri $detailsEndpoint -Body $body
$detailsById = @{}
foreach ($detail in $response.response.publishedfiledetails) {
    $detailsById[[string]$detail.publishedfileid] = $detail
}

$items = foreach ($mod in $mods) {
    $detail = $detailsById[$mod.WorkshopId]
    if ($null -eq $detail -or $detail.result -ne 1) {
        throw "Steam returned no public metadata for Workshop item $($mod.WorkshopId)."
    }

    $descriptorPath = Join-Path (Join-Path (Join-Path $repositoryRoot 'mods') $mod.Source) 'descriptor.mod'
    $descriptor = Get-Content $descriptorPath -Raw
    $descriptorId = [regex]::Match($descriptor, '(?m)^remote_file_id\s*=\s*"([^"]+)"').Groups[1].Value
    $version = [regex]::Match($descriptor, '(?m)^version\s*=\s*"([^"]+)"').Groups[1].Value
    $supportedVersion = [regex]::Match($descriptor, '(?m)^supported_version\s*=\s*"([^"]+)"').Groups[1].Value
    $descriptorName = [regex]::Match($descriptor, '(?m)^name\s*=\s*"([^"]+)"').Groups[1].Value
    if ($descriptorId -ne $mod.WorkshopId) {
        throw "Descriptor ID $descriptorId does not match expected Workshop ID $($mod.WorkshopId): $descriptorPath"
    }

    $pageUri = "https://steamcommunity.com/sharedfiles/filedetails/?id=$($mod.WorkshopId)&l=english"
    $pageUris = @(
        $pageUri,
        "https://steamcommunity.com/workshop/filedetails/?id=$($mod.WorkshopId)&l=english"
    )
    $html = ''
    $requiredBlock = ''
    $pageAvailable = $false
    foreach ($candidateUri in $pageUris) {
        try {
            $html = (Invoke-WebRequest -Uri $candidateUri -UseBasicParsing -Headers @{ 'User-Agent' = 'Mozilla/5.0' }).Content
            $pageAvailable = $true
        }
        catch {
            continue
        }
        $requiredBlock = [regex]::Match(
            $html,
            '(?s)<div class="requiredItemsContainer".*?</div>\s*</div>\s*</div>'
        ).Value
        if ($requiredBlock) {
            break
        }
    }
    $pageDependencies = @(
        [regex]::Matches(
            $requiredBlock,
            '(?s)workshop/filedetails/\?id=(\d+).*?<div class="requiredItem">\s*(.*?)\s*</div>'
        ) | ForEach-Object {
            [pscustomobject][ordered]@{
                id = $_.Groups[1].Value
                title = [Net.WebUtility]::HtmlDecode(
                    ($_.Groups[2].Value -replace '<[^>]+>', '').Trim()
                )
            }
        }
    )
    $dependencies = @($mod.Dependencies | ForEach-Object {
        [pscustomobject][ordered]@{ id = $_.Id; title = $_.Title }
    })
    $actualDependencyIds = @($pageDependencies.id | Sort-Object)
    $expectedDependencyIds = @($dependencies.id | Sort-Object)
    $dependenciesVerified = $requiredBlock -and (($actualDependencyIds -join ',') -eq ($expectedDependencyIds -join ','))
    if ($requiredBlock -and -not $dependenciesVerified) {
        throw "Workshop dependencies for $($mod.WorkshopId) differ from the managed set. Expected $($expectedDependencyIds -join ', '); found $($actualDependencyIds -join ', ')."
    }
    $changeNoteMatch = [regex]::Match($html, '(\d+) Change Notes')

    [pscustomobject][ordered]@{
        id = $mod.WorkshopId
        repositoryPath = "mods/$($mod.Source)"
        pageUrl = $pageUri
        result = [int]$detail.result
        title = $detail.title
        descriptorName = $descriptorName
        descriptorVersion = $version
        descriptorSupportedVersion = $supportedVersion
        visibility = [int]$detail.visibility
        timeCreated = [DateTimeOffset]::FromUnixTimeSeconds($detail.time_created).ToString('o')
        timeUpdated = [DateTimeOffset]::FromUnixTimeSeconds($detail.time_updated).ToString('o')
        previewUrl = $detail.preview_url
        tags = @($detail.tags | ForEach-Object { $_.tag })
        pageMetadataAvailable = $pageAvailable
        changeNoteCount = if ($changeNoteMatch.Success) { [int]$changeNoteMatch.Groups[1].Value } else { $null }
        dependenciesVerifiedFromPage = [bool]$dependenciesVerified
        dependencies = $dependencies
        description = $detail.description
    }
}

$snapshot = [pscustomobject][ordered]@{
    schemaVersion = 1
    retrievedAt = [DateTimeOffset]::UtcNow.ToString('o')
    source = $detailsEndpoint
    items = @($items)
}

$outputDirectory = Split-Path $OutputPath -Parent
if ($outputDirectory) {
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
}
[IO.File]::WriteAllText(
    $OutputPath,
    ($snapshot | ConvertTo-Json -Depth 8) + "`n",
    [Text.UTF8Encoding]::new($false)
)

Write-Host "Wrote public metadata for $($items.Count) Workshop items to $OutputPath"