<#
.SYNOPSIS
    AGcompare — AEGIS Baseline Comparator. Before/after delta analysis.

.DESCRIPTION
    Compares two JSON baselines to identify improvements, regressions,
    and unchanged values. Reports a weighted delta with a final verdict.

.PARAMETER Before
    Path to the earlier (pre-change) baseline JSON.

.PARAMETER After
    Path to the later (post-change) baseline JSON.

.EXAMPLE
    .\AGcompare.ps1 -Before .\results\before.json -After .\results\after.json

.NOTES
    AEGIS v1.0
#>
param(
    [string]$Before,
    [string]$After
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── Auto-detect baselines if not provided ─────────────────────────────────────
$resultsDir = Join-Path $PSScriptRoot "..\results"

function Format-Age($timespan) {
    if ($timespan.TotalDays -ge 1) {
        return "$([math]::Floor($timespan.TotalDays)) day(s), $($timespan.Hours) hour(s) ago"
    } elseif ($timespan.TotalHours -ge 1) {
        return "$([math]::Floor($timespan.TotalHours)) hour(s), $($timespan.Minutes) min ago"
    } else {
        return "$([math]::Floor($timespan.TotalMinutes)) minute(s) ago"
    }
}

if (-not $Before -or -not $After) {
    if (-not (Test-Path $resultsDir)) {
        Write-Host "[ERROR] No results directory found. Run AGcollect.ps1 first." -ForegroundColor Red
        exit 1
    }
    $allBaselines = @(Get-ChildItem $resultsDir -Filter "Baseline_*.json" | Sort-Object LastWriteTime -Descending)
    if ($allBaselines.Count -lt 2) {
        Write-Host "[ERROR] Need at least 2 baselines to compare. Run AGcollect.ps1 again after making changes." -ForegroundColor Red
        Write-Host "        Found: $($allBaselines.Count) baseline(s) in $resultsDir" -ForegroundColor Yellow
        exit 1
    }
    if (-not $After)  { $After  = $allBaselines[0].FullName }
    if (-not $Before) { $Before = $allBaselines[1].FullName }

    $now = Get-Date
    $beforeAge = $now - $allBaselines[1].LastWriteTime
    $afterAge  = $now - $allBaselines[0].LastWriteTime
    $gap       = $allBaselines[0].LastWriteTime - $allBaselines[1].LastWriteTime

    Write-Host "[*] Auto-selected baselines:" -ForegroundColor DarkGray
    Write-Host "    Before : $($allBaselines[1].Name)" -ForegroundColor DarkGray
    Write-Host "             Captured $(Format-Age $beforeAge)" -ForegroundColor DarkGray
    Write-Host "    After  : $($allBaselines[0].Name)" -ForegroundColor DarkGray
    Write-Host "             Captured $(Format-Age $afterAge)" -ForegroundColor DarkGray

    $gapStr = if ($gap.TotalDays -ge 1) {
        "$([math]::Floor($gap.TotalDays)) day(s), $($gap.Hours) hour(s)"
    } elseif ($gap.TotalHours -ge 1) {
        "$([math]::Floor($gap.TotalHours)) hour(s), $($gap.Minutes) min"
    } else {
        "$([math]::Floor($gap.TotalMinutes)) minute(s)"
    }
    Write-Host "    Gap    : $gapStr between snapshots" -ForegroundColor DarkGray

    if ($beforeAge.TotalHours -gt 24 -or $afterAge.TotalHours -gt 24) {
        Write-Host "    [!] One or both baselines are older than 24 hours." -ForegroundColor Yellow
    }
}

# ── Helpers ──────────────────────────────────────────────────────────────────
function Import-Baseline($path) {
    if (-not (Test-Path $path)) {
        Write-Host "[ERROR] File not found: $path" -ForegroundColor Red
        exit 1
    }
    try {
        return (Get-Content $path -Raw -Encoding UTF8 | ConvertFrom-Json)
    } catch {
        Write-Host "[ERROR] Failed to parse: $path" -ForegroundColor Red
        exit 1
    }
}

function Show-Delta($label, $oldVal, $newVal, $unit, $lowerIsBetter) {
    if ($null -eq $oldVal -or $null -eq $newVal) {
        Write-Host "  $label : N/A"
        return "neutral"
    }
    if ($oldVal -eq $newVal) {
        Write-Host "  $label : $oldVal$unit (unchanged)" -ForegroundColor Gray
        return "neutral"
    }

    $arrow = "$oldVal$unit -> $newVal$unit"
    if ($lowerIsBetter) {
        $improved = $newVal -lt $oldVal
    } else {
        $improved = $newVal -gt $oldVal
    }

    if ($improved) {
        Write-Host "  $label : $arrow [IMPROVED]" -ForegroundColor Green
        return "improved"
    } else {
        Write-Host "  $label : $arrow [REGRESSED]" -ForegroundColor Red
        return "regressed"
    }
}

# ── Load Data ────────────────────────────────────────────────────────────────
$b = Import-Baseline $Before
$a = Import-Baseline $After

Write-Host ""
Write-Host "=== AEGIS COMPARISON ===" -ForegroundColor Cyan
Write-Host "Before : $(Split-Path $Before -Leaf)  ($($b.Timestamp))"
Write-Host "After  : $(Split-Path $After -Leaf)  ($($a.Timestamp))"
Write-Host ""

$improvements = 0
$regressions  = 0

# ── System Info ──────────────────────────────────────────────────────────────
Write-Host "[System]" -ForegroundColor White
if ($b.System.CPU -ne $a.System.CPU) {
    Write-Host "  CPU : $($b.System.CPU) -> $($a.System.CPU) [CHANGED]" -ForegroundColor Yellow
} else {
    Write-Host "  CPU : $($b.System.CPU) (unchanged)" -ForegroundColor Gray
}
if ($b.System.GPU -ne $a.System.GPU) {
    Write-Host "  GPU : $($b.System.GPU) -> $($a.System.GPU) [CHANGED]" -ForegroundColor Yellow
}
Write-Host ""

# ── Power ────────────────────────────────────────────────────────────────────
Write-Host "[Power]" -ForegroundColor White
$r = Show-Delta "CPU Min State (AC)" $b.Power.CpuMinStateAC $a.Power.CpuMinStateAC "%" $true
if ($r -eq "improved") { $improvements++ } elseif ($r -eq "regressed") { $regressions++ }
$r = Show-Delta "CPU Min State (DC)" $b.Power.CpuMinStateDC $a.Power.CpuMinStateDC "%" $true
if ($r -eq "improved") { $improvements++ } elseif ($r -eq "regressed") { $regressions++ }
Write-Host ""

# ── Memory ───────────────────────────────────────────────────────────────────
Write-Host "[Memory]" -ForegroundColor White
$r = Show-Delta "Total GB" $b.Memory.TotalGB $a.Memory.TotalGB " GB" $false
if ($r -eq "improved") { $improvements++ } elseif ($r -eq "regressed") { $regressions++ }
$r = Show-Delta "Modules" $b.Memory.Modules $a.Memory.Modules "" $false
if ($r -eq "improved") { $improvements++ } elseif ($r -eq "regressed") { $regressions++ }

if ($b.Memory.IsDualChannel -ne $a.Memory.IsDualChannel) {
    $dcBefore = if ($b.Memory.IsDualChannel) { "Yes" } else { "No" }
    $dcAfter  = if ($a.Memory.IsDualChannel) { "Yes" } else { "No" }
    $color = if ($a.Memory.IsDualChannel) { "Green" } else { "Red" }
    Write-Host "  Dual-Channel : $dcBefore -> $dcAfter" -ForegroundColor $color
    if ($a.Memory.IsDualChannel) { $improvements++ } else { $regressions++ }
}
Write-Host ""

# ── Storage ──────────────────────────────────────────────────────────────────
Write-Host "[Storage]" -ForegroundColor White

# Compare matching disks
if ($null -ne $a.Storage) {
    foreach ($aDisk in $a.Storage) {
        $bDisk = $null
        if ($null -ne $b.Storage) {
            $bDisk = $b.Storage | Where-Object { $_.Name -eq $aDisk.Name } | Select-Object -First 1
        }
        if ($null -ne $bDisk) {
            if ($bDisk.Health -ne $aDisk.Health) {
                Write-Host "  $($aDisk.Name) Health: $($bDisk.Health) -> $($aDisk.Health)" -ForegroundColor Yellow
            } else {
                Write-Host "  $($aDisk.Name) : $($aDisk.Health) (unchanged)" -ForegroundColor Gray
            }
        } else {
            Write-Host "  $($aDisk.Name) : [NEW DISK]" -ForegroundColor Green
        }
    }
}

# Removed disks
if ($null -ne $b.Storage) {
    foreach ($bDisk in $b.Storage) {
        $still = $null
        if ($null -ne $a.Storage) {
            $still = $a.Storage | Where-Object { $_.Name -eq $bDisk.Name } | Select-Object -First 1
        }
        if ($null -eq $still) {
            Write-Host "  $($bDisk.Name) : [REMOVED]" -ForegroundColor Red
        }
    }
}
Write-Host ""

# ── Wake Locks ───────────────────────────────────────────────────────────────
Write-Host "[Wake Locks]" -ForegroundColor White
$bLockCount = if ($null -ne $b.WakeLocks) { $b.WakeLocks.Count } else { 0 }
$aLockCount = if ($null -ne $a.WakeLocks) { $a.WakeLocks.Count } else { 0 }

$r = Show-Delta "Active Locks" $bLockCount $aLockCount "" $true
if ($r -eq "improved") { $improvements++ } elseif ($r -eq "regressed") { $regressions++ }

if ($aLockCount -gt 0) {
    foreach ($lock in $a.WakeLocks) {
        Write-Host "    - [$($lock.Category)] $($lock.Blocker)" -ForegroundColor Yellow
    }
}
Write-Host ""

# ── Top Processes ────────────────────────────────────────────────────────────
Write-Host "[Top Processes — After]" -ForegroundColor White
if ($null -ne $a.TopProcesses -and $a.TopProcesses.Count -gt 0) {
    $top5 = $a.TopProcesses | Select-Object -First 5
    foreach ($p in $top5) {
        Write-Host "  $($p.Name) : $($p.WorkingSetMB) MB RAM" -ForegroundColor Gray
    }
}
Write-Host ""

# ── Verdict ──────────────────────────────────────────────────────────────────
Write-Host "--- Verdict ---" -ForegroundColor Cyan
Write-Host "  Improvements : $improvements" -ForegroundColor Green
Write-Host "  Regressions  : $regressions"  -ForegroundColor $(if ($regressions -gt 0) {"Red"} else {"Green"})
Write-Host ""

if ($regressions -gt 0 -and $improvements -eq 0) {
    Write-Host "[!] System regressed. Review changes." -ForegroundColor Red
} elseif ($regressions -gt 0 -and $improvements -gt 0) {
    Write-Host "[~] Mixed results. Some improvements, some regressions." -ForegroundColor Yellow
} elseif ($improvements -gt 0) {
    Write-Host "[OK] System improved." -ForegroundColor Green
} else {
    Write-Host "[=] No significant changes detected." -ForegroundColor Gray
}
Write-Host ""
