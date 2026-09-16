# Check Byzantine headgear in gene files and DNA data
$game = "C:\Program Files (x86)\Steam\steamapps\common\Crusader Kings III\game"
$cfp  = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\2220098919"
$epe  = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\2507209632"
$cfpepe = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\2996881191"
$reno = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\3798537678"
$compatch = "c:\Users\ruben\Desktop\EoE_mod_dev\EoE+compatches\other_mods\cfp-reno-compatch"

$out = @()

# 1. Check headgear gene file (06) for byzantine entries
$out += "=== HEADGEAR GENE FILE (06) - byzantine entries ==="
$files = @{
    "GAME"     = "$game\common\genes\06_genes_special_accessories_headgear.txt"
    "CFP"      = "$cfp\common\genes\06_genes_special_accessories_headgear.txt"
    "EPE"      = "$epe\common\genes\06_genes_special_accessories_headgear.txt"
    "CFP+EPE"  = "$cfpepe\common\genes\06_genes_special_accessories_headgear.txt"
    "RENO"     = "$reno\common\genes\06_genes_special_accessories_headgear.txt"
    "COMPATCH" = "$compatch\common\genes\06_genes_special_accessories_headgear.txt"
}
foreach ($name in @("GAME","CFP","EPE","CFP+EPE","RENO","COMPATCH")) {
    $f = $files[$name]
    if (Test-Path $f) {
        $lines = Get-Content $f
        $found = $false
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match "byzantine" -and $lines[$i] -notmatch "^\s*#") {
                $start = [Math]::Max(0, $i - 2)
                $end = [Math]::Min($lines.Count - 1, $i + 5)
                $out += "--- $name L$($i+1) ---"
                for ($j = $start; $j -le $end; $j++) {
                    $out += "  L$($j+1): $($lines[$j])"
                }
                $found = $true
            }
        }
        if (-not $found) { $out += "--- ${name}: no byzantine entries ---" }
    } else {
        $out += "--- ${name}: file not found ---"
    }
}

# 2. Check DNA data for byzantine headgear
$out += ""
$out += "=== DNA DATA (05_dna_byzantine.txt) - headgear entries ==="
$dnaFiles = @{
    "GAME"     = "$game\common\dna_data\05_dna_byzantine.txt"
    "CFP"      = "$cfp\common\dna_data\05_dna_byzantine.txt"
    "EPE"      = "$epe\common\dna_data\05_dna_byzantine.txt"
    "CFP+EPE"  = "$cfpepe\common\dna_data\05_dna_byzantine.txt"
    "RENO"     = "$reno\common\dna_data\05_dna_byzantine.txt"
    "COMPATCH" = "$compatch\common\dna_data\05_dna_byzantine.txt"
}
foreach ($name in @("GAME","CFP","EPE","CFP+EPE","RENO","COMPATCH")) {
    $f = $dnaFiles[$name]
    if (Test-Path $f) {
        $lines = Get-Content $f
        $out += "--- $name ---"
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match "headgear" -and $lines[$i] -notmatch "^\s*#") {
                $out += "  L$($i+1): $($lines[$i].Trim())"
            }
        }
    } else {
        $out += "--- ${name}: file not found ---"
    }
}

# 3. Check portrait modifiers for byzantine headgear templates
$out += ""
$out += "=== PORTRAIT MODIFIERS - byzantine headgear templates ==="
$pmDirs = @{
    "GAME"     = "$game\gfx\portraits\portrait_modifiers"
    "CFP"      = "$cfp\gfx\portraits\portrait_modifiers"
    "EPE"      = "$epe\gfx\portraits\portrait_modifiers"
    "CFP+EPE"  = "$cfpepe\gfx\portraits\portrait_modifiers"
    "RENO"     = "$reno\gfx\portraits\portrait_modifiers"
    "COMPATCH" = "$compatch\gfx\portraits\portrait_modifiers"
}
foreach ($name in @("GAME","CFP","EPE","CFP+EPE","RENO","COMPATCH")) {
    $dir = $pmDirs[$name]
    if (Test-Path $dir) {
        $out += "--- $name ---"
        foreach ($f in (Get-ChildItem $dir -Filter "*.txt")) {
            $lines = Get-Content $f.FullName
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -match "byzantine" -and $lines[$i] -notmatch "^\s*#") {
                    $out += "  $($f.Name) L$($i+1): $($lines[$i].Trim())"
                }
            }
        }
    }
}

$out | Out-File "c:\Users\ruben\Desktop\EoE_mod_dev\EoE+compatches\refs\byzantine_headgear_check.txt" -Encoding utf8
Write-Host "Done"
