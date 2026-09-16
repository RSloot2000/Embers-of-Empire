param(
    [string]$RenoDir,
    [string]$EpeDir,
    [string[]]$Files
)

# Extract all leaf gene containers: any "key = {" block (any depth) whose body
# contains "male = {" or "female = {" or "index =". Returns hashtable key -> normalized body.
function Get-LeafContainers([string]$path) {
    $lines = Get-Content $path
    $result = @{}
    # stack entries: [key, startLineIndex]
    $stack = New-Object System.Collections.Generic.List[object]
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $l = $lines[$i]
        $opens = ([regex]::Matches($l, '\{')).Count
        $closes = ([regex]::Matches($l, '\}')).Count
        if ($l -match '^\s*([a-z0-9_]+)\s*=\s*\{') {
            $stack.Add(@($Matches[1], $i))
        }
        for ($c = 0; $c -lt $closes; $c++) {
            if ($stack.Count -eq 0) { continue }
            $top = $stack[$stack.Count - 1]
            $stack.RemoveAt($stack.Count - 1)
            $body = ($lines[$top[1]..$i] -join "`n") -replace '\s+', ' '
            $isLeaf = ($body -match 'male\s*=\s*\{' -or $body -match 'female\s*=\s*\{' -or $body -match 'index\s*=')
            if ($isLeaf -and -not $result.ContainsKey($top[0])) {
                $result[$top[0]] = $body
            }
        }
    }
    return $result
}

foreach ($f in $Files) {
    $rp = Join-Path $RenoDir $f
    $ep = Join-Path $EpeDir $f
    if (-not (Test-Path $rp)) { Write-Host "=== $f === (missing in Reno)"; continue }
    if (-not (Test-Path $ep)) { Write-Host "=== $f === (missing in EPE)"; continue }
    $r = Get-LeafContainers $rp
    $e = Get-LeafContainers $ep
    $shared = @($r.Keys | Where-Object { $_ -in $e.Keys })
    $onlyR = @($r.Keys | Where-Object { $_ -notin $e.Keys })
    $onlyE = @($e.Keys | Where-Object { $_ -notin $r.Keys })
    $conflicts = @()
    foreach ($k in $shared) { if ($r[$k] -ne $e[$k]) { $conflicts += $k } }
    Write-Host "=== $f ==="
    Write-Host ("  Reno leaf containers: {0}   EPE leaf containers: {1}" -f $r.Count, $e.Count)
    Write-Host ("  Shared: {0}   Only-Reno: {1}   Only-EPE: {2}" -f $shared.Count, $onlyR.Count, $onlyE.Count)
    Write-Host ("  CONFLICTS (shared key, different body): {0}" -f $conflicts.Count)
    $conflicts | ForEach-Object { Write-Host "    - $_" }
    Write-Host "  Only-EPE (missing from Reno):"
    $onlyE | ForEach-Object { Write-Host "    - $_" }
    Write-Host ""
}
