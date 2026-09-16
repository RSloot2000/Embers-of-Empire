# Check: are the missing portrait modifier templates referenced by merged gene files?
# If yes → accessory is invisible (template not loaded)

$compGenes = "c:\Users\ruben\Desktop\EoE_mod_dev\EoE+compatches\other_mods\cfp-reno-compatch\common\genes"
$missing = @(
    "most_clothes",
    "rtt_hairstyles",
    "western_imperial_clothes",
    "tgp_shinto_priest",
    "cfp_indian_high_nobility",
    "cfp_indian_war",
    "cfp_iranian_common",
    "cfp_iranian_war_high_medieval",
    "cfp_mena_war_high",
    "cfp_oghuz_high_nobility",
    "cfp_oghuz_low_nobility",
    "cfp_turkic_royalty",
    "cfp_turkic_war"
)

$out = @()
$out += "=== MISSING TEMPLATES vs GENE REFERENCES ==="
$out += ""

foreach ($m in $missing) {
    $foundIn = @()
    foreach ($gf in (Get-ChildItem $compGenes -Filter "*.txt")) {
        $t = Get-Content $gf.FullName -Raw
        if ($t -match [regex]::Escape($m)) {
            $foundIn += $gf.Name
        }
    }
    if ($foundIn.Count -gt 0) {
        $out += "  $m : REFERENCED in gene files: $($foundIn -join ', ')"
    } else {
        $out += "  $m : NOT referenced in any gene file (safe to ignore)"
    }
}

$out | Out-File "c:\Users\ruben\Desktop\EoE_mod_dev\EoE+compatches\refs\missing_vs_genes.txt" -Encoding utf8
Write-Host "Done"
