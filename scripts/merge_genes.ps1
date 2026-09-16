# merge_genes.ps1
# Merges two CK3 special-gene files (A = base/keep, B = append-only) by FULL REBUILD.
#
# CK3 loads gene files by filename: same filename in the same directory means the
# last-loaded mod's file REPLACES the earlier one (file-level override). So when two
# mods ship the same gene filename, one mod's genes are silently lost.
#
# This script produces a merged file that:
#   - keeps A's category structure (special_genes > accessory_genes > clothes/headgear/
#     legwear, or special_genes > morph_genes + accessory_genes for file 08)
#   - keeps every A gene verbatim (raw text), EXCEPT shared-but-different CLOTHING
#     genes, which are rebuilt as a UNION of A's and B's clothing refs per gender
#   - keeps A's version of shared morph/setting genes (file 08) - documented
#   - appends each B-only gene to the matching category (in B's order)
#
# Usage:
#   pwsh ./scripts/merge_genes.ps1 -A <fileA> -B <fileB> -Out <mergedFile>
#   pwsh ./scripts/merge_genes.ps1 -A <fileA> -B <fileB> -AnalyzeOnly

param(
    [Parameter(Mandatory)][string]$A,
    [Parameter(Mandatory)][string]$B,
    [string]$Out,
    [switch]$AnalyzeOnly
)

function Read-Text([string]$path) {
    $raw = [System.IO.File]::ReadAllText($path)
    return ($raw -replace "`r`n", "`n")
}

$CATS = @('special_genes','accessory_genes','morph_genes','clothes','headgear','legwear')
$GENDER_RE = '^\s*(male|female|boy|girl|pregnant)\s*=\s*\{'

# Parse a gene file into a tree of category nodes + gene info.
# Returns @{
#   Root = node
#   Genes = [ordered]@{ geneName = @{ Raw=<string>; Refs=[ordered]@{g->[ordered]@{ref->w}}; IsCloth; Index; Aliases=[ordered]@{}; Path=<string[]> } }
# }
# A node = @{ Name; Children=[ordered]@{}; Genes=[ordered]@{} ; Path=<string[]> }
function Parse-GeneFile([string]$text) {
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

    $root = @{ Name = '_root'; Children = [ordered]@{}; Genes = [ordered]@{}; Path = @() }
    $stack = New-Object System.Collections.Generic.List[object]
    $stack.Add($root)
    $genes = [ordered]@{}

    for ($i = 0; $i -lt $n; $i++) {
        $trimmed = $lines[$i].Trim()
        if ($trimmed -notmatch '^([A-Za-z_][\w]*)\s*=\s*\{') { continue }
        $key = $Matches[1]
        $openDepth = $depthBefore[$i]
        $childDepth = $openDepth + 1
        $d = 0; $end = $i
        for ($j = $i; $j -lt $n; $j++) { $d += $delta[$j]; if ($d -eq 0) { $end = $j; break } }

        # pop stack to the right parent (depth <= openDepth)
        while ($stack.Count -gt 1 -and $depthBefore[$i] -lt (Get-NodeDepth $stack[$stack.Count-1])) { $stack.RemoveAt($stack.Count - 1) }
        $parent = $stack[$stack.Count - 1]

        if ($key -in $CATS) {
            $node = @{ Name = $key; Children = [ordered]@{}; Genes = [ordered]@{}; Path = ($parent.Path + $key) }
            $parent.Children[$key] = $node
            $stack.Add($node)
            continue
        }

        # is it a gene? direct child is a gender block
        $isGene = $false
        for ($j = $i + 1; $j -lt $end; $j++) {
            if ($depthBefore[$j] -eq $childDepth -and $lines[$j].Trim() -match $GENDER_RE) { $isGene = $true; break }
        }
        if (-not $isGene) {
            # Skip gender blocks (male, female, boy, girl, pregnant) — they're not categories
            if ($key -in @('male','female','boy','girl','pregnant')) { continue }
            # Not a gene → treat as a category node (e.g. cloaks, props_left, props_right,
            # animated_props, special_legwear — any section that wraps genes but isn't in $CATS)
            $node = @{ Name = $key; Children = [ordered]@{}; Genes = [ordered]@{}; Path = ($parent.Path + $key) }
            $parent.Children[$key] = $node
            $stack.Add($node)
            continue
        }
        if ($genes.Contains($key)) { continue }

        $cat = $parent
        $refs = [ordered]@{}; $isCloth = $false; $index = $null; $aliases = [ordered]@{}
        $j = $i + 1
        while ($j -lt $end) {
            if ($depthBefore[$j] -ne $childDepth) { $j++; continue }
            $ct = $lines[$j].Trim()
            if ($ct -match '^index\s*=\s*(\d+)') { $index = [int]$Matches[1]; $j++ }
            elseif ($ct -match '^([A-Za-z_][\w]*)\s*=\s*\{') {
                $gname = $Matches[1]
                $gd = 0; $gend = $j
                for ($k = $j; $k -lt $n; $k++) { $gd += $delta[$k]; if ($gd -eq 0) { $gend = $k; break } }
                $grefs = [ordered]@{}
                for ($k = $j + 1; $k -lt $gend; $k++) {
                    $rt = $lines[$k].Trim()
                    if ($rt -match '^(\d+)\s*=\s*([A-Za-z_][\w]*)') { $grefs[$Matches[2]] = [int]$Matches[1]; $isCloth = $true }
                }
                $refs[$gname] = $grefs
                $j = $gend + 1
            }
            elseif ($ct -match '^([A-Za-z_][\w]*)\s*=\s*([A-Za-z_][\w]*)\s*$') { $aliases[$Matches[1]] = $Matches[2]; $j++ }
            else { $j++ }
        }
        $raw = ($lines[$i..$end]) -join "`n"
        $genes[$key] = @{ Raw = $raw; Refs = $refs; IsCloth = $isCloth; Index = $index; Aliases = $aliases; Path = $parent.Path }
        $cat.Genes[$key] = $true
    }
    return @{ Root = $root; Genes = $genes }
}

function Get-NodeDepth($node) { return $node.Path.Count }

# Serialize a union gene.
function Serialize-UnionGene([string]$name, $gene, [int]$indent) {
    $pad = ' ' * (4 * $indent)
    $padIn = ' ' * (4 * $indent + 4)
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("$pad$name = {")
    if ($null -ne $gene.Index) { [void]$sb.AppendLine("$padIn    index = $($gene.Index)") }
    foreach ($g in $gene.Refs.Keys) {
        [void]$sb.AppendLine("$padIn$g = {")
        foreach ($r in $gene.Refs[$g].Keys) { [void]$sb.AppendLine("$padIn    $($gene.Refs[$g][$r]) = $r") }
        [void]$sb.AppendLine("$padIn}")
    }
    foreach ($a in $gene.Aliases.Keys) { [void]$sb.AppendLine("$padIn$a = $($gene.Aliases[$a])") }
    [void]$sb.AppendLine("$pad}")
    return $sb.ToString()
}

# ---- main ----
$textA = Read-Text $A
$textB = Read-Text $B
$parseA = Parse-GeneFile $textA
$parseB = Parse-GeneFile $textB
$allA = $parseA.Genes
$allB = $parseB.Genes

$shared=@(); $identical=@(); $different=@(); $aOnly=@(); $bOnly=@()
foreach ($k in $allA.Keys) { if ($allB.Contains($k)) { $shared += $k } else { $aOnly += $k } }
foreach ($k in $allB.Keys) { if (-not $allA.Contains($k)) { $bOnly += $k } }
foreach ($k in $shared) {
    $ga = $allA[$k]; $gb = $allB[$k]
    if ($ga.IsCloth -and $gb.IsCloth) {
        $same = $true
        foreach ($g in $ga.Refs.Keys) {
            if (-not $gb.Refs.Contains($g)) { $same=$false; break }
            foreach ($r in $ga.Refs[$g].Keys) { if (-not $gb.Refs[$g].Contains($r)) { $same=$false; break } }
            if (-not $same) { break }
        }
        if ($same) { foreach ($g in $gb.Refs.Keys) { if (-not $ga.Refs.Contains($g)) { $same=$false; break }; foreach ($r in $gb.Refs[$g].Keys) { if (-not $ga.Refs[$g].Contains($r)) { $same=$false; break } } } }
        if ($same) { $identical += $k } else { $different += $k }
    }
    else {
        if (($ga.Index -eq $gb.Index) -and ($ga.Refs.Count -eq $gb.Refs.Count)) { $identical += $k } else { $different += $k }
    }
}

Write-Host "=== $(Split-Path $A -Leaf) ==="
Write-Host "  genes: $($allA.Count)"
Write-Host "=== $(Split-Path $B -Leaf) ==="
Write-Host "  genes: $($allB.Count)"
Write-Host "shared: $($shared.Count)  (identical: $($identical.Count), different: $($different.Count))"
Write-Host "A-only: $($aOnly.Count)"
Write-Host "B-only: $($bOnly.Count)"
if ($different.Count -gt 0) {
    Write-Host ""
    Write-Host "  shared-but-different:"
    $different | ForEach-Object {
        $tag = if ($allA[$_].IsCloth) { "cloth-union" } else { "morph-keepA" }
        Write-Host "    $_  [$tag]"
    }
}
if ($bOnly.Count -gt 0) {
    Write-Host ""
    Write-Host "  B-only (appended):"
    $bOnly | ForEach-Object { Write-Host "    $_  [cat: $($allB[$_].Path -join ' > ')]" }
}

if ($AnalyzeOnly) { return }

# Build merged gene list per leaf category (in A's tree order).
# A leaf category = a node that has genes.
$mergedByPath = [ordered]@{}   # pathString -> [ordered]@{ geneName -> textBlock }
function Join-PathStr([string[]]$p) { return ($p -join ' > ') }

# Walk A's tree in order, collecting leaf categories and their merged genes.
$leafOrder = New-Object System.Collections.Generic.List[object]
function Walk-Node($node) {
    foreach ($child in $node.Children.Keys) {
        Walk-Node $node.Children[$child]
    }
    if ($node.Genes.Count -gt 0) {
        $script:leafOrder.Add($node)
    }
}
Walk-Node $parseA.Root

foreach ($leaf in $leafOrder) {
    $ps = Join-PathStr $leaf.Path
    $mergedByPath[$ps] = [ordered]@{}
    # A's genes in order
    foreach ($k in $leaf.Genes.Keys) {
        if ($allB.Contains($k) -and $allA[$k].IsCloth -and $allB[$k].IsCloth -and ($different -contains $k)) {
            # union
            $urefs = [ordered]@{}
            foreach ($g in $allA[$k].Refs.Keys) { $urefs[$g] = [ordered]@{}; foreach ($r in $allA[$k].Refs[$g].Keys) { $urefs[$g][$r] = $allA[$k].Refs[$g][$r] } }
            foreach ($g in $allB[$k].Refs.Keys) {
                if (-not $urefs.Contains($g)) { $urefs[$g] = [ordered]@{} }
                foreach ($r in $allB[$k].Refs[$g].Keys) { if (-not $urefs[$g].Contains($r)) { $urefs[$g][$r] = $allB[$k].Refs[$g][$r] } }
            }
            $ugene = @{ Index = $allA[$k].Index; Aliases = $allA[$k].Aliases; Refs = $urefs }
            $indent = $leaf.Path.Count + 1
            $mergedByPath[$ps][$k] = Serialize-UnionGene $k $ugene $indent
        }
        else {
            $mergedByPath[$ps][$k] = $allA[$k].Raw
        }
    }
    # B-only genes for this path, in B's order
    foreach ($k in $allB.Keys) {
        if ((-not $allA.Contains($k)) -and ((Join-PathStr $allB[$k].Path) -eq $ps)) {
            $mergedByPath[$ps][$k] = $allB[$k].Raw
        }
    }
}

# Serialize the tree.
function Emit-Node($node, [int]$indent) {
    $pad = ' ' * (4 * $indent)
    $sb = New-Object System.Text.StringBuilder
    if ($node.Name -ne '_root') {
        [void]$sb.AppendLine("$pad$($node.Name) = {")
    }
    foreach ($child in $node.Children.Keys) {
        $childOut = Emit-Node $node.Children[$child] ($indent + 1)
        [void]$sb.Append($childOut)
    }
    $ps = Join-PathStr $node.Path
    if ($mergedByPath.Contains($ps)) {
        foreach ($k in $mergedByPath[$ps].Keys) {
            $block = $mergedByPath[$ps][$k]
            [void]$sb.AppendLine("")
            [void]$sb.Append($block)
            [void]$sb.AppendLine("")
        }
    }
    if ($node.Name -ne '_root') {
        [void]$sb.AppendLine("$pad}")
    }
    return $sb.ToString()
}

$outText = Emit-Node $parseA.Root 0
# tidy: collapse 3+ blank lines to 1, trim trailing blank
$outText = ($outText -replace "`n{3,}", "`n`n").TrimEnd() + "`n"

if (-not $Out) { $Out = (Join-Path (Split-Path $A -Parent) ((Split-Path $A -Leaf) + ".merged")) }
$Out = [System.IO.Path]::GetFullPath($Out)
[System.IO.File]::WriteAllText($Out, $outText)
$total = $allA.Count + $bOnly.Count
Write-Host ""
Write-Host "Wrote merged file: $Out"
Write-Host "  total genes: $total  (A=$($allA.Count), B-only appended=$($bOnly.Count), union-merged=$($different.Count))"
