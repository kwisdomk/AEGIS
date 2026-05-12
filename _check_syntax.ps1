$errs  = $null
$errs2 = $null
[System.Management.Automation.Language.Parser]::ParseFile(
    'q:\AEGIS\scripts\AGanalyse.ps1', [ref]$null, [ref]$errs) | Out-Null
[System.Management.Automation.Language.Parser]::ParseFile(
    'q:\AEGIS\scripts\AGremediate.ps1', [ref]$null, [ref]$errs2) | Out-Null

if ($errs.Count -eq 0) {
    Write-Host "AGanalyse.ps1   : OK (0 parse errors)" -ForegroundColor Green
} else {
    Write-Host "AGanalyse.ps1   : $($errs.Count) parse error(s)" -ForegroundColor Red
    $errs | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
}

if ($errs2.Count -eq 0) {
    Write-Host "AGremediate.ps1 : OK (0 parse errors)" -ForegroundColor Green
} else {
    Write-Host "AGremediate.ps1 : $($errs2.Count) parse error(s)" -ForegroundColor Red
    $errs2 | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
}
