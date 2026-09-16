# Compare CFP+EPE vs RENO 01_headgear_base.txt: find templates with headgear_2 in CFP+EPE but not RENO
$cfpepe = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\2996881191\gfx\portraits\portrait_modifiers\01_headgear_base.txt"
$reno = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\3798537678\gfx\portraits\portrait_modifiers\01_headgear_base.txt"

$out = @()

function Get-TemplateNames {
    param($path)
    $names = @()
    $lines = Get-Content $path
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^\s{0,1}(\w+)\s*=\s*\{") {
            $names += $Matches[1]
        }
    }
    return $names
}


function Get-TemplateBlock {
    param($path, $templateName)
    $lines = Get-Content $path
    $result = @()
    $inBlock = $false
    $depth = 0
    $pattern = "^\s{0,1}" + [regex]::Escape($templateName) + "\s*=\s*\{"
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $l = $lines[$i]
        if (-not $inBlock -and $l -match $pattern) {
            $inBlock = $true
            $depth = 1
        }
        if ($inBlock) {
            $o = ([regex]::Matches($l, '\{')).Count
            $c = ([regex]::Matches($l, '\}')).Count
            $depth += $o - $c
            $result += $l
            if ($depth -le 0) { $inBlock = $false }
        }
    }
    return $result
}

# Get all template names from both files
$cfpepeNames = Get-TemplateNames $cfpepe
$renoNames = Get-TemplateNames $reno

$out += "CFP+EPE templates: $($cfpepeNames.Count)"
$out += "RENO templates: $($renoNames.Count)"
$out += ""

# Find templates in CFP+EPE that have headgear_2 but RENO doesn't
$cfpepeSet = @{}
foreach ($n in $cfpepeNames) { $cfpepeSet[$n] = $true }
$renoSet = @{}
foreach ($n in $renoNames) { $renoSet[$n] = $true }

$out += "=== Templates ONLY in CFP+EPE (not in RENO) ==="
$onlyCfpepe = $cfpepeNames | Where-Object { -not $renoSet[$_] }
foreach ($n in $onlyCfpepe) { $out += "  $n" }
$out += ""

$out += "=== Templates ONLY in RENO (not in CFP+EPE) ==="
$onlyReno = $renoNames | Where-Object { -not $cfpepeSet[$_] }
foreach ($n in $onlyReno) { $out += "  $n" }
$out += ""

# For templates in BOTH, check if CFP+EPE has headgear_2 but RENO doesn't
$out += "=== Templates in BOTH where CFP+EPE has headgear_2 but RENO does NOT ==="
$common = $cfpepeNames | Where-Object { $renoSet[$_] }
$diffCount = 0
foreach ($n in $common) {
    $cfpepeBlock = Get-TemplateBlock $cfpepe $n
    $renoBlock = Get-TemplateBlock $reno $n
    $cfpepeHasHG2 = ($cfpepeBlock -join "`n") -match "headgear_2"
    $renoHasHG2 = ($renoBlock -join "`n") -match "headgear_2"
    if ($cfpepeHasHG2 -and -not $renoHasHG2) {
        $diffCount++
        $out += "  $n"
    }
}
$out += "Total: $diffCount templates"
$out += ""

# Also check: templates in BOTH where RENO has headgear_2 but CFP+EPE does NOT
$out += "=== Templates in BOTH where RENO has headgear_2 but CFP+EPE does NOT ==="
$diffCount2 = 0
foreach ($n in $common) {
    $cfpepeBlock = Get-TemplateBlock $cfpepe $n
    $renoBlock = Get-TemplateBlock $reno $n
    $cfpepeHasHG2 = ($cfpepeBlock -join "`n") -match "headgear_2"
    $renoHasHG2 = ($renoBlock -join "`n") -match "headgear_2"
    if ($renoHasHG2 -and -not $cfpepeHasHG2) {
        $diffCount2++
        $out += "  $n"
    }
}
$out += "Total: $diffCount2 templates"

$out | Out-File "c:\Users\ruben\Desktop\EoE_mod_dev\EoE+compatches\refs\diff_headgear_base.txt" -Encoding UTF8
Write-Host "Done. Output: refs\diff_headgear_base.txt"
