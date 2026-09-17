# 2-way gene merge: CFP+EPE compat (A) + Reno (B). Reno (B) wins on conflicts.
# The CFP+EPE compat patch (2996881191) is a complete standalone mod that already
# contains the merged base-game + CFP + EPE content, so we no longer need to
# merge game/CFP/EPE separately.
# Usage: pwsh ./scripts/merge_genes_chain.ps1 [-OutDir <dir>]
param(
    [string]$OutDir = ""
)

$root = "c:\Users\ruben\Desktop\EoE_mod_dev\EoE+compatches"
$ws   = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310"

if (-not $OutDir) { $OutDir = "$root\other_mods\cfp-reno-compatch\common\genes" }

$mergeScript = "$root\scripts\merge_genes.ps1"

# Source directories: A = CFP+EPE compat (base), B = Reno (leading on conflicts)
$src = [ordered]@{
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

    # Check both sources have this file
    $missing = @()
    foreach ($s in $src.Keys) {
        $path = Join-Path $src[$s] $fname
        if (-not (Test-Path $path)) { $missing += $s }
    }
    if ($missing.Count -gt 0) {
        Write-Host "  SKIP: missing in $($missing -join ', ')" -ForegroundColor Yellow
        continue
    }

    # Single merge: CFP+EPE (A) + Reno (B) -> final. Reno (B) wins on conflicts.
    $final = Join-Path $OutDir $fname
    Write-Host "  CFP+EPE + Reno -> $final"
    pwsh -NoProfile -File $mergeScript -A (Join-Path $src["CFP+EPE"] $fname) -B (Join-Path $src["Reno"] $fname) -Out $final

    # Verify
    $content = (Get-Content $final -Raw) -replace '#[^\r\n]*',''
    $o = ([regex]::Matches($content,'\{')).Count
    $c = ([regex]::Matches($content,'\}')).Count
    $lines = (Get-Content $final | Measure-Object -Line).Lines
    Write-Host "  Result: ${lines} lines, braces ${o}/${c} balanced=$($o -eq $c)" -ForegroundColor $(if ($o -eq $c) { "Green" } else { "Red" })
}

Write-Host "`nDone. Output in: $OutDir" -ForegroundColor Cyan
