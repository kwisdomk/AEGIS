<#
.SYNOPSIS
    AGanalyse - AEGIS Baseline Analyzer. Weighted, rule-based diagnostics.

.DESCRIPTION
    Reads a JSON baseline and applies diagnostic rules with severity weighting.
    Each finding carries an impact score. The total score determines the
    overall system health grade.

    After the diagnosis, an ACTION PLAN is printed: findings ranked by impact
    with step-by-step fix instructions and a re-test command sequence.

    Scoring thresholds:
        0-29  points = HEALTHY
        30-69 points = NEEDS ATTENTION
        70+   points = CRITICAL STATE

.PARAMETER JsonPath
    Path to the baseline JSON file to analyze. If omitted, uses the most
    recent baseline in the results/ directory.

.EXAMPLE
    .\AGanalyse.ps1 -JsonPath .\results\Baseline_PC_20260418_120000.json
    .\AGanalyse.ps1

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
                Write-Host "    [!] Baseline is older than 24 hours. Consider running AGcollect for a current snapshot." -ForegroundColor Yellow
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

Write-Host ""
Write-Host "=== AEGIS DIAGNOSIS ===" -ForegroundColor Cyan
Write-Host "Baseline : $(Split-Path $JsonPath -Leaf)"
Write-Host "Captured : $($baseline.Timestamp)"
Write-Host "Machine  : $($baseline.System.Manufacturer) $($baseline.System.Model)"
Write-Host "CPU      : $($baseline.System.CPU)"
Write-Host "GPU      : $($baseline.System.GPU)"
Write-Host ""

# -- Findings Collector -------------------------------------------------------
. (Join-Path $PSScriptRoot "AGrules.ps1")
$analysis = Invoke-AEGISAnalysis -baseline $baseline
$findings = $analysis.Findings
$totalScore = $analysis.TotalScore

# ==============================================================================
# DIAGNOSIS OUTPUT  (unchanged from v1.0)
# ==============================================================================

$sevColors = @{ CRITICAL = "Red"; WARNING = "Yellow"; INFO = "Gray" }
$sevOrder  = @("CRITICAL", "WARNING", "INFO")

foreach ($sev in $sevOrder) {
    $items = @($findings | Where-Object { $_.Severity -eq $sev })
    if ($items.Count -gt 0) {
        Write-Host "[$sev]" -ForegroundColor $sevColors[$sev]
        foreach ($item in $items) {
            $weightTag = if ($item.Weight -gt 0) { " (+$($item.Weight))" } else { "" }
            Write-Host "  $($item.Message)$weightTag" -ForegroundColor $sevColors[$sev]
        }
        Write-Host ""
    }
}

# -- Severity Summary ---------------------------------------------------------
$critCount = @($findings | Where-Object { $_.Severity -eq "CRITICAL" }).Count
$warnCount = @($findings | Where-Object { $_.Severity -eq "WARNING" }).Count
$infoCount = @($findings | Where-Object { $_.Severity -eq "INFO" }).Count

Write-Host "--- Weighted Summary ---" -ForegroundColor Cyan
Write-Host "  CRITICAL : $critCount" -ForegroundColor $(if ($critCount -gt 0) { "Red" } else { "Green" })
Write-Host "  WARNING  : $warnCount" -ForegroundColor $(if ($warnCount -gt 0) { "Yellow" } else { "Green" })
Write-Host "  INFO     : $infoCount" -ForegroundColor Gray
Write-Host ""
Write-Host "  Impact Score : $totalScore points" -ForegroundColor White

# -- Health Grade -------------------------------------------------------------
Write-Host ""
$grade = if ($totalScore -ge 70) { "CRITICAL STATE" } elseif ($totalScore -ge 30) { "NEEDS ATTENTION" } else { "HEALTHY" }
if ($totalScore -ge 70) {
    Write-Host "[!!!] CRITICAL STATE ($totalScore pts) - Immediate intervention required." -ForegroundColor Red
} elseif ($totalScore -ge 30) {
    Write-Host "[!!] NEEDS ATTENTION ($totalScore pts) - Review flagged issues." -ForegroundColor Yellow
} else {
    Write-Host "[OK] HEALTHY ($totalScore pts) - System within acceptable parameters." -ForegroundColor Green
}
Write-Host ""

# ==============================================================================
# ACTION PLAN  (new in v1.1)
# ==============================================================================

$actionable = @(
    $findings |
    Where-Object { $_.Weight -gt 0 -and $_.Remedy -ne "" } |
    Sort-Object Weight -Descending
)

if ($actionable.Count -gt 0) {
    Write-Host "=== ACTION PLAN ===" -ForegroundColor Cyan
    Write-Host "Ranked by impact - fix the top items first." -ForegroundColor DarkGray
    Write-Host ""

    $rank = 1
    foreach ($item in $actionable) {
        $shortMsg = if ($item.Message.Length -gt 90) {
            $item.Message.Substring(0, 87) + "..."
        } else {
            $item.Message
        }

        $color = if ($item.Severity -eq "CRITICAL") { "Red" } else { "Yellow" }
        Write-Host "[$rank] PROBLEM: $shortMsg" -ForegroundColor $color
        Write-Host "    IMPACT : -$($item.Weight) pts" -ForegroundColor DarkGray
        Write-Host "    REMEDY :" -ForegroundColor DarkGray

        $remedyLines = $item.Remedy -split "`n"
        foreach ($line in $remedyLines) {
            Write-Host "      $line" -ForegroundColor White
        }
        Write-Host " "
        $rank++
    }

    # -- Close-the-loop footer ------------------------------------------------
    Write-Host "--- Close the loop ---" -ForegroundColor Cyan
    Write-Host "  After applying fixes, run these commands in order:" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Step 1 - Re-collect  : .\scripts\AGcollect.ps1" -ForegroundColor Green
    Write-Host "  Step 2 - Re-analyse  : .\scripts\AGanalyse.ps1" -ForegroundColor Green
    Write-Host "  Step 3 - Compare     : .\scripts\AGcompare.ps1" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Or for just the action plan: .\scripts\AGremediate.ps1" -ForegroundColor Green
    Write-Host ""
}
