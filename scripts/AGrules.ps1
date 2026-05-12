<#
.SYNOPSIS
    AGrules - Shared Rule Engine for AEGIS

.DESCRIPTION
    Contains the core analysis rules used by both AGanalyse and AGremediate.
    Provides the Invoke-AEGISAnalysis function which returns structured findings.
#>

$script:findings = @()
$script:totalScore = 0

function Invoke-AEGISAnalysis {
    param(
        [Parameter(Mandatory=$true)]
        [object]$baseline
    )

    $script:findings = @()
    $script:totalScore = 0

    function Add-Finding {
        param($severity, $weight, $message, $remedy = "")
        $script:findings += [PSCustomObject]@{
            Severity = $severity
            Weight   = $weight
            Message  = $message
            Remedy   = $remedy
        }
        $script:totalScore += $weight
    }

    # -- Power Rules --------------------------------------------------------------
    if ($null -ne $baseline.Power.CpuMinStateAC -and $baseline.Power.CpuMinStateAC -ge 0) {
        $minAC = $baseline.Power.CpuMinStateAC
        if ($minAC -ge 100) {
            $remedy = @(
                "Run the following in an elevated (Admin) PowerShell, then reboot:",
                "  powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 5",
                "  powercfg /setactive SCHEME_CURRENT",
                "Verify with: powercfg /query SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN"
            ) -join "`n"
            Add-Finding "CRITICAL" 40 "CPU minimum state (AC) locked at $minAC% - processor cannot idle. Causes constant heat, fan noise, and wasted power." $remedy
        } elseif ($minAC -gt 10) {
            $remedy = @(
                "Run in elevated PowerShell:",
                "  powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 5",
                "  powercfg /setactive SCHEME_CURRENT"
            ) -join "`n"
            Add-Finding "WARNING" 15 "CPU minimum state (AC) is $minAC% - above configured threshold (<=10%). Consider lowering for efficiency." $remedy
        } else {
            Add-Finding "INFO" 0 "CPU minimum state (AC) at $minAC% - within configured threshold."
        }
    }

    if ($null -ne $baseline.Power.CpuMinStateDC -and $baseline.Power.CpuMinStateDC -ge 0) {
        $minDC = $baseline.Power.CpuMinStateDC
        if ($minDC -ge 100) {
            $remedy = @(
                "Run in elevated PowerShell:",
                "  powercfg /setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 5",
                "  powercfg /setactive SCHEME_CURRENT",
                "This alone can double battery life on affected systems."
            ) -join "`n"
            Add-Finding "CRITICAL" 40 "CPU minimum state (DC/Battery) locked at $minDC% - processor runs full speed on battery. Severe battery drain." $remedy
        } elseif ($minDC -gt 10) {
            $remedy = @(
                "Run in elevated PowerShell:",
                "  powercfg /setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 5",
                "  powercfg /setactive SCHEME_CURRENT"
            ) -join "`n"
            Add-Finding "WARNING" 15 "CPU minimum state (DC/Battery) is $minDC% - above configured threshold for battery mode." $remedy
        } else {
            Add-Finding "INFO" 0 "CPU minimum state (DC/Battery) at $minDC% - within configured threshold."
        }
    }

    # -- Memory Rules -------------------------------------------------------------
    if ($null -ne $baseline.Memory.Modules) {
        if ($baseline.Memory.Modules -eq 1) {
            $totalGB = $baseline.Memory.TotalGB
            $remedy = @(
                "Install a second RAM module identical to the existing one",
                "(same brand, capacity, speed, and CAS latency) into the second DIMM slot.",
                "- Power off and unplug before opening.",
                "- Use the Crucial System Scanner (crucial.com/store/advisor) to find compatible sticks.",
                "- Expected uplift: significant FPS / bandwidth improvement in CPU-limited workloads."
            ) -join "`n"
            Add-Finding "WARNING" 50 "Single-channel memory detected ($totalGB GB, 1 module). Memory bandwidth is halved compared to dual-channel configuration." $remedy
        } elseif ($baseline.Memory.Modules -ge 2) {
            Add-Finding "INFO" 0 "Dual-channel memory active: $($baseline.Memory.Modules) modules, $($baseline.Memory.TotalGB) GB total."
        }
    }

    if ($null -ne $baseline.Memory.TotalGB) {
        $totalGB = $baseline.Memory.TotalGB
        if ($totalGB -lt 4) {
            $remedy = @(
                "Upgrade RAM to at least 8 GB (16 GB recommended for modern workloads).",
                "- Check maximum supported RAM in your device manual or manufacturer spec sheet.",
                "- Use the Crucial System Scanner or CPU-Z (free) to identify compatible modules."
            ) -join "`n"
            Add-Finding "CRITICAL" 60 "Total RAM is $totalGB GB - severely constrained for modern Windows workloads." $remedy
        } elseif ($totalGB -lt 8) {
            $remedy = "Consider upgrading to 8-16 GB. Run CPU-Z (free) to identify compatible RAM for your system."
            Add-Finding "WARNING" 20 "Total RAM is $totalGB GB - may limit multitasking under load." $remedy
        } else {
            Add-Finding "INFO" 0 "Total RAM: $totalGB GB."
        }
    }

    # -- Wake Lock Rules ----------------------------------------------------------
    if ($null -ne $baseline.WakeLocks -and $baseline.WakeLocks.Count -gt 0) {
        $lockCount  = $baseline.WakeLocks.Count
        $lockWeight = [math]::Min(40 + ($lockCount * 5), 60)
        $lockNames  = ($baseline.WakeLocks | ForEach-Object { "  - $($_.Blocker)" }) -join "`n"
        $remedy = @(
            "For each blocker below, choose one option:",
            "  A. Quick:     Right-click the app in the system tray -> Exit",
            "  B. Sustained: Task Manager (Ctrl+Shift+Esc) -> Startup tab -> Disable the app",
            "  C. Nuclear:   Uninstall if the app is not needed",
            "Blockers found:",
            $lockNames,
            "After closing them, re-collect to confirm the locks are gone."
        ) -join "`n"
        Add-Finding "WARNING" $lockWeight "Active wake locks detected ($lockCount). System sleep may be prevented:" $remedy
        foreach ($lock in $baseline.WakeLocks) {
            Add-Finding "WARNING" 0 "  [$($lock.Category)] $($lock.Blocker)"
        }
    } else {
        Add-Finding "INFO" 0 "No active wake locks - sleep/hibernate should function normally."
    }

    # -- Storage Rules ------------------------------------------------------------
    if ($null -ne $baseline.Storage -and $baseline.Storage.Count -gt 0) {
        foreach ($disk in $baseline.Storage) {
            if ($disk.Health -and $disk.Health -ne "Healthy" -and $disk.Health -ne "Unknown") {
                $remedy = @(
                    "IMMEDIATE ACTIONS:",
                    "  1. Back up all critical data NOW before doing anything else.",
                    "  2. Run: chkdsk C: /f /r  (replace C: with the affected drive letter) - requires reboot.",
                    "  3. Download CrystalDiskInfo (free, crystalmark.info) for a full S.M.A.R.T. report.",
                    "  4. If reallocated sectors are non-zero or growing, plan immediate drive replacement."
                ) -join "`n"
                Add-Finding "CRITICAL" 70 "Storage '$($disk.Name)' reports health: '$($disk.Health)' - potential data loss risk. Back up immediately." $remedy
            }

            if ($disk.Type -eq "HDD") {
                $remedy = @(
                    "Replace with an SSD (SATA or NVMe depending on your slot) for a major responsiveness uplift.",
                    "- Benchmark current speed first with CrystalDiskMark (free) for before/after comparison.",
                    "- Clone the existing drive with Macrium Reflect Free or Samsung Data Migration (if using Samsung SSD)."
                ) -join "`n"
                Add-Finding "WARNING" 25 "Mechanical drive (HDD) detected: '$($disk.Name)' ($($disk.SizeGB) GB). Significantly slower than SSD." $remedy
            }

            if ($disk.Type -eq "External") {
                Add-Finding "INFO" 0 "External storage: '$($disk.Name)' ($($disk.SizeGB) GB) - Health: $($disk.Health)."
            }

            if ($disk.Type -eq "SSD" -and $disk.Health -eq "Healthy") {
                Add-Finding "INFO" 0 "SSD: '$($disk.Name)' ($($disk.SizeGB) GB) - Healthy."
            }
        }
    }

    # -- Process Rules ------------------------------------------------------------
    if ($null -ne $baseline.TopProcesses -and $baseline.TopProcesses.Count -gt 0) {
        foreach ($proc in $baseline.TopProcesses) {
            if ($proc.WorkingSetMB -gt 2048) {
                $pname = $proc.Name
                $remedy = @(
                    "Investigate '$pname':",
                    "  A. If a browser: close unused tabs or restart it.",
                    "  B. If a background service: Task Manager -> Services tab -> disable if not needed.",
                    "  C. If unknown: search the process name online to confirm legitimacy."
                ) -join "`n"
                Add-Finding "WARNING" 20 "Process '$($proc.Name)' consuming $($proc.WorkingSetMB) MB RAM (>2 GB working set)." $remedy
            }
        }

        $top5     = $baseline.TopProcesses | Select-Object -First 5
        $procList = ($top5 | ForEach-Object { "$($_.Name) ($($_.WorkingSetMB) MB)" }) -join ", "
        Add-Finding "INFO" 0 "Top processes by cumulative CPU time: $procList"
    }

    return [PSCustomObject]@{
        Findings   = $script:findings
        TotalScore = $script:totalScore
    }
}
