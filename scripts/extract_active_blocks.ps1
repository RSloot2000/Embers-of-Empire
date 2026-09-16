# Extract active template blocks from source files for compatch
# These templates are referenced by gene files but missing from compatch portrait modifiers

$cfpClothes = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\2220098919\gfx\portraits\portrait_modifiers\00_custom_clothes.txt"
$epeClothes = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\2507209632\gfx\portraits\portrait_modifiers\00_custom_clothes.txt"
$cfpepeClothes = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\2996881191\gfx\portraits\portrait_modifiers\00_custom_clothes.txt"
$renoClothes = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\3798537678\gfx\portraits\portrait_modifiers\00_custom_clothes.txt"
$cfpHead = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\2220098919\gfx\portraits\portrait_modifiers\00_custom_headgear.txt"
$cfpepeHead = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\2996881191\gfx\portraits\portrait_modifiers\00_custom_headgear.txt"

$out = @()

function Get-ActiveBlock {
    param([string]$path, [string]$template)
    if (-not (Test-Path $path)) { return $null }
    $lines = Get-Content $path
    $inBlock = $false
    $blockLines = @()
    $braceDepth = 0
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if (-not $inBlock) {
            if ($line -match "add_accessory_modifiers\s*=\s*\{") {
                $inBlock = $true
                $braceDepth = 1
                $blockLines = @($line)
            }
        } else {
            $blockLines += $line
            $opens = ([regex]::Matches($line, '\{')).Count
            $closes = ([regex]::Matches($line, '\}')).Count
            $braceDepth += $opens - $closes
            if ($braceDepth -le 0) {
                $blockText = $blockLines -join "`n"
                if ($blockText -match "template\s*=\s*$template\b" -and $blockText -notmatch "^\s*#.*template\s*=\s*$template\b") {
                    # Check if the template line itself is NOT commented
                    $tplLine = $blockLines | Where-Object { $_ -match "template\s*=\s*$template\b" } | Select-Object -First 1
                    if ($tplLine -and -not $tplLine.TrimStart().StartsWith("#")) {
                        return $blockText
                    }
                }
                $inBlock = $false
                $blockLines = @()
            }
        }
    }
    return $null
}

# --- Clothes templates ---
$out += "=== CLOTHES TEMPLATES ==="

# most_clothes - try EPE first (it's the most complete)
$block = Get-ActiveBlock -path $epeClothes -template "most_clothes"
if ($block) { $out += "--- most_clothes (from EPE) ---"; $out += $block }
else {
    $block = Get-ActiveBlock -path $cfpepeClothes -template "most_clothes"
    if ($block) { $out += "--- most_clothes (from CFP+EPE) ---"; $out += $block }
    else { $out += "--- most_clothes: NOT FOUND ACTIVE in any source ---" }
}
$out += ""

# western_imperial_clothes
$block = Get-ActiveBlock -path $cfpClothes -template "western_imperial_clothes"
if ($block) { $out += "--- western_imperial_clothes (from CFP) ---"; $out += $block }
else {
    $block = Get-ActiveBlock -path $epeClothes -template "western_imperial_clothes"
    if ($block) { $out += "--- western_imperial_clothes (from EPE) ---"; $out += $block }
    else { $out += "--- western_imperial_clothes: NOT FOUND ACTIVE in any source ---" }
}
$out += ""

# --- Headgear templates ---
$out += "=== HEADGEAR TEMPLATES ==="

# tgp_shinto_priest
$block = Get-ActiveBlock -path $cfpHead -template "tgp_shinto_priest"
if ($block) { $out += "--- tgp_shinto_priest (from CFP) ---"; $out += $block }
else { $out += "--- tgp_shinto_priest: NOT FOUND ACTIVE in any source ---" }
$out += ""

# cfp_* templates from CFP+EPE
$cfpTemplates = @(
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

foreach ($tpl in $cfpTemplates) {
    $block = Get-ActiveBlock -path $cfpepeHead -template $tpl
    if ($block) {
        $out += "--- $tpl (from CFP+EPE) ---"
        $out += $block
    } else {
        $out += "--- ${tpl}: NOT FOUND ACTIVE in CFP+EPE ---"
    }
    $out += ""
}

$out | Out-File "c:\Users\ruben\Desktop\EoE_mod_dev\EoE+compatches\refs\active_blocks.txt" -Encoding utf8
Write-Host "Done"
