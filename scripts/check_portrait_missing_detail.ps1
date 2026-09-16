# Check: which templates are in source portrait modifier files but NOT in compatch
# This determines if accessories will be invisible (last-wins per file)

$comp = "c:\Users\ruben\Desktop\EoE_mod_dev\EoE+compatches\other_mods\cfp-reno-compatch\gfx\portraits\portrait_modifiers"
$cfp = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\2220098919\gfx\portraits\portrait_modifiers"
$epe = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\2507209632\gfx\portraits\portrait_modifiers"
$cfpepe = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\2996881191\gfx\portraits\portrait_modifiers"
$reno = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\3798537678\gfx\portraits\portrait_modifiers"

$out = @()
$compFiles = (Get-ChildItem $comp -Filter "*.txt").Name

foreach ($cf in $compFiles) {
    $compText = Get-Content (Join-Path $comp $cf) -Raw
    $compTpl = [regex]::Matches($compText, 'template\s*=\s*([A-Za-z_][\w]*)') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique

    $out += "=== $cf (compatch: $($compTpl.Count) templates) ==="

    $srcs = @()
    $srcs += @("CFP", $cfp)
    $srcs += @("EPE", $epe)
    $srcs += @("CFP+EPE", $cfpepe)
    $srcs += @("RENO", $reno)

    for ($i = 0; $i -lt $srcs.Count; $i += 2) {
        $sn = $srcs[$i]
        $sp = Join-Path $srcs[$i+1] $cf
        if (Test-Path $sp) {
            $st = Get-Content $sp -Raw
            $stTpl = [regex]::Matches($st, 'template\s*=\s*([A-Za-z_][\w]*)') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
            $miss = $stTpl | Where-Object { $compTpl -notcontains $_ }
            if ($miss.Count -gt 0) {
                $out += "  $sn : $($stTpl.Count) total, $($miss.Count) MISSING in compatch:"
                foreach ($m in $miss) { $out += "    - $m" }
            } else {
                $out += "  $sn : $($stTpl.Count) total, all present in compatch"
            }
        }
    }
    $out += ""
}

$out | Out-File "c:\Users\ruben\Desktop\EoE_mod_dev\EoE+compatches\refs\portrait_missing_detail.txt" -Encoding utf8
Write-Host "Done"
