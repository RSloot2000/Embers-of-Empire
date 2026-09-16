# Check sp5_headgears template and m_headgear_sec_sp5_byzantine_roy_01 in 00_custom_headgear.txt
$cfpepe = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\2996881191"
$reno = "C:\Program Files (x86)\Steam\steamapps\workshop\content\1158310\3798537678"
$compatch = "c:\Users\ruben\Desktop\EoE_mod_dev\EoE+compatches\other_mods\cfp-reno-compatch"

$out = @()

function Get-TemplateBlock {
    param($path, $templateName, $label)
    $result = @()
    if (-not (Test-Path $path)) {
        return @("--- ${label}: file not found ---")
    }
    $lines = Get-Content $path
    $inBlock = $false
    $depth = 0
    $blockStart = 0
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $l = $lines[$i]
        if (-not $inBlock -and $l -match "^\s*$([templateName])\s*=\s*\{") {
            $inBlock = $true
            $depth = 1
            $blockStart = $i
        }
        if ($inBlock) {
            $o = ([regex]::Matches($l, '\{')).Count
            $c = ([regex]::Matches($l, '\}')).Count
            $depth += $o - $c
            $result += "  L$($i+1): $($l)"
            if ($depth -le 0) {
                $result += ""
                $inBlock = $false
            }
        }
    }
    if ($result.Count -eq 0) {
        return @("--- ${label}: template '$templateName' NOT FOUND ---")
    }
    return $result
}

# 1. sp5_headgears template
foreach ($src in @(@{n="CFP+EPE";p="$cfpepe\gfx\portraits\portrait_modifiers\00_custom_headgear.txt"}, @{n="RENO";p="$reno\gfx\portraits\portrait_modifiers\00_custom_headgear.txt"}, @{n="COMPATCH";p="$compatch\gfx\portraits\portrait_modifiers\00_custom_headgear.txt"})) {
    $out += "########## $($src.n) - sp5_headgears ##########"
    $out += Get-TemplateBlock $src.p "sp5_headgears" $src.n
}

# 2. m_headgear_sec_sp5_byzantine_roy_01
foreach ($src in @(@{n="CFP+EPE";p="$cfpepe\gfx\portraits\portrait_modifiers\00_custom_headgear.txt"}, @{n="RENO";p="$reno\gfx\portraits\portrait_modifiers\00_custom_headgear.txt"}, @{n="COMPATCH";p="$compatch\gfx\portraits\portrait_modifiers\00_custom_headgear.txt"})) {
    $out += "########## $($src.n) - m_headgear_sec_sp5_byzantine_roy_01 ##########"
    $out += Get-TemplateBlock $src.p "m_headgear_sec_sp5_byzantine_roy_01" $src.n
}

# 3. Search for "turban" and "mail_coif" in all headgear files
$out += "########## SEARCH: turban / mail_coif in headgear files ##########"
foreach ($src in @(@{n="CFP+EPE";p="$cfpepe\gfx\portraits\portrait_modifiers"}, @{n="RENO";p="$reno\gfx\portraits\portrait_modifiers"}, @{n="COMPATCH";p="$compatch\gfx\portraits\portrait_modifiers"})) {
    if (Test-Path $src.p) {
        $files = Get-ChildItem $src.p -Filter "*.txt"
        foreach ($f in $files) {
            $hits = Select-String -Path $f.FullName -Pattern "turban|mail_coif|mailcoif" 
            if ($hits) {
                $out += "--- $($src.n) $($f.Name) ---"
                foreach ($h in $hits) {
                    $out += "  L$($h.LineNumber): $($h.Line.Trim())"
                }
            }
        }
    }
}

# 4. Also check gene file 06 for turban/mail_coif in byzantine section
$out += "########## SEARCH: turban / mail_coif in gene 06 byzantine ##########"
foreach ($src in @(@{n="CFP+EPE";p="$cfpepe\common\genes\06_genes_special_accessories_headgear.txt"}, @{n="RENO";p="$reno\common\genes\06_genes_special_accessories_headgear.txt"}, @{n="COMPATCH";p="$compatch\common\genes\06_genes_special_accessories_headgear.txt"})) {
    if (Test-Path $src.p) {
        $lines = Get-Content $src.p
        $inByz = $false
        $depth = 0
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $l = $lines[$i]
            if (-not $inByz -and $l -match "^\s*byzantine\s*=") { $inByz = $true; $depth = 0 }
            if ($inByz) {
                $o = ([regex]::Matches($l, '\{')).Count
                $c = ([regex]::Matches($l, '\}')).Count
                $depth += $o - $c
                if ($l -match "turban|mail_coif|mailcoif") {
                    $out += "  $($src.n) L$($i+1): $($l.Trim())"
                }
                if ($depth -le 0 -and $i -gt 0) { $inByz = $false }
            }
        }
    }
}

$out | Out-File "c:\Users\ruben\Desktop\EoE_mod_dev\EoE+compatches\refs\sp5_template_check.txt" -Encoding UTF8
Write-Host "Done. Output: refs\sp5_template_check.txt"
