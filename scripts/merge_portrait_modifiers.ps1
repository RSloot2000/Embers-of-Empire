<#
.SYNOPSIS
Merge two CK3 portrait modifier files (union of add_accessory_modifiers blocks by template name).
A = CFP+EPE compat (base), B = Reno (leading). Shared templates keep B's (Reno) version.
#>
param(
    [Parameter(Mandatory)][string]$A,
    [Parameter(Mandatory)][string]$B,
    [string]$Out,
    [switch]$AnalyzeOnly
)

function Read-Text([string]$path) {
    $raw = [System.IO.File]::ReadAllText($path)
    return $raw -replace "`r`n", "`n"
}

function Parse-PortraitFile([string]$text) {
    $lines = $text -split "`n"
    $result = @{
        TopKey = $null
        Usage = $null
        InterfacePosition = $null
        Blocks = [ordered]@{}   # template name -> block text
        BlockOrder = [System.Collections.Generic.List[string]]::new()
    }

    $i = 0
    while ($i -lt $lines.Count) {
        $line = $lines[$i]
        $trimmed = $line.Trim()

        # Top-level key
        if ($result.TopKey -eq $null -and $trimmed -match '^([A-Za-z_][\w]*)\s*=\s*\{') {
            $result.TopKey = ($trimmed -split '=')[0].Trim()
            $i++
            continue
        }

        # usage / interface_position (only before first add_accessory_modifiers)
        if ($result.Blocks.Count -eq 0) {
            if ($trimmed -match '^usage\s*=\s*(\w+)') {
                $result.Usage = $Matches[1]
                $i++
                continue
            }
            if ($trimmed -match '^interface_position\s*=\s*(\d+)') {
                $result.InterfacePosition = $Matches[1]
                $i++
                continue
            }
        }

        # add_accessory_modifiers block
        if ($trimmed -match '^add_accessory_modifiers\s*=\s*\{') {
            $depth = 1
            $start = $i
            $i++
            while ($i -lt $lines.Count -and $depth -gt 0) {
                $depth += ([regex]::Matches($lines[$i], '\{')).Count - ([regex]::Matches($lines[$i], '\}')).Count
                $i++
            }
            $blockLines = $lines[$start..($i - 1)]
            $tplLine = $blockLines | Where-Object { $_ -match '^\s*template\s*=\s*([A-Za-z_][\w]*)' } | Select-Object -First 1
            if ($tplLine) {
                $tplName = ($tplLine.Trim() -split '=')[1].Trim()
                $result.Blocks[$tplName] = ($blockLines -join "`n")
                $result.BlockOrder.Add($tplName)
            }
            continue
        }

        $i++
    }
    return $result
}

# --- Main ---
$textA = Read-Text $A
$textB = Read-Text $B
$parseA = Parse-PortraitFile $textA
$parseB = Parse-PortraitFile $textB

$shared = @($parseA.Blocks.Keys | Where-Object { $parseB.Blocks.Contains($_) })
$onlyA  = @($parseA.Blocks.Keys | Where-Object { -not $parseB.Blocks.Contains($_) })
$onlyB  = @($parseB.Blocks.Keys | Where-Object { -not $parseA.Blocks.Contains($_) })

Write-Host "=== Portrait Modifier Analysis ==="
Write-Host "  File A: $A"
Write-Host "  File B: $B"
Write-Host "  Top key: $($parseA.TopKey)"
Write-Host "  Templates: A=$($parseA.Blocks.Count)  B=$($parseB.Blocks.Count)  shared=$($shared.Count)  A-only=$($onlyA.Count)  B-only=$($onlyB.Count)"

if ($AnalyzeOnly) { return }

if (-not $Out) {
    $Out = [System.IO.Path]::GetFullPath((Join-Path (Split-Path $A -Parent) ([System.IO.Path]::GetFileName($A) + ".merged")))
}

# Build merged output
$sb = [System.Text.StringBuilder]::new()
$indent = "	"  # tab

# Top-level header
[void]$sb.AppendLine("$($parseA.TopKey) = {")
if ($parseA.Usage) { [void]$sb.AppendLine("$indent usage = $($parseA.Usage)") }
if ($parseA.InterfacePosition) { [void]$sb.AppendLine("$indent interface_position = $($parseA.InterfacePosition)") }
[void]$sb.AppendLine()

# A's blocks in order; B (Reno) wins for shared templates
foreach ($name in $parseA.BlockOrder) {
    if ($parseB.Blocks.Contains($name)) {
        [void]$sb.AppendLine($parseB.Blocks[$name])
    } else {
        [void]$sb.AppendLine($parseA.Blocks[$name])
    }
    [void]$sb.AppendLine()
}

# B-only blocks appended
foreach ($name in $parseB.BlockOrder) {
    if (-not $parseA.Blocks.Contains($name)) {
        [void]$sb.AppendLine($parseB.Blocks[$name])
        [void]$sb.AppendLine()
    }
}

# Close top-level
[void]$sb.AppendLine("}")

# Tidy: collapse 3+ newlines to 2
$output = $sb.ToString() -replace "(\n){3,}", "`n`n"

[System.IO.File]::WriteAllText($Out, $output)
Write-Host "Wrote merged file: $Out"
Write-Host "  total templates: $($parseA.Blocks.Count + $onlyB.Count)  (A=$($parseA.Blocks.Count), B-only appended=$($onlyB.Count))"
