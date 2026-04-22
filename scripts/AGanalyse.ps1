<#
.SYNOPSIS
    AGanalyse - AEGIS Baseline Analyzer. Weighted, rule-based diagnostics.

.DESCRIPTION
    Reads a JSON baseline and applies diagnostic rules with severity weighting.
    Each finding carries an impact score. The total score determines the
    overall system health grade.

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
    AEGIS v1.0
#>
param(
    [string]$JsonPath
)

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

# -- Findings Collector (with weights) ----------------------------------------
# Each finding: [PSCustomObject]@{ Severity; Weight; Message }
$findings = @()
$totalScore = 0

function Add-Finding($severity, $weight, $message) {
    $script:findings += [PSCustomObject]@{
        Severity = $severity
        Weight   = $weight
        Message  = $message
    }
    $script:totalScore += $weight
}

# ==============================================================================
# RULE ENGINE
# ==============================================================================

# -- Power Rules --------------------------------------------------------------
if ($null -ne $baseline.Power.CpuMinStateAC -and $baseline.Power.CpuMinStateAC -ge 0) {
    $minAC = $baseline.Power.CpuMinStateAC
    if ($minAC -ge 100) {
        Add-Finding "CRITICAL" 40 "CPU minimum state (AC) locked at $minAC% - processor cannot idle. Causes constant heat, fan noise, and wasted power."
    } elseif ($minAC -gt 10) {
        Add-Finding "WARNING" 15 "CPU minimum state (AC) is $minAC% - above configured threshold (<=10%). Consider lowering for efficiency."
    } else {
        Add-Finding "INFO" 0 "CPU minimum state (AC) at $minAC% - within configured threshold."
    }
}

if ($null -ne $baseline.Power.CpuMinStateDC -and $baseline.Power.CpuMinStateDC -ge 0) {
    $minDC = $baseline.Power.CpuMinStateDC
    if ($minDC -ge 100) {
        Add-Finding "CRITICAL" 40 "CPU minimum state (DC/Battery) locked at $minDC% - processor runs full speed on battery. Severe battery drain."
    } elseif ($minDC -gt 10) {
        Add-Finding "WARNING" 15 "CPU minimum state (DC/Battery) is $minDC% - above configured threshold for battery mode."
    } else {
        Add-Finding "INFO" 0 "CPU minimum state (DC/Battery) at $minDC% - within configured threshold."
    }
}

# -- Memory Rules -------------------------------------------------------------
if ($null -ne $baseline.Memory.Modules) {
    if ($baseline.Memory.Modules -eq 1) {
        Add-Finding "WARNING" 50 "Single-channel memory detected ($($baseline.Memory.TotalGB) GB, 1 module). Memory bandwidth is halved compared to dual-channel configuration."
    } elseif ($baseline.Memory.Modules -ge 2) {
        Add-Finding "INFO" 0 "Dual-channel memory active: $($baseline.Memory.Modules) modules, $($baseline.Memory.TotalGB) GB total."
    }
}

if ($null -ne $baseline.Memory.TotalGB) {
    if ($baseline.Memory.TotalGB -lt 4) {
        Add-Finding "CRITICAL" 60 "Total RAM is $($baseline.Memory.TotalGB) GB - severely constrained for modern Windows workloads."
    } elseif ($baseline.Memory.TotalGB -lt 8) {
        Add-Finding "WARNING" 20 "Total RAM is $($baseline.Memory.TotalGB) GB - may limit multitasking under load."
    } else {
        Add-Finding "INFO" 0 "Total RAM: $($baseline.Memory.TotalGB) GB."
    }
}

# -- Wake Lock Rules ----------------------------------------------------------
if ($null -ne $baseline.WakeLocks -and $baseline.WakeLocks.Count -gt 0) {
    $lockCount = $baseline.WakeLocks.Count
    # Weight scales with count: 1 lock = 40, 2 = 45, 3+ = 50
    $lockWeight = [math]::Min(40 + ($lockCount * 5), 60)
    Add-Finding "WARNING" $lockWeight "Active wake locks detected ($lockCount). System sleep may be prevented:"
    foreach ($lock in $baseline.WakeLocks) {
        Add-Finding "WARNING" 0 "  [$($lock.Category)] $($lock.Blocker)"
    }
} else {
    Add-Finding "INFO" 0 "No active wake locks - sleep/hibernate should function normally."
}

# -- Storage Rules ------------------------------------------------------------
if ($null -ne $baseline.Storage -and $baseline.Storage.Count -gt 0) {
    foreach ($disk in $baseline.Storage) {
        # Unhealthy storage = critical
        if ($disk.Health -and $disk.Health -ne "Healthy" -and $disk.Health -ne "Unknown") {
            Add-Finding "CRITICAL" 70 "Storage '$($disk.Name)' reports health: '$($disk.Health)' - potential data loss risk. Back up immediately."
        }

        # HDD as primary storage
        if ($disk.Type -eq "HDD") {
            Add-Finding "WARNING" 25 "Mechanical drive (HDD) detected: '$($disk.Name)' ($($disk.SizeGB) GB). Significantly slower than SSD for system operations."
        }

        # External drive info
        if ($disk.Type -eq "External") {
            Add-Finding "INFO" 0 "External storage: '$($disk.Name)' ($($disk.SizeGB) GB) - Health: $($disk.Health)."
        }

        # Healthy SSD
        if ($disk.Type -eq "SSD" -and $disk.Health -eq "Healthy") {
            Add-Finding "INFO" 0 "SSD: '$($disk.Name)' ($($disk.SizeGB) GB) - Healthy."
        }
    }
}

# -- Process Rules ------------------------------------------------------------
# Note: CPU field = cumulative CPU seconds since process start (not real-time %).
# We flag only genuinely anomalous RAM usage. Everything else is informational.
if ($null -ne $baseline.TopProcesses -and $baseline.TopProcesses.Count -gt 0) {
    foreach ($proc in $baseline.TopProcesses) {
        # Memory hog: > 2 GB working set is genuinely anomalous
        if ($proc.WorkingSetMB -gt 2048) {
            Add-Finding "WARNING" 20 "Process '$($proc.Name)' consuming $($proc.WorkingSetMB) MB RAM (>2 GB working set)."
        }
    }

    # Informational snapshot: top 5 processes by cumulative CPU time
    $top5 = $baseline.TopProcesses | Select-Object -First 5
    $procList = ($top5 | ForEach-Object { "$($_.Name) ($($_.WorkingSetMB) MB)" }) -join ", "
    Add-Finding "INFO" 0 "Top processes by cumulative CPU time: $procList"
}

# ==============================================================================
# OUTPUT
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
Write-Host "  CRITICAL : $critCount" -ForegroundColor $(if ($critCount -gt 0) {"Red"} else {"Green"})
Write-Host "  WARNING  : $warnCount" -ForegroundColor $(if ($warnCount -gt 0) {"Yellow"} else {"Green"})
Write-Host "  INFO     : $infoCount" -ForegroundColor Gray
Write-Host ""
Write-Host "  Impact Score : $totalScore points" -ForegroundColor White

# -- Health Grade -------------------------------------------------------------
Write-Host ""
if ($totalScore -ge 70) {
    Write-Host "[!!!] CRITICAL STATE ($totalScore pts) - Immediate intervention required." -ForegroundColor Red
} elseif ($totalScore -ge 30) {
    Write-Host "[!!] NEEDS ATTENTION ($totalScore pts) - Review flagged issues." -ForegroundColor Yellow
} else {
    Write-Host "[OK] HEALTHY ($totalScore pts) - System within acceptable parameters." -ForegroundColor Green
}
Write-Host ""
