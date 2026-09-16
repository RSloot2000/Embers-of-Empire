$cfp = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\2220098919\gfx\portraits\portrait_modifiers\00_custom_clothes.txt"
$epe = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\2507209632\gfx\portraits\portrait_modifiers\00_custom_clothes.txt"
$cfpepe = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\2996881191\gfx\portraits\portrait_modifiers\00_custom_clothes.txt"
$reno = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\3798537678\gfx\portraits\portrait_modifiers\00_custom_clothes.txt"

$out = @()
$missing = @("most_clothes", "rtt_hairstyles", "western_imperial_clothes")

foreach ($m in $missing) {
    $out += "=== $m ==="
    $sources = @()
    $sources += @("CFP", $cfp)
    $sources += @("EPE", $epe)
    $sources += @("CFP+EPE", $cfpepe)
    $sources += @("RENO", $reno)
    for ($i = 0; $i -lt $sources.Count; $i += 2) {
        $name = $sources[$i]
        $path = $sources[$i+1]
        if (Test-Path $path) {
            $t = Get-Content $path -Raw
            if ($t -match "template\s*=\s*$m\b") {
                $out += "  $name : FOUND"
            } else {
                $out += "  $name : not found"
            }
        }
    }
    $out += ""
}

# Also check headgear missing templates
$cfpH = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\2220098919\gfx\portraits\portrait_modifiers\00_custom_headgear.txt"
$cfpepeH = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\2996881191\gfx\portraits\portrait_modifiers\00_custom_headgear.txt"
$missingH = @("tgp_shinto_priest", "cfp_indian_high_nobility", "cfp_indian_war", "cfp_iranian_common", "cfp_iranian_war_high_medieval", "cfp_mena_war_high", "cfp_oghuz_high_nobility", "cfp_oghuz_low_nobility", "cfp_turkic_royalty", "cfp_turkic_war", "rtt_hairstyles")
$out += "=== HEADGEAR MISSING ==="
foreach ($m in $missingH) {
    $found = $false
    foreach ($p in @($cfpH, $cfpepeH)) {
        if (Test-Path $p) {
            $t = Get-Content $p -Raw
            if ($t -match "template\s*=\s*$m\b") { $found = $true }
        }
    }
    $out += "  $m : $(if ($found) { 'FOUND in source' } else { 'NOT FOUND anywhere' })"
}

$out | Out-File "c:\Users\ruben\Desktop\EoE_mod_dev\EoE+compatches\refs\missing_templates.txt" -Encoding utf8
Write-Host "Done"
