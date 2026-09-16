# Extract the 3 missing template blocks from source files and append to compatch
# Templates: most_clothes, western_imperial_clothes (clothes), tgp_shinto_priest (headgear)

$cfpClothes = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\2220098919\gfx\portraits\portrait_modifiers\00_custom_clothes.txt"
$epeClothes = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\2507209632\gfx\portraits\portrait_modifiers\00_custom_clothes.txt"
$cfpepeClothes = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\2996881191\gfx\portraits\portrait_modifiers\00_custom_clothes.txt"
$renoClothes = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\3798537678\gfx\portraits\portrait_modifiers\00_custom_clothes.txt"

$cfpHead = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\2220098919\gfx\portraits\portrait_modifiers\00_custom_headgear.txt"
$cfpepeHead = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\2996881191\gfx\portraits\portrait_modifiers\00_custom_headgear.txt"

function Get-TemplateBlock {
    param([string]$text, [string]$template)
    # Find the add_accessory_modifiers block containing this template
    # Pattern: add_accessory_modifiers = { ... template = X ... }
    $pattern = "add_accessory_modifiers\s*=\s*\{[^{}]*template\s*=\s*$template\b[^{}]*\}"
    $match = [regex]::Match($text, $pattern)
    if ($match.Success) {
        return $match.Value
    }
    # Try nested braces (is_valid_custom blocks)
    $pattern2 = "add_accessory_modifiers\s*=\s*\{(?<body>(?:[^{}]|\{[^{}]*\})*)\}"
    $allMatches = [regex]::Matches($text, $pattern2)
    foreach ($m in $allMatches) {
        if ($m.Groups["body"].Value -match "template\s*=\s*$template\b") {
            return $m.Value
        }
    }
    return $null
}

$out = @()

# --- Clothes: most_clothes, western_imperial_clothes ---
$missingClothes = @("most_clothes", "western_imperial_clothes")
$srcClothes = @()
$srcClothes += @("CFP", $cfpClothes)
$srcClothes += @("EPE", $epeClothes)
$srcClothes += @("CFP+EPE", $cfpepeClothes)
$srcClothes += @("RENO", $renoClothes)

foreach ($tpl in $missingClothes) {
    $out += "=== $tpl (clothes) ==="
    $found = $false
    for ($i = 0; $i -lt $srcClothes.Count; $i += 2) {
        $name = $srcClothes[$i]
        $path = $srcClothes[$i+1]
        if (Test-Path $path) {
            $t = Get-Content $path -Raw
            $block = Get-TemplateBlock -text $t -template $tpl
            if ($block) {
                $out += "  Found in ${name}:"
                $out += $block
                $found = $true
                break
            }
        }
    }
    if (-not $found) { $out += "  NOT FOUND in any source!" }
    $out += ""
}

# --- Headgear: tgp_shinto_priest ---
$missingHead = @("tgp_shinto_priest")
$srcHead = @()
$srcHead += @("CFP", $cfpHead)
$srcHead += @("CFP+EPE", $cfpepeHead)

foreach ($tpl in $missingHead) {
    $out += "=== $tpl (headgear) ==="
    $found = $false
    for ($i = 0; $i -lt $srcHead.Count; $i += 2) {
        $name = $srcHead[$i]
        $path = $srcHead[$i+1]
        if (Test-Path $path) {
            $t = Get-Content $path -Raw
            $block = Get-TemplateBlock -text $t -template $tpl
            if ($block) {
                $out += "  Found in ${name}:"
                $out += $block
                $found = $true
                break
            }
        }
    }
    if (-not $found) { $out += "  NOT FOUND in any source!" }
    $out += ""
}

$out | Out-File "c:\Users\ruben\Desktop\EoE_mod_dev\EoE+compatches\refs\missing_blocks.txt" -Encoding utf8
Write-Host "Done"
