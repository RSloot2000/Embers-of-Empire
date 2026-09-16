# Check if the "missing" templates are actually commented out in sources
$cfpClothes = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\2220098919\gfx\portraits\portrait_modifiers\00_custom_clothes.txt"
$epeClothes = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\2507209632\gfx\portraits\portrait_modifiers\00_custom_clothes.txt"
$cfpepeClothes = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\2996881191\gfx\portraits\portrait_modifiers\00_custom_clothes.txt"
$renoClothes = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\3798537678\gfx\portraits\portrait_modifiers\00_custom_clothes.txt"
$cfpHead = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\2220098919\gfx\portraits\portrait_modifiers\00_custom_headgear.txt"
$epeHead = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\2507209632\gfx\portraits\portrait_modifiers\00_custom_headgear.txt"
$cfpepeHead = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\2996881191\gfx\portraits\portrait_modifiers\00_custom_headgear.txt"
$renoHead = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\3798537678\gfx\portraits\portrait_modifiers\00_custom_headgear.txt"

$out = @()

function Check-Template {
    param([string]$path, [string]$template)
    if (-not (Test-Path $path)) { return "FILE NOT FOUND" }
    $lines = Get-Content $path
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line -match "template\s*=\s*$template\b") {
            # Check if this line is commented
            $trimmed = $line.TrimStart()
            if ($trimmed.StartsWith("#")) {
                return "COMMENTED (line $($i+1))"
            } else {
                return "ACTIVE (line $($i+1))"
            }
        }
    }
    return "NOT FOUND"
}

$templates = @{
    "rtt_hairstyles" = @($cfpClothes, $epeClothes, $cfpepeClothes, $renoClothes, $cfpHead, $epeHead, $cfpepeHead, $renoHead)
    "most_clothes" = @($cfpClothes, $epeClothes, $cfpepeClothes, $renoClothes)
    "western_imperial_clothes" = @($cfpClothes, $epeClothes, $cfpepeClothes, $renoClothes)
    "tgp_shinto_priest" = @($cfpHead, $epeHead, $cfpepeHead, $renoHead)
    "cfp_indian_high_nobility" = @($cfpHead, $cfpepeHead)
    "cfp_indian_war" = @($cfpHead, $cfpepeHead)
    "cfp_iranian_common" = @($cfpHead, $cfpepeHead)
    "cfp_iranian_war_high_medieval" = @($cfpHead, $cfpepeHead)
    "cfp_mena_war_high" = @($cfpHead, $cfpepeHead)
    "cfp_oghuz_high_nobility" = @($cfpHead, $cfpepeHead)
    "cfp_oghuz_low_nobility" = @($cfpHead, $cfpepeHead)
    "cfp_turkic_royalty" = @($cfpHead, $cfpepeHead)
    "cfp_turkic_war" = @($cfpHead, $cfpepeHead)
}

foreach ($tpl in $templates.Keys | Sort-Object) {
    $out += "=== $tpl ==="
    $paths = $templates[$tpl]
    $names = @("CFP_clothes", "EPE_clothes", "CFP+EPE_clothes", "RENO_clothes", "CFP_head", "EPE_head", "CFP+EPE_head", "RENO_head")
    for ($i = 0; $i -lt $paths.Count; $i++) {
        $result = Check-Template -path $paths[$i] -template $tpl
        $out += "  ${names[$i]} : $result"
    }
    $out += ""
}

$out | Out-File "c:\Users\ruben\Desktop\EoE_mod_dev\EoE+compatches\refs\template_status.txt" -Encoding utf8
Write-Host "Done"
