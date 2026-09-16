# Check Byzantine DNA in 00_ep3_dna.txt and clothing triggers
$game = "C:\Program Files (x86)\Steam\steamapps\common\Crusader Kings III\game"
$cfp = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\2220098919"
$epe = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\2507209632"
$cfpepe = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\2996881191"
$reno = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\3798537678"
$compatch = "c:\Users\ruben\Desktop\EoE_mod_dev\EoE+compatches\other_mods\cfp-reno-compatch"

$out = @()

# 1. Byzantine DNA in 00_ep3_dna.txt
$out += "=== GAME 00_ep3_dna.txt - byzantine block ==="
$f = "$game\common\dna_data\00_ep3_dna.txt"
$lines = Get-Content $f
$inByz = $false
$depth = 0
for ($i = 0; $i -lt $lines.Count; $i++) {
    $l = $lines[$i]
    if (-not $inByz -and $l -match "^\s*byzantine\s*=") {
        $inByz = $true
        $depth = 0
        $out += "--- byzantine block starts at line $($i+1) ---"
    }
    if ($inByz) {
        $o = ([regex]::Matches($l, '\{')).Count
        $c = ([regex]::Matches($l, '\}')).Count
        $depth += $o - $c
        $out += "  L$($i+1): $($l.Trim())"
        if ($depth -le 0 -and $i -gt 0) {
            $out += "--- byzantine block ends at line $($i+1) ---"
            $inByz = $false
        }
    }
}

# 2. Check clothing triggers for byzantine in all sources
$out += ""
$out += "=== CLOTHING TRIGGERS - byzantine (all sources) ==="
$triggerSources = @(
    @{ name = "GAME"; path = "$game\common\scripted_triggers" },
    @{ name = "CFP"; path = "$cfp\common\scripted_triggers" },
    @{ name = "EPE"; path = "$epe\common\scripted_triggers" },
    @{ name = "CFP+EPE"; path = "$cfpepe\common\scripted_triggers" },
    @{ name = "RENO"; path = "$reno\common\scripted_triggers" }
)
foreach ($ts in $triggerSources) {
    if (Test-Path $ts.path) {
        $files = Get-ChildItem $ts.path -Filter "*.txt" -Recurse
        foreach ($f in $files) {
            $lines = Get-Content $f.FullName
            $inBlock = $false
            $blockName = ""
            $blockLines = @()
            for ($i = 0; $i -lt $lines.Count; $i++) {
                $l = $lines[$i]
                if (-not $inBlock -and $l -match "^\s*(\w*byzantine\w*)\s*=\s*\{") {
                    $inBlock = $true
                    $blockName = $Matches[1]
                    $blockLines = @()
                }
                if ($inBlock) {
                    $blockLines += "  L$($i+1): $($l.Trim())"
                    $o = ([regex]::Matches($l, '\{')).Count
                    $c = ([regex]::Matches($l, '\}')).Count
                    $depth2 = 0
                    # Simple: if line is just } at same indent, end block
                    if ($l -match "^\s*\}\s*$" -and $blockLines.Count -gt 1) {
                        $out += "--- $($ts.name) $($f.Name) L$($i+1): $blockName ---"
                        $out += $blockLines
                        $inBlock = $false
                    }
                }
            }
        }
    }
}

# 3. Check what headgear templates exist for byzantine in CFP+EPE portrait modifiers
# Specifically look for the imperial/royalty templates
$out += ""
$out += "=== CFP+EPE 01_headgear_base.txt - byzantine imperial/royalty templates ==="
$f = "$cfpepe\gfx\portraits\portrait_modifiers\01_headgear_base.txt"
if (Test-Path $f) {
    $lines = Get-Content $f
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "byzantine_imperial|byzantine_royalty|byzantine_high_nobility") {
            # Print surrounding context
            $start = [Math]::Max(0, $i - 5)
            $end = [Math]::Min($lines.Count - 1, $i + 15)
            $out += "--- Context around L$($i+1) ---"
            for ($j = $start; $j -le $end; $j++) {
                $out += "  L$($j+1): $($lines[$j])"
            }
            $out += ""
        }
    }
}

# 4. Check if any source has a byzantine headgear that points to Islamic/Mena assets
$out += ""
$out += "=== CHECK: byzantine headgear pointing to Islamic/Mena assets ==="
$geneSources = @(
    @{ name = "GAME"; path = "$game\common\genes\06_genes_special_accessories_headgear.txt" },
    @{ name = "CFP"; path = "$cfp\common\genes\06_genes_special_accessories_headgear.txt" },
    @{ name = "EPE"; path = "$epe\common\genes\06_genes_special_accessories_headgear.txt" },
    @{ name = "CFP+EPE"; path = "$cfpepe\common\genes\06_genes_special_accessories_headgear.txt" },
    @{ name = "RENO"; path = "$reno\common\genes\06_genes_special_accessories_headgear.txt" },
    @{ name = "COMPATCH"; path = "$compatch\common\genes\06_genes_special_accessories_headgear.txt" }
)
foreach ($gs in $geneSources) {
    if (Test-Path $gs.path) {
        $lines = Get-Content $gs.path
        $inByz = $false
        $depth = 0
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $l = $lines[$i]
            if (-not $inByz -and $l -match "^\s*byzantine\s*=") {
                $inByz = $true
                $depth = 0
            }
            if ($inByz) {
                $o = ([regex]::Matches($l, '\{')).Count
                $c = ([regex]::Matches($l, '\}')).Count
                $depth += $o - $c
                if ($l -match "mena|islamic|arab|persian|turban|kufi|tarbusch") {
                    $out += "  $($gs.name) L$($i+1): $($l.Trim())  <-- POTENTIAL ISSUE"
                }
                if ($depth -le 0 -and $i -gt 0) { $inByz = $false }
            }
        }
    }
}

$out | Out-File "c:\Users\ruben\Desktop\EoE_mod_dev\EoE+compatches\refs\byzantine_dna_check2.txt" -Encoding UTF8
Write-Host "Done. Output: refs\byzantine_dna_check2.txt"
