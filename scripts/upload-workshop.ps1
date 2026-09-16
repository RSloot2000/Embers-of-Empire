# Uploads one or more mod source folders to the Steam Workshop via SteamCMD.
#
# Usage:
#   ./scripts/upload-workshop.ps1                          # checkbox popup to pick mods
#   ./scripts/upload-workshop.ps1 -Mod eoe-main            # upload a specific mod
#   ./scripts/upload-workshop.ps1 -Mod eoe-main -SteamUser mysteamname
#   ./scripts/upload-workshop.ps1 -Mod eoe-main -DryRun    # only generate the VDF
#
# Notes:
# - SteamCMD uploads the source folder directly; the dev copies in the CK3
#   mod folder are not involved, so DEV_VERSION names never leak to the
#   Workshop.
# - Mods without a workshopId in mod-config.json are shown in the popup but
#   disabled: create the Workshop item once via the CK3 launcher, then add
#   the published file id to scripts/mod-config.json.
# - SteamCMD reuses its cached login; pass -SteamUser to log in again.
#   Credentials are read from refs/.env (STEAM_USER, STEAM_PASSWORD).
#   If Steam Guard is enabled, a popup will prompt for the 5-character
#   code automatically. You can also pass -SteamGuardCode <code> to skip
#   the popup.
#
# .env format (refs/.env):
#   STEAM_USER=yourname
#   STEAM_PASSWORD=yourpassword

[CmdletBinding(SupportsShouldProcess)]
param(
    [string[]]$Mod = @(),

    [string]$SteamCmdPath = 'C:\steamcmd\steamcmd.exe',

    [string]$Changelog = '',

    [string]$SteamUser = '',

    [string]$SteamGuardCode = '',

    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path $PSScriptRoot -Parent
. (Join-Path $PSScriptRoot 'lib/mods.ps1')

# ---------------------------------------------------------------------------
# Read credentials from refs/.env
# ---------------------------------------------------------------------------
function Read-EnvFile {
    param([string]$Path)
    $result = @{}
    if (Test-Path $Path) {
        foreach ($line in (Get-Content $Path)) {
            if ($line -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$') {
                $key = $Matches[1]
                $value = $Matches[2].Trim()
                # Strip surrounding quotes if present
                if ($value.Length -ge 2 -and (($value[0] -eq "'" -and $value[-1] -eq "'") -or ($value[0] -eq '"' -and $value[-1] -eq '"'))) {
                    $value = $value.Substring(1, $value.Length - 2)
                }
                $result[$key] = $value
            }
        }
    }
    return $result
}

$envFile = Join-Path $repositoryRoot 'refs/.env'
$envVars = Read-EnvFile -Path $envFile

# Use .env values as defaults when parameters are not explicitly given
if (-not $SteamUser -and $envVars['STEAM_USER']) {
    $SteamUser = $envVars['STEAM_USER']
    Write-Host "Steam user from .env: $SteamUser" -ForegroundColor DarkGray
}
$steamPassword = $envVars['STEAM_PASSWORD']

# ---------------------------------------------------------------------------
# Checkbox popup: pick which mods to upload.
# ---------------------------------------------------------------------------
function Show-ModPicker {
    param(
        $Config,
        $Inventory
    )

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Upload to Steam Workshop'
    $form.Width = 520
    $modCount = @($Config.mods.PSObject.Properties).Count
    $orphanCount = @($Inventory | Where-Object { $Config.mods.PSObject.Properties.Name -notcontains $_.Source }).Count
    $orphanHeight = if ($orphanCount -gt 0) { 34 + 26 + 34 * $orphanCount } else { 0 }
    $form.Height = 60 + 34 * $modCount + 90 + $orphanHeight
    $form.StartPosition = 'CenterScreen'
    $form.Font = New-Object System.Drawing.Font('Segoe UI', 9)

    $y = 12
    foreach ($prop in $Config.mods.PSObject.Properties) {
        $name = $prop.Name
        $entry = $prop.Value
        $inv = $Inventory | Where-Object { $_.Source -eq $name } | Select-Object -First 1
        $label = if ($inv) { $inv.DisplayName } else { $name }
        if ($entry.workshopId) {
            $suffix = "  (workshop $($entry.workshopId))"
        } else {
            $suffix = '  (no workshop id yet - create via launcher first)'
        }

        $checkbox = New-Object System.Windows.Forms.CheckBox
        $checkbox.Text = "$label$suffix"
        $checkbox.Location = [System.Drawing.Point]::new(12, $y)
        $checkbox.AutoSize = $true
        $checkbox.Name = $name
        $checkbox.Checked = $false
        $form.Controls.Add($checkbox)
        $y += 34
    }

    # Detect mods present on disk but missing from mod-config.json
    $configNames = @($Config.mods.PSObject.Properties.Name)
    $orphans = @($Inventory | Where-Object { $configNames -notcontains $_.Source })
    if ($orphans.Count -gt 0) {
        $y += 8
        $header = New-Object System.Windows.Forms.Label
        $header.Text = 'Found on disk but not in mod-config.json:'
        $header.Location = [System.Drawing.Point]::new(12, $y)
        $header.AutoSize = $true
        $header.ForeColor = [System.Drawing.Color]::DarkOrange
        $form.Controls.Add($header)
        $y += 26
        foreach ($orphan in $orphans) {
            $checkbox = New-Object System.Windows.Forms.CheckBox
            $checkbox.Text = "$($orphan.DisplayName)  (add to mod-config.json first)"
            $checkbox.Location = [System.Drawing.Point]::new(12, $y)
            $checkbox.AutoSize = $true
            $checkbox.Enabled = $false
            $form.Controls.Add($checkbox)
            $y += 34
        }
    }

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = 'Upload selected'
    $okButton.Location = [System.Drawing.Point]::new(12, $y + 8)
    $okButton.Size = [System.Drawing.Size]::new(140, 32)
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.Controls.Add($okButton)
    $form.AcceptButton = $okButton

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = 'Cancel'
    $cancelButton.Location = [System.Drawing.Point]::new(162, $y + 8)
    $cancelButton.Size = [System.Drawing.Size]::new(100, 32)
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.Controls.Add($cancelButton)
    $form.CancelButton = $cancelButton

    $result = $form.ShowDialog()

    $picked = @()
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        foreach ($control in $form.Controls) {
            if ($control -is [System.Windows.Forms.CheckBox] -and $control.Checked) {
                $picked += $control.Name
            }
        }
    }
    $form.Dispose()
    return $picked
}

# ---------------------------------------------------------------------------
# Steam Guard code input popup
# ---------------------------------------------------------------------------
function Show-SteamGuardPrompt {
    param([string]$Message = 'Enter your 5-character Steam Guard code (from the Steam Mobile app).')

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Steam Guard Code'
    $form.Width = 420
    $form.Height = 160
    $form.StartPosition = 'CenterScreen'
    $form.Font = New-Object System.Drawing.Font('Segoe UI', 9)
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false

    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Message
    $label.Location = [System.Drawing.Point]::new(12, 12)
    $label.Size = [System.Drawing.Size]::new(390, 40)
    $form.Controls.Add($label)

    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = [System.Drawing.Point]::new(12, 56)
    $textBox.Size = [System.Drawing.Size]::new(120, 28)
    $textBox.Font = New-Object System.Drawing.Font('Consolas', 14)
    $textBox.CharacterCasing = 'Upper'
    $textBox.MaxLength = 5
    $form.Controls.Add($textBox)

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = 'OK'
    $okButton.Location = [System.Drawing.Point]::new(144, 56)
    $okButton.Size = [System.Drawing.Size]::new(80, 28)
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.Controls.Add($okButton)
    $form.AcceptButton = $okButton

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = 'Cancel'
    $cancelButton.Location = [System.Drawing.Point]::new(232, 56)
    $cancelButton.Size = [System.Drawing.Size]::new(80, 28)
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.Controls.Add($cancelButton)
    $form.CancelButton = $cancelButton

    $result = $form.ShowDialog()
    $code = $textBox.Text.Trim().ToUpper()
    $form.Dispose()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK -and $code.Length -eq 5) {
        return $code
    }
    return ''
}

$steamAppId = '1158310'

if (-not (Test-Path $SteamCmdPath)) {
    throw "SteamCMD not found at $SteamCmdPath"
}

$config = Get-Content (Join-Path $PSScriptRoot 'mod-config.json') -Raw | ConvertFrom-Json
$inventory = @(Get-ModInventory -RepositoryRoot $repositoryRoot)

# Resolve which mods to upload: explicit -Mod list, or a checkbox popup.
$selected = @()
if ($Mod.Count -gt 0) {
    foreach ($name in $Mod) {
        if (-not $config.mods.PSObject.Properties[$name]) {
            throw "Unknown mod '$name'. Known mods: $($config.mods.PSObject.Properties.Name -join ', ')"
        }
        $selected += $name
    }
} else {
    $selected = Show-ModPicker -Config $config -Inventory $inventory
    if ($selected.Count -eq 0) {
        Write-Host 'No mods selected; nothing to do.'
        return
    }
}

foreach ($name in $selected) {
    $configEntry = $config.mods.$name
    if (-not $configEntry.workshopId) {
        throw "Mod '$name' has no workshopId in mod-config.json. Create the Workshop item once via the CK3 launcher, then add its published file id to mod-config.json."
    }

    $modEntry = $inventory | Where-Object { $_.Source -eq $name }
    if ($modEntry.Count -ne 1) {
        throw "Expected exactly one mod with source '$name', found $($modEntry.Count)"
    }
    $source = Join-Path (Join-Path $repositoryRoot $modEntry.Root) $modEntry.Source

    if (-not (Test-Path (Join-Path $source 'descriptor.mod'))) {
        throw "Missing source descriptor: $source"
    }

    # --- Changelog: prefer file from workshop/change-notes/<mod>.bbcode ---
    $changelog = $Changelog
    if ([string]::IsNullOrWhiteSpace($changelog)) {
        $changelogFile = Join-Path $repositoryRoot "workshop/change-notes/$name.bbcode"
        if (Test-Path $changelogFile) {
            $changelog = (Get-Content $changelogFile -Raw).Trim()
            Write-Host "  Changelog: read from $changelogFile" -ForegroundColor Cyan
        } else {
            $changelog = "Version $($modEntry.Version)"
            Write-Host "  Changelog: no file found, using default" -ForegroundColor DarkGray
        }
    }

    # --- Description: read from workshop/descriptions/<mod>.bbcode ---
    $description = ''
    $descFile = Join-Path $repositoryRoot "workshop/descriptions/$name.bbcode"
    if (Test-Path $descFile) {
        $description = (Get-Content $descFile -Raw).Trim()
        Write-Host "  Description: read from $descFile" -ForegroundColor Cyan
    }

    # --- Preview file: thumbnail.png in the mod source folder ---
    $previewFile = Join-Path $source 'thumbnail.png'
    if (-not (Test-Path $previewFile)) {
        $previewFile = ''
    }

    # --- Escape for VDF: only quotes (VDF supports real newlines in quoted strings) ---
    $escapedChangelog = $changelog.Replace('"', '\"')
    $escapedDescription = $description.Replace('"', '\"')

    # --- Build VDF ---
    $vdfLines = @(
        '"workshopitem"',
        '{',
        "    `"appid`" `"$steamAppId`"",
        "    `"publishedfileid`" `"$($configEntry.workshopId)`"",
        "    `"contentfolder`" `"$source`"",
        "    `"title`" `"$($modEntry.DisplayName.Replace('"', '\"'))`"",
        "    `"changenote`" `"$escapedChangelog`""
    )
    if ($description) {
        $vdfLines += "    `"description`" `"$escapedDescription`""
    }
    if ($previewFile) {
        $vdfLines += "    `"previewfile`" `"$previewFile`""
    }
    $vdfLines += @('}', '')

    $vdfPath = Join-Path $PSScriptRoot "workshop_$name.vdf"
    [IO.File]::WriteAllLines($vdfPath, $vdfLines, [Text.UTF8Encoding]::new($false))
    Write-Host "Generated VDF: $vdfPath"

    if ($DryRun) {
        Write-Host "Dry run: skipping SteamCMD upload for '$name'."
        continue
    }

    # Prompt for Steam Guard code if not already provided
    if ($SteamUser -and -not $SteamGuardCode) {
        $SteamGuardCode = Show-SteamGuardPrompt
        if (-not $SteamGuardCode) {
            throw "No Steam Guard code provided; upload cancelled for '$name'."
        }
        Write-Host "  Steam Guard code received." -ForegroundColor Cyan
    }

    $steamArgs = @()
    if ($SteamUser) {
        $steamArgs += @('+login', $SteamUser)
        if ($steamPassword) {
            $steamArgs += $steamPassword
        }
        if ($SteamGuardCode) {
            $steamArgs += $SteamGuardCode
        }
    }
    $steamArgs += @('+workshop_build_item', $vdfPath, '+quit')

    Write-Host "Uploading '$($modEntry.DisplayName)' (workshop id $($configEntry.workshopId))..."
    & $SteamCmdPath @steamArgs
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw "SteamCMD exited with code $exitCode for '$name'"
    }
    Write-Host "Uploaded '$($modEntry.DisplayName)' to the Steam Workshop."
}
