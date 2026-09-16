# Search ALL portrait modifier files for sp5_headgears and m_headgear_sec_sp5_byzantine_roy_01
$cfpepe = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\2996881191"
$reno = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\3798537678"
$compatch = "c:\Users\ruben\Desktop\EoE_mod_dev\EoE+compatches\other_mods\cfp-reno-compatch"
$game = "C:\Program Files (x86)\Steam\steamapps\common\Crusader Kings III\game"

$out = @()
$targets = @("sp5_headgears", "m_headgear_sec_sp5_byzantine_roy_01")

foreach ($src in @(@{n="GAME";p="$game\gfx\portraits\portrait_modifiers"}, @{n="CFP+EPE";p="$cfpepe\gfx\portraits\portrait_modifiers"}, @{n="RENO";p="$reno\gfx\portraits\portrait_modifiers"}, @{n="COMPATCH";p="$compatch\gfx\portraits\portrait_modifiers"})) {
    if (-not (Test-Path $src.p)) { continue }
    $files = Get-ChildItem $src.p -Filter "*.txt"
    foreach ($f in $files) {
        foreach ($t in $targets) {
            $hits = Select-String -Path $f.FullName -Pattern $t
            if ($hits) {
                $out += "=== $($src.n) / $($f.Name) : '$t' ==="
                foreach ($h in $hits) {
                    $out += "  L$($h.LineNumber): $($h.Line.Trim())"
                }
            }
        }
    }
}

# Also search in gene files
$out += ""
$out += "########## GENE FILES ##########"
foreach ($src in @(@{n="GAME";p="$game\common\genes"}, @{n="CFP+EPE";p="$cfpepe\common\genes"}, @{n="RENO";p="$reno\common\genes"}, @{n="COMPATCH";p="$compatch\common\genes"})) {
    if (-not (Test-Path $src.p)) { continue }
    $files = Get-ChildItem $src.p -Filter "*.txt"
    foreach ($f in $files) {
        foreach ($t in $targets) {
            $hits = Select-String -Path $f.FullName -Pattern $t
            if ($hits) {
                $out += "=== $($src.n) / $($f.Name) : '$t' ==="
                foreach ($h in $hits) {
                    $out += "  L$($h.LineNumber): $($h.Line.Trim())"
                }
            }
        }
    }
}

$out | Out-File "c:\Users\ruben\Desktop\EoE_mod_dev\EoE+compatches\refs\find_sp5_templates.txt" -Encoding UTF8
Write-Host "Done. Output: refs\find_sp5_templates.txt"
