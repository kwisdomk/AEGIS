<#
.SYNOPSIS
    AGcollect — AEGIS Baseline Collector. Gathers structured system telemetry.

.DESCRIPTION
    Collects CPU, GPU, RAM, storage, power configuration, wake locks, and
    top processes into a timestamped JSON baseline file.

    Output conforms to the AEGIS JSON Schema v1 (docs/08_schema.md).

.PARAMETER OutputDir
    Directory to save the baseline JSON file. Defaults to a "results" folder
    relative to the project root.

.EXAMPLE
    .\AGcollect.ps1
    .\AGcollect.ps1 -OutputDir "C:\Baselines"

.NOTES
    AEGIS v1.0 — Requires PowerShell 5.1+ and Administrator for full data.
#>

param(
    [string]$OutputDir = (Join-Path $PSScriptRoot "..\results")
)

# ── Bootstrap ────────────────────────────────────────────────────────────────
Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$hostname  = $env:COMPUTERNAME
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$isoTime   = Get-Date -Format "s"

# Ensure output directory exists
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$ReportPath = Join-Path $OutputDir "Baseline_${hostname}_${timestamp}.json"

Write-Host ""
Write-Host "=== AEGIS BASELINE COLLECTOR ===" -ForegroundColor Cyan
Write-Host "Machine : $hostname"
Write-Host "Target  : $ReportPath"
Write-Host ""

# ── 1. System Info ───────────────────────────────────────────────────────────
Write-Host "[*] Collecting system info..." -ForegroundColor DarkGray

$cs   = Get-WmiObject Win32_ComputerSystem
$cpu  = Get-WmiObject Win32_Processor | Select-Object -First 1

# GPU — prefer discrete (non-Intel) GPU, fall back to first available
$gpuName = "Unknown"
try {
    $allGpus = @(Get-WmiObject Win32_VideoController | Where-Object { $_.Name -notmatch 'Microsoft|Basic' })
    # Prefer discrete: anything that isn't Intel integrated
    $discrete = $allGpus | Where-Object { $_.Name -notmatch 'Intel' } | Select-Object -First 1
    $gpu = if ($discrete) { $discrete } else { $allGpus | Select-Object -First 1 }
    if ($gpu -and $gpu.Name) { $gpuName = $gpu.Name }
    # If machine has both, record both
    if ($allGpus.Count -gt 1) {
        $gpuName = ($allGpus | ForEach-Object { $_.Name }) -join ' / '
    }
} catch { }

$SystemInfo = @{
    Manufacturer = $cs.Manufacturer
    Model        = $cs.Model
    CPU          = $cpu.Name
    Cores        = [int]$cpu.NumberOfCores
    LogicalCores = [int]$cpu.NumberOfLogicalProcessors
    GPU          = $gpuName
}

# ── 2. Memory ────────────────────────────────────────────────────────────────
Write-Host "[*] Collecting memory info..." -ForegroundColor DarkGray

$ram = @(Get-WmiObject Win32_PhysicalMemory)
$totalBytes = ($ram | Measure-Object -Property Capacity -Sum).Sum

$MemoryInfo = @{
    TotalGB       = [math]::Round($totalBytes / 1GB, 2)
    Modules       = $ram.Count
    IsDualChannel = ($ram.Count -gt 1)
}

# ── 3. Storage ───────────────────────────────────────────────────────────────
Write-Host "[*] Collecting storage info..." -ForegroundColor DarkGray

$StorageInfo = @()
try {
    $disks = Get-PhysicalDisk -ErrorAction SilentlyContinue
    foreach ($d in $disks) {
        $sizeGB = [math]::Round($d.Size / 1GB, 2)

        # Determine type — check BusType to distinguish external USB drives
        $diskType = switch ($d.MediaType) {
            "SSD" { "SSD" }
            "HDD" { "HDD" }
            default {
                # Unspecified MediaType: check BusType for external drives
                if ($d.BusType -eq "USB" -or $d.BusType -eq "1394") { "External" }
                elseif ($d.BusType -eq "NVMe") { "SSD" }
                elseif ($d.BusType -eq "SATA" -or $d.BusType -eq "ATA") { "HDD" }
                else { "Unknown" }
            }
        }

        # Health status
        $health = if ($d.HealthStatus) { "$($d.HealthStatus)" } else { "Unknown" }

        $StorageInfo += @{
            Name   = $d.FriendlyName
            Type   = $diskType
            SizeGB = $sizeGB
            Health = $health
        }
    }
} catch {
    # Fallback for systems without Get-PhysicalDisk (older PS / non-admin)
    Write-Host "  [!] Get-PhysicalDisk unavailable, using WMI fallback" -ForegroundColor Yellow
    $wmiDisks = Get-WmiObject Win32_DiskDrive
    foreach ($d in $wmiDisks) {
        $sizeGB = [math]::Round($d.Size / 1GB, 2)
        $StorageInfo += @{
            Name   = $d.Model
            Type   = "Unknown"
            SizeGB = $sizeGB
            Health = "Unknown"
        }
    }
}

# ── 4. Power Configuration ──────────────────────────────────────────────────
Write-Host "[*] Collecting power configuration..." -ForegroundColor DarkGray

$PowerInfo = @{
    ActiveSchemeGUID = "Unknown"
    CpuMinStateAC    = -1
    CpuMinStateDC    = -1
}

try {
    $schemeRaw = powercfg /getactivescheme 2>$null
    $schemeMatch = [regex]::Match($schemeRaw, "GUID:\s*([\w-]+)")
    if ($schemeMatch.Success) {
        $schemeGuid = $schemeMatch.Groups[1].Value

        $minStateRaw = powercfg /query $schemeGuid SUB_PROCESSOR PROCTHROTTLEMIN 2>$null

        $acLine = $minStateRaw | Select-String "Current AC Power Setting Index:"
        $dcLine = $minStateRaw | Select-String "Current DC Power Setting Index:"

        $acVal = if ($acLine) { [int]("0x" + $acLine.ToString().Split('x')[-1]) } else { -1 }
        $dcVal = if ($dcLine) { [int]("0x" + $dcLine.ToString().Split('x')[-1]) } else { -1 }

        $PowerInfo = @{
            ActiveSchemeGUID = $schemeGuid
            CpuMinStateAC    = $acVal
            CpuMinStateDC    = $dcVal
        }
    }
} catch {
    Write-Host "  [!] Power configuration query failed" -ForegroundColor Yellow
}

# ── 5. Wake Locks ────────────────────────────────────────────────────────────
Write-Host "[*] Scanning wake locks..." -ForegroundColor DarkGray

$WakeLocks = @()
try {
    $requests = powercfg /requests 2>$null
    $currentCategory = ""
    foreach ($line in $requests) {
        if ($line -match "^([A-Z][A-Z ]+):$") {
            $currentCategory = $Matches[1].Trim()
        }
        elseif ($line -match "\[.+\]" -and $line -notmatch "None\.") {
            $WakeLocks += @{
                Category = $currentCategory
                Blocker  = $line.Trim()
            }
        }
    }
} catch {
    Write-Host "  [!] Wake lock scan failed" -ForegroundColor Yellow
}

# ── 6. Top Processes ─────────────────────────────────────────────────────────
Write-Host "[*] Sampling top processes..." -ForegroundColor DarkGray

$TopProcesses = @()
try {
    $procs = Get-Process -ErrorAction SilentlyContinue |
        Where-Object { $_.CPU -ne $null -and $_.ProcessName -ne "Idle" } |
        Sort-Object CPU -Descending |
        Select-Object -First 10

    foreach ($p in $procs) {
        $TopProcesses += @{
            Name         = $p.ProcessName
            CPU          = [math]::Round($p.CPU, 2)
            WorkingSetMB = [math]::Round($p.WorkingSet64 / 1MB, 2)
        }
    }
} catch {
    Write-Host "  [!] Process sampling failed" -ForegroundColor Yellow
}

# ── Assemble Baseline ────────────────────────────────────────────────────────
$Baseline = [ordered]@{
    Timestamp    = $isoTime
    System       = $SystemInfo
    Memory       = $MemoryInfo
    Storage      = $StorageInfo
    Power        = $PowerInfo
    WakeLocks    = $WakeLocks
    TopProcesses = $TopProcesses
}

# ── Write Output ─────────────────────────────────────────────────────────────
$Baseline | ConvertTo-Json -Depth 5 | Out-File $ReportPath -Encoding UTF8

Write-Host ""
Write-Host "[+] Baseline saved: $ReportPath" -ForegroundColor Green
Write-Host ""
