[CmdletBinding()]
param(
    [string]$OutputPath = (Join-Path (Split-Path $PSScriptRoot -Parent) 'workshop\current-metadata.json')
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path $PSScriptRoot -Parent
$detailsEndpoint = 'https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/'

$mods = @(
    @{ Id = '3679840613'; Path = 'mods\eoe-main'; Dependencies = @() },
    @{
        Id = '3679849030'
        Path = 'mods\eoe-compat-epe'
        Dependencies = @(
            @{ Id = '3679840613'; Title = 'Embers of Empire - A Roman Restoration' },
            @{ Id = '2507209632'; Title = 'Ethnicities & Portraits Expanded' }
        )
    },
    @{
        Id = '3679849283'
        Path = 'mods\eoe-compat-it'
        Dependencies = @(
            @{ Id = '3679840613'; Title = 'Embers of Empire - A Roman Restoration' },
            @{ Id = '2255229872'; Title = 'Immersive Toponyms' }
        )
    },
    @{
        Id = '3679850009'
        Path = 'mods\eoe-compat-ce'
        Dependencies = @(
            @{ Id = '3679840613'; Title = 'Embers of Empire - A Roman Restoration' },
            @{ Id = '2829397295'; Title = 'Culture Expanded' }
        )
    }
)

$body = @{ itemcount = $mods.Count }
for ($index = 0; $index -lt $mods.Count; $index++) {
    $body["publishedfileids[$index]"] = $mods[$index].Id
}

$response = Invoke-RestMethod -Method Post -Uri $detailsEndpoint -Body $body
$detailsById = @{}
foreach ($detail in $response.response.publishedfiledetails) {
    $detailsById[[string]$detail.publishedfileid] = $detail
}

$items = foreach ($mod in $mods) {
    $detail = $detailsById[$mod.Id]
    if ($null -eq $detail -or $detail.result -ne 1) {
        throw "Steam returned no public metadata for Workshop item $($mod.Id)."
    }

    $descriptorPath = Join-Path (Join-Path $repositoryRoot $mod.Path) 'descriptor.mod'
    $descriptor = Get-Content $descriptorPath -Raw
    $descriptorId = [regex]::Match($descriptor, '(?m)^remote_file_id\s*=\s*"([^"]+)"').Groups[1].Value
    $version = [regex]::Match($descriptor, '(?m)^version\s*=\s*"([^"]+)"').Groups[1].Value
    $supportedVersion = [regex]::Match($descriptor, '(?m)^supported_version\s*=\s*"([^"]+)"').Groups[1].Value
    $descriptorName = [regex]::Match($descriptor, '(?m)^name\s*=\s*"([^"]+)"').Groups[1].Value
    if ($descriptorId -ne $mod.Id) {
        throw "Descriptor ID $descriptorId does not match expected Workshop ID $($mod.Id): $descriptorPath"
    }

    $pageUri = "https://steamcommunity.com/sharedfiles/filedetails/?id=$($mod.Id)&l=english"
    $pageUris = @(
        $pageUri,
        "https://steamcommunity.com/workshop/filedetails/?id=$($mod.Id)&l=english"
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
        throw "Workshop dependencies for $($mod.Id) differ from the managed set. Expected $($expectedDependencyIds -join ', '); found $($actualDependencyIds -join ', ')."
    }
    $changeNoteMatch = [regex]::Match($html, '(\d+) Change Notes')

    [pscustomobject][ordered]@{
        id = $mod.Id
        repositoryPath = $mod.Path.Replace('\', '/')
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