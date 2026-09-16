# Compare Byzantine headgear templates between CFP+EPE and Reno 01_headgear_base.txt
$cfpepe = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\2996881191"
$reno = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\3798537678"
$compatch = "c:\Users\ruben\Desktop\EoE_mod_dev\EoE+compatches\other_mods\cfp-reno-compatch"

$out = @()

function Get-ByzantineBlocks {
    param($path, $label)
    $result = @()
    if (-not (Test-Path $path)) {
        return @("--- ${label}: file not found ---")
    }
    $lines = Get-Content $path
    $inBlock = $false
    $depth = 0
    $blockStart = 0
    $blockName = ""
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $l = $lines[$i]
        if (-not $inBlock) {
            if ($l -match "^\s*([a-z0-9_]*byzantine[a-z0-9_]*)\s*=\s*\{" -and $l -notmatch "^\s*#") {
                $inBlock = $true
                $depth = 1
                $blockStart = $i
                $blockName = $Matches[1]
            }
        } else {
            $o = ([regex]::Matches($l, '\{')).Count
            $c = ([regex]::Matches($l, '\}')).Count
            $depth += $o - $c
            if ($depth -le 0) {
                $result += "=== ${label} L$($blockStart+1): $blockName ==="
                for ($j = $blockStart; $j -le $i; $j++) {
                    $result += "  $($lines[$j])"
                }
                $result += ""
                $inBlock = $false
            }
        }
    }
    return $result
}

# 1. CFP+EPE byzantine blocks
$out += "########## CFP+EPE 01_headgear_base.txt ##########"
$out += Get-ByzantineBlocks "$cfpepe\gfx\portraits\portrait_modifiers\01_headgear_base.txt" "CFP+EPE"

# 2. Reno byzantine blocks
$out += "########## RENO 01_headgear_base.txt ##########"
$out += Get-ByzantineBlocks "$reno\gfx\portraits\portrait_modifiers\01_headgear_base.txt" "RENO"

# 3. Check which templates the byzantine imperial block references in each
$out += "########## TEMPLATE REFERENCES ##########"
foreach ($src in @(@{n="CFP+EPE";p="$cfpepe\gfx\portraits\portrait_modifiers\01_headgear_base.txt"}, @{n="RENO";p="$reno\gfx\portraits\portrait_modifiers\01_headgear_base.txt"})) {
    $lines = Get-Content $src.p
    $inBlock = $false
    $depth = 0
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $l = $lines[$i]
        if (-not $inBlock -and $l -match "^\s*sp5_byzantine_imperial\s*=\s*\{") {
            $inBlock = $true
            $depth = 1
            $out += "--- $($src.n) sp5_byzantine_imperial (L$($i+1)) ---"
        }
        if ($inBlock) {
            $o = ([regex]::Matches($l, '\{')).Count
            $c = ([regex]::Matches($l, '\}')).Count
            $depth += $o - $c
            if ($l -match "template\s*=|accessory\s*=|gene\s*=|value\s*=|mode\s*=") {
                $out += "  $($l.Trim())"
            }
            if ($depth -le 0) { $inBlock = $false }
        }
    }
}

# 4. Check if the templates referenced exist in 00_custom_headgear.txt of each source
$out += "########## TEMPLATE EXISTENCE CHECK ##########"
$templatesToCheck = @("sp5_headgears", "m_headgear_sec_sp5_byzantine_roy_01", "byzantine_high_nobility", "byzantine_imperial", "byzantine_royalty")
foreach ($src in @(@{n="CFP+EPE";p="$cfpepe\gfx\portraits\portrait_modifiers"}, @{n="RENO";p="$reno\gfx\portraits\portrait_modifiers"}, @{n="COMPATCH";p="$compatch\gfx\portraits\portrait_modifiers"})) {
    $out += "--- $($src.n) ---"
    foreach ($t in $templatesToCheck) {
        $found = $false
        if (Test-Path $src.p) {
            $files = Get-ChildItem $src.p -Filter "*.txt"
            foreach ($f in $files) {
                $hits = Select-String -Path $f.FullName -Pattern "^\s*$t\s*=" 
                if ($hits) { $out += "  $t : FOUND in $($f.Name) L$($hits[0].LineNumber)"; $found = $true }
            }
        }
        if (-not $found) { $out += "  $t : NOT FOUND" }
    }
}

$out | Out-File "c:\Users\ruben\Desktop\EoE_mod_dev\EoE+compatches\refs\reno_headgear_check.txt" -Encoding UTF8
Write-Host "Done. Output: refs\reno_headgear_check.txt"
