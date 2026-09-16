# Multi-way gene merge: game -> CFP -> EPE -> CFP+EPE -> Reno
# Usage: pwsh ./scripts/merge_genes_chain.ps1 [-OutDir <dir>]
param(
    [string]$OutDir = ""
)

$root = "c:\Users\ruben\Desktop\EoE_mod_dev\EoE+compatches"
$ws   = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310"
$game = "C:\Program Files (x86)\Steam\steamapps\common\Crusader Kings III\game\common\genes"

if (-not $OutDir) { $OutDir = "$root\other_mods\cfp-reno-compatch\common\genes" }

$mergeScript = "$root\scripts\merge_genes.ps1"
$tempDir = "$root\refs\merge_temp"
if (-not (Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir | Out-Null }

# Source directories
$src = [ordered]@{
    "game"    = $game
    "CFP"     = "$ws\2220098919\common\genes"
    "EPE"     = "$ws\2507209632\common\genes"
    "CFP+EPE" = "$ws\2996881191\common\genes"
    "Reno"    = "$ws\3798537678\common\genes"
}

# Files to merge (05-08)
$files = [ordered]@{
    "05_genes_special_accessories_clothes.txt"    = $true
    "06_genes_special_accessories_headgear.txt"   = $true
    "07_genes_special_accessories_misc.txt"       = $true
    "08_genes_special_visual_traits.txt"          = $true
}

foreach ($fname in $files.Keys) {
    Write-Host "`n=== Merging $fname ===" -ForegroundColor Cyan

    # Check all sources have this file
    $missing = @()
    foreach ($s in $src.Keys) {
        $path = Join-Path $src[$s] $fname
        if (-not (Test-Path $path)) { $missing += $s }
    }
    if ($missing.Count -gt 0) {
        Write-Host "  SKIP: missing in $($missing -join ', ')" -ForegroundColor Yellow
        continue
    }

    # Step 1: game + CFP -> temp1
    $t1 = "$tempDir\$($fname)_t1.txt"
    Write-Host "  Step 1: game + CFP"
    pwsh -NoProfile -File $mergeScript -A (Join-Path $src["game"] $fname) -B (Join-Path $src["CFP"] $fname) -Out $t1

    # Step 2: temp1 + EPE -> temp2
    $t2 = "$tempDir\$($fname)_t2.txt"
    Write-Host "  Step 2: + EPE"
    pwsh -NoProfile -File $mergeScript -A $t1 -B (Join-Path $src["EPE"] $fname) -Out $t2

    # Step 3: temp2 + CFP+EPE -> temp3
    $t3 = "$tempDir\$($fname)_t3.txt"
    Write-Host "  Step 3: + CFP+EPE"
    pwsh -NoProfile -File $mergeScript -A $t2 -B (Join-Path $src["CFP+EPE"] $fname) -Out $t3

    # Step 4: temp3 + Reno -> final
    $final = Join-Path $OutDir $fname
    Write-Host "  Step 4: + Reno -> $final"
    pwsh -NoProfile -File $mergeScript -A $t3 -B (Join-Path $src["Reno"] $fname) -Out $final

    # Verify
    $content = (Get-Content $final -Raw) -replace '#[^\r\n]*',''
    $o = ([regex]::Matches($content,'\{')).Count
    $c = ([regex]::Matches($content,'\}')).Count
    $lines = (Get-Content $final | Measure-Object -Line).Lines
    Write-Host "  Result: ${lines} lines, braces ${o}/${c} balanced=$($o -eq $c)" -ForegroundColor $(if ($o -eq $c) { "Green" } else { "Red" })
}

Write-Host "`nDone. Output in: $OutDir" -ForegroundColor Cyan
