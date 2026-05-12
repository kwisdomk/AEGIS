<#
.SYNOPSIS
    AGremediate - AEGIS Remediation Advisor. Standalone action plan printer.

.DESCRIPTION
    Reads a JSON baseline (or auto-selects the latest), runs the same
    rule engine as AGanalyse, and prints only the prioritized ACTION PLAN:
    ranked by impact score with step-by-step fix instructions and a
    projected score outcome.

    Use this to:
      - Re-read the fix list without re-printing the full diagnosis
      - Share a clean remediation summary
      - Pipe into a log file for reference during manual fixes

    After applying fixes, close the loop with:
      .\AGcollect.ps1   (re-snapshot)
      .\AGanalyse.ps1   (re-diagnose)
      .\AGcompare.ps1   (verify improvement)

.PARAMETER JsonPath
    Path to the baseline JSON file to analyse. If omitted, uses the most
    recent baseline in the results/ directory.

.EXAMPLE
    .\AGremediate.ps1
    .\AGremediate.ps1 -JsonPath .\results\Baseline_PC_20260418_120000.json

.NOTES
    AEGIS v1.1
#>
param(
    [string]$JsonPath
)

Write-Host "Hello, I am AEGIS. Whachu wanna do..." -ForegroundColor Cyan

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# -- Auto-detect latest baseline if no path given -----------------------------
if (-not $JsonPath) {
    $resultsDir = Join-Path $PSScriptRoot "..\results"
    if (Test-Path $resultsDir) {
        $latest = Get-ChildItem $resultsDir -Filter "Baseline_*.json" |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1
        if ($latest) {
            $JsonPath = $latest.FullName
            $age = (Get-Date) - $latest.LastWriteTime
            $ageStr = if ($age.TotalDays -ge 1) {
                "$([math]::Floor($age.TotalDays)) day(s), $($age.Hours) hour(s) ago"
            } elseif ($age.TotalHours -ge 1) {
                "$([math]::Floor($age.TotalHours)) hour(s), $($age.Minutes) min ago"
            } else {
                "$([math]::Floor($age.TotalMinutes)) minute(s) ago"
            }
            Write-Host "[*] Auto-selected baseline:" -ForegroundColor DarkGray
            Write-Host "    File     : $($latest.Name)" -ForegroundColor DarkGray
            Write-Host "    Captured : $($latest.LastWriteTime)" -ForegroundColor DarkGray
            Write-Host "    Age      : $ageStr" -ForegroundColor DarkGray
            if ($age.TotalHours -gt 24) {
                Write-Host "    [!] Baseline is older than 24 hours. Re-run AGcollect for a current snapshot." -ForegroundColor Yellow
            }
        }
    }
    if (-not $JsonPath) {
        Write-Host "[ERROR] No baseline found. Run AGcollect.ps1 first." -ForegroundColor Red
        exit 1
    }
}

if (-not (Test-Path $JsonPath)) {
    Write-Host "[ERROR] File not found: $JsonPath" -ForegroundColor Red
    exit 1
}

try {
    $raw = Get-Content $JsonPath -Raw -Encoding UTF8
    $baseline = $raw | ConvertFrom-Json
} catch {
    Write-Host "[ERROR] Failed to parse JSON: $_" -ForegroundColor Red
    exit 1
}

# -- Findings Collector -------------------------------------------------------
. (Join-Path $PSScriptRoot "AGrules.ps1")
$analysis = Invoke-AEGISAnalysis -baseline $baseline
$findings = $analysis.Findings
$totalScore = $analysis.TotalScore

# ==============================================================================
# OUTPUT -- ACTION PLAN ONLY
# ==============================================================================

Write-Host ""
Write-Host "=== AEGIS ACTION PLAN ===" -ForegroundColor Cyan
Write-Host "Baseline : $(Split-Path $JsonPath -Leaf)"
Write-Host "Machine  : $($baseline.System.Manufacturer) $($baseline.System.Model)"
Write-Host ""

$actionable = @(
    $findings |
    Where-Object { $_.Weight -gt 0 -and $_.Remedy -ne "" } |
    Sort-Object Weight -Descending
)

if ($actionable.Count -eq 0) {
    Write-Host "[OK] No actionable findings. System appears healthy." -ForegroundColor Green
    Write-Host ""
    exit 0
}

# -- Score headline -----------------------------------------------------------
if ($totalScore -ge 70) {
    Write-Host "[!!!] CRITICAL STATE ($totalScore pts)" -ForegroundColor Red
} elseif ($totalScore -ge 30) {
    Write-Host "[!!] NEEDS ATTENTION ($totalScore pts)" -ForegroundColor Yellow
} else {
    Write-Host "[OK] HEALTHY ($totalScore pts)" -ForegroundColor Green
}
Write-Host ""
Write-Host "Ranked by impact - fix the top items first." -ForegroundColor DarkGray
Write-Host ""

$rank          = 1
$potentialSave = 0

foreach ($item in $actionable) {
    $potentialSave += $item.Weight

    $shortMsg = if ($item.Message.Length -gt 65) {
        $item.Message.Substring(0, 62) + "..."
    } else {
        $item.Message
    }

    $color = if ($item.Severity -eq "CRITICAL") { "Red" } else { "Yellow" }
    Write-Host "[$rank] $shortMsg" -ForegroundColor $color
    Write-Host "    Potential score reduction : -$($item.Weight) pts" -ForegroundColor DarkGray

    $remedyLines = $item.Remedy -split "`n"
    foreach ($line in $remedyLines) {
        Write-Host "    $line" -ForegroundColor White
    }
    Write-Host ""
    $rank++
}

# -- Potential outcome --------------------------------------------------------
$projectedScore = [math]::Max(0, $totalScore - $potentialSave)
Write-Host "--- Potential Outcome ---" -ForegroundColor Cyan
Write-Host "  Current score   : $totalScore pts" -ForegroundColor White
Write-Host "  Max reduction   : -$potentialSave pts" -ForegroundColor Green
$projColor = if ($projectedScore -ge 70) { "Red" } elseif ($projectedScore -ge 30) { "Yellow" } else { "Green" }
Write-Host "  Projected score : ~$projectedScore pts" -ForegroundColor $projColor
Write-Host ""

# -- Close-the-loop footer ----------------------------------------------------
Write-Host "--- Close the loop ---" -ForegroundColor Cyan
Write-Host "  After applying fixes, run these commands in order:" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Step 1 - Re-collect  : .\scripts\AGcollect.ps1" -ForegroundColor Green
Write-Host "  Step 2 - Re-analyse  : .\scripts\AGanalyse.ps1" -ForegroundColor Green
Write-Host "  Step 3 - Compare     : .\scripts\AGcompare.ps1" -ForegroundColor Green
Write-Host ""
