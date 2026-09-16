# Check Byzantine DNA data and scripted triggers for headgear
$game = "C:\Program Files (x86)\Steam\steamapps\common\Crusader Kings III\game"
$cfp = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\2220098919"
$epe = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\2507209632"
$cfpepe = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\2996881191"
$reno = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\3798537678"
$compatch = "c:\Users\ruben\Desktop\EoE_mod_dev\EoE+compatches\other_mods\cfp-reno-compatch"

$out = @()

# 1. Find Byzantine DNA in 00_dna.txt (game)
$out += "=== GAME 00_dna.txt - byzantine block ==="
$f = "$game\common\dna_data\00_dna.txt"
if (Test-Path $f) {
    $lines = Get-Content $f
    $inByz = $false
    $braceDepth = 0
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $l = $lines[$i]
        if (-not $inByz -and $l -match "^\s*byzantine\s*=") {
            $inByz = $true
            $braceDepth = 0
            $out += "--- byzantine block starts at line $($i+1) ---"
        }
        if ($inByz) {
            $opens = ([regex]::Matches($l, '\{')).Count
            $closes = ([regex]::Matches($l, '\}')).Count
            $braceDepth += $opens - $closes
            if ($l -match "headgear|clothes|clothing") {
                $out += "  L$($i+1): $($l.Trim())"
            }
            if ($braceDepth -le 0 -and $i -gt 0) {
                $out += "--- byzantine block ends at line $($i+1) ---"
                $inByz = $false
            }
        }
    }
} else {
    $out += "File not found: $f"
}

# 2. Check scripted triggers for byzantine headgear/clothing
$out += ""
$out += "=== SCRIPTED TRIGGERS - byzantine clothing/headgear ==="
$triggerDirs = @(
    @{ name = "GAME"; path = "$game\common\scripted_triggers" },
    @{ name = "CFP"; path = "$cfp\common\scripted_triggers" },
    @{ name = "EPE"; path = "$epe\common\scripted_triggers" },
    @{ name = "CFP+EPE"; path = "$cfpepe\common\scripted_triggers" },
    @{ name = "RENO"; path = "$reno\common\scripted_triggers" },
    @{ name = "COMPATCH"; path = "$compatch\common\scripted_triggers" }
)
foreach ($td in $triggerDirs) {
    if (Test-Path $td.path) {
        $files = Get-ChildItem $td.path -Filter "*.txt" -Recurse
        foreach ($f in $files) {
            $lines = Get-Content $f.FullName
            $found = $false
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -match "byzantine" -and $lines[$i] -match "headgear|clothes|clothing") {
                    if (-not $found) { $out += "--- $($td.name) $($f.Name) ---"; $found = $true }
                    $out += "  L$($i+1): $($lines[$i].Trim())"
                }
            }
        }
    } else {
        $out += "--- $($td.name): no scripted_triggers dir ---"
    }
}

# 3. Check portrait modifiers for byzantine headgear in CFP+EPE and COMPATCH specifically
$out += ""
$out += "=== PORTRAIT MODIFIERS - byzantine headgear (CFP+EPE + COMPATCH) ==="
$pmDirs = @(
    @{ name = "CFP+EPE"; path = "$cfpepe\gfx\portraits\portrait_modifiers" },
    @{ name = "COMPATCH"; path = "$compatch\gfx\portraits\portrait_modifiers" }
)
foreach ($pm in $pmDirs) {
    if (Test-Path $pm.path) {
        $files = Get-ChildItem $pm.path -Filter "*.txt"
        foreach ($f in $files) {
            $lines = Get-Content $f.FullName
            $inBlock = $false
            $blockName = ""
            for ($i = 0; $i -lt $lines.Count; $i++) {
                $l = $lines[$i]
                if ($l -match "^\s*(\w+)\s*=\s*\{" -and $l -match "byzantine") {
                    $inBlock = $true
                    $blockName = $Matches[1]
                    $out += "--- $($pm.name) $($f.Name) L$($i+1): $blockName ---"
                }
                if ($inBlock) {
                    if ($l -match "gene\s*=") { $out += "  gene: $($l.Trim())" }
                    if ($l -match "template\s*=") { $out += "  template: $($l.Trim())" }
                    if ($l -match "^\s*\}\s*$") { $inBlock = $false }
                }
            }
        }
    } else {
        $out += "--- $($pm.name): no portrait_modifiers dir ---"
    }
}

# 4. Check if compatch has DNA data files
$out += ""
$out += "=== COMPATCH DNA DATA FILES ==="
$dnaDir = "$compatch\common\dna_data"
if (Test-Path $dnaDir) {
    $files = Get-ChildItem $dnaDir -Filter "*.txt"
    foreach ($f in $files) { $out += "  $($f.Name)" }
} else {
    $out += "  No dna_data dir in compatch"
}

# 5. Check if compatch has scripted triggers
$out += ""
$out += "=== COMPATCH SCRIPTED TRIGGERS FILES ==="
$stDir = "$compatch\common\scripted_triggers"
if (Test-Path $stDir) {
    $files = Get-ChildItem $stDir -Filter "*.txt" -Recurse
    foreach ($f in $files) { $out += "  $($f.Name)" }
} else {
    $out += "  No scripted_triggers dir in compatch"
}

$out | Out-File "c:\Users\ruben\Desktop\EoE_mod_dev\EoE+compatches\refs\byzantine_dna_check.txt" -Encoding UTF8
Write-Host "Done. Output: refs\byzantine_dna_check.txt"
