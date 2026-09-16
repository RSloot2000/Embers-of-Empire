param(
    [string]$RenoDir,
    [string]$EpeDir,
    [string[]]$Files
)

# For each shared CLOTHING gene whose refs differ between Reno and EPE,
# check whether EPE's refs are a SUBSET of Reno's refs (i.e. Reno is a proper
# union/superset). If any EPE ref is missing from Reno, that EPE clothing is LOST.
# Reuses the same parse approach as merge_genes.ps1 (gender-block detection).

function Parse-GeneRefs([string]$path) {
    $text = [System.IO.File]::ReadAllText($path) -replace "`r`n", "`n"
    $lines = $text -split "`n"
    $n = $lines.Count
    $delta = New-Object int[] $n
    $depthBefore = New-Object int[] $n
    $depth = 0
    for ($i = 0; $i -lt $n; $i++) {
        $depthBefore[$i] = $depth
        $delta[$i] = ([regex]::Matches($lines[$i], '\{')).Count - ([regex]::Matches($lines[$i], '\}')).Count
        $depth += $delta[$i]
    }
    $GENDER_RE = '^\s*(male|female|boy|girl|pregnant)\s*=\s*\{'
    $genes = @{}
    for ($i = 0; $i -lt $n; $i++) {
        $trimmed = $lines[$i].Trim()
        if ($trimmed -notmatch '^([A-Za-z_][\w]*)\s*=\s*\{') { continue }
        $key = $Matches[1]
        $d = 0; $end = $i
        for ($j = $i; $j -lt $n; $j++) { $d += $delta[$j]; if ($d -eq 0) { $end = $j; break } }
        $childDepth = $depthBefore[$i] + 1
        $isGene = $false
        for ($j = $i + 1; $j -lt $end; $j++) {
            if ($depthBefore[$j] -eq $childDepth -and $lines[$j].Trim() -match $GENDER_RE) { $isGene = $true; break }
        }
        if (-not $isGene) { continue }
        if ($genes.ContainsKey($key)) { continue }
        # collect refs: gender -> set of refs
        $refs = @{}
        $j = $i + 1
        while ($j -lt $end) {
            if ($depthBefore[$j] -ne $childDepth) { $j++; continue }
            $ct = $lines[$j].Trim()
            if ($ct -match '^([A-Za-z_][\w]*)\s*=\s*\{') {
                $gname = $Matches[1]
                $gd = 0; $gend = $j
                for ($k = $j; $k -lt $n; $k++) { $gd += $delta[$k]; if ($gd -eq 0) { $gend = $k; break } }
                $grefs = @{}
                for ($k = $j + 1; $k -lt $gend; $k++) {
                    $rt = $lines[$k].Trim()
                    if ($rt -match '^(\d+)\s*=\s*([A-Za-z_][\w]*)') { $grefs[$Matches[2]] = $true }
                }
                $refs[$gname] = $grefs
                $j = $gend + 1
            } else { $j++ }
        }
        $genes[$key] = $refs
    }
    return $genes
}

foreach ($f in $Files) {
    $r = Parse-GeneRefs (Join-Path $RenoDir $f)
    $e = Parse-GeneRefs (Join-Path $EpeDir $f)
    $lost = @()
    foreach ($k in $e.Keys) {
        if (-not $r.ContainsKey($k)) { $lost += "$k  [GENE MISSING IN RENO]"; continue }
        # for each gender, check EPE refs subset of Reno refs
        foreach ($g in $e[$k].Keys) {
            if (-not $r[$k].ContainsKey($g)) { $lost += "$k  [gender '$g' missing in Reno]"; continue }
            foreach ($ref in $e[$k][$g].Keys) {
                if (-not $r[$k][$g].ContainsKey($ref)) { $lost += "$k  [${g}: ref '$ref' LOST]" }
            }
        }
    }
    Write-Host "=== $f ==="
    if ($lost.Count -eq 0) { Write-Host "  OK: every EPE gene/ref present in Reno (Reno is a superset)" }
    else {
        Write-Host ("  LOST EPE content ({0}):" -f $lost.Count)
        $lost | ForEach-Object { Write-Host "    - $_" }
    }
    Write-Host ""
}
