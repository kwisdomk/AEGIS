# AEGIS Documentation — v1.0

**Automated Environment Gathering & Inspection System**

A portable Windows diagnostic framework that converts any machine into a measurable, analyzable environment. No installation required.

---

## Table of Contents

1. [Overview](#overview)
2. [Requirements](#requirements)
3. [Installation](#installation)
4. [Usage](#usage)
5. [Architecture](#architecture)
6. [JSON Baseline Schema](#json-baseline-schema)
7. [Diagnostic Rules & Scoring](#diagnostic-rules--scoring)
8. [Decision Tree](#decision-tree)
9. [Design Principles](#design-principles)
10. [Known Limitations](#known-limitations)
11. [Future Improvements](#future-improvements)
12. [Troubleshooting](#troubleshooting)
13. [Changelog](#changelog)

---

## Overview

AEGIS is a portable diagnostic framework for Windows. It works in three stages:

1. **Collect** — Gather structured system telemetry into a JSON baseline
2. **Analyse** — Apply rule-based diagnostics with weighted severity scoring
3. **Compare** — Measure before/after changes with delta reporting

AEGIS exists to answer three questions:

- What is the current system state?
- What is wrong or inefficient?
- Did my changes improve the system?

It does not modify system settings, apply fixes, or run in the background. It is strictly a measurement and validation system.

---

## Requirements

- **OS:** Windows 10 or Windows 11
- **Shell:** PowerShell 5.1 or later
- **Permissions:** Administrator recommended for full telemetry access
- **Dependencies:** None — all data is gathered through built-in Windows APIs (WMI, powercfg)

---

## Installation

No installation required. Clone the repository and run from any directory:

```powershell
git clone https://github.com/kwisdomk/AEGIS.git
cd AEGIS
```

If PowerShell blocks script execution:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
```

---

## Usage

### Collect a Baseline

```powershell
.\scripts\AGcollect.ps1
```

Captures a full system snapshot and saves it to `results/` as a timestamped JSON file.

**Custom output directory:**

```powershell
.\scripts\AGcollect.ps1 -OutputDir "C:\MyBaselines"
```

**Output filename format:**

```
Baseline_HOSTNAME_YYYYMMDD_HHMMSS.json
```

**Example output:**

```
=== AEGIS BASELINE COLLECTOR ===
Machine : ATHENA
Target  : Q:\LTgit\AEGIS\results\Baseline_ATHENA_20260418_035416.json

[*] Collecting system info...
[*] Collecting memory info...
[*] Collecting storage info...
[*] Collecting power configuration...
[*] Scanning wake locks...
[*] Sampling top processes...

[+] Baseline saved: Q:\LTgit\AEGIS\results\Baseline_ATHENA_20260418_035416.json
```

---

### Analyse a Baseline

```powershell
# Auto-selects the most recent baseline
.\scripts\AGanalyse.ps1

# Or specify a file
.\scripts\AGanalyse.ps1 -JsonPath .\results\Baseline_ATHENA_20260418_035416.json
```

Reads a baseline and applies diagnostic rules. Each finding carries a severity level and an impact score. The total score determines the overall health grade.

**Example output:**

```
=== AEGIS DIAGNOSIS ===
Baseline : Baseline_ATHENA_20260418_035416.json
Captured : 2026-04-18T03:54:16
Machine  : HP Victus by HP Gaming Laptop 15-fa2xxx
CPU      : 13th Gen Intel(R) Core(TM) i5-13420H
GPU      : Intel(R) UHD Graphics / NVIDIA GeForce RTX 3050 6GB Laptop GPU

[WARNING]
  Single-channel memory detected (8 GB, 1 module). Memory bandwidth
  is halved compared to dual-channel configuration. (+50)

[INFO]
  CPU minimum state (AC) at 10% — within configured threshold.
  No active wake locks — sleep/hibernate should function normally.
  SSD: 'SAMSUNG MZVL8512HFLU-00BH1' (476.94 GB) — Healthy.

--- Weighted Summary ---
  CRITICAL : 0
  WARNING  : 1
  INFO     : 4

  Impact Score : 50 points

[!!] NEEDS ATTENTION (50 pts) — Review flagged issues.
```

---

### Compare Two Baselines

```powershell
# Auto-selects the two most recent baselines
.\scripts\AGcompare.ps1

# Or specify both files
.\scripts\AGcompare.ps1 -Before .\results\before.json -After .\results\after.json
```

Compares two system states to identify improvements, regressions, and unchanged values.

**Example output:**

```
=== AEGIS COMPARISON ===
Before : Baseline_ATHENA_20260418_032802.json  (2026-04-18T03:28:02)
After  : Baseline_ATHENA_20260418_035416.json  (2026-04-18T03:54:16)

[Power]
  CPU Min State (AC) : 100% -> 10% [IMPROVED]
  CPU Min State (DC) : 100% -> 5% [IMPROVED]

[Memory]
  Total GB : 8 GB (unchanged)
  Modules : 1 (unchanged)

[Wake Locks]
  Active Locks : 2 -> 0 [IMPROVED]

--- Verdict ---
  Improvements : 3
  Regressions  : 0

[OK] System improved.
```

---

### Full Workflow

```
1. Run AGcollect         → captures current state
2. Run AGanalyse         → identifies problems
3. Apply manual fixes    → power settings, cleanup, hardware changes
4. Run AGcollect again   → captures new state
5. Run AGcompare         → validates improvement
```

```
AGcollect ──→ JSON BASELINE ──→ AGanalyse ──→ WEIGHTED DIAGNOSIS
                   │
                   └──────────→ AGcompare ──→ DELTA REPORT
```

---

## Architecture

AEGIS follows a layered diagnostic pipeline with strict separation between stages:

```
COLLECTION → STORAGE → ANALYSIS → COMPARISON
```

### Collection Layer — AGcollect.ps1

Gathers system telemetry through Windows APIs:

| Data Category | Source | Fields Collected |
|--------------|--------|-----------------|
| System Info | Win32_ComputerSystem, Win32_Processor | Manufacturer, Model, CPU, Cores, GPU |
| Memory | Win32_PhysicalMemory | Total GB, Module count, Dual-channel status |
| Storage | Get-PhysicalDisk (WMI fallback) | Device name, Type (SSD/HDD/External), Size, Health |
| Power | powercfg | Active scheme GUID, CPU min state (AC/DC) |
| Wake Locks | powercfg /requests | Category, Blocker process/driver |
| Processes | Get-Process | Top 10 by CPU time — Name, CPU seconds, Working set MB |

GPU detection prioritizes discrete GPUs over integrated. When multiple GPUs are present, both are recorded.

### Storage Layer

- Immutable JSON snapshots
- Each file is timestamped and machine-specific
- Stored in `results/` (gitignored — machine-specific data is not tracked)

### Analysis Layer — AGanalyse.ps1

- Reads a single baseline
- Applies rule-based diagnostics
- Produces findings categorized by severity (CRITICAL / WARNING / INFO)
- Calculates weighted impact score
- Auto-selects the most recent baseline if no path is given
- Reports baseline age and warns if older than 24 hours

### Comparison Layer — AGcompare.ps1

- Reads two baselines (before/after)
- Computes deltas across all categories
- Classifies each change as IMPROVED, REGRESSED, or unchanged
- Reports overall verdict
- Auto-selects the two most recent baselines if no paths are given
- Reports time gap between snapshots

### Design Constraint

AEGIS does **not**:

- Modify system settings
- Apply automatic fixes
- Run continuously in the background

---

## JSON Baseline Schema

All baselines conform to this structure. Any deviation is a breaking change.

### Root Object

```json
{
  "Timestamp": "2026-04-18T03:54:16",
  "System": {},
  "Memory": {},
  "Storage": [],
  "Power": {},
  "WakeLocks": [],
  "TopProcesses": []
}
```

### System

```json
{
  "Manufacturer": "HP",
  "Model": "Victus by HP Gaming Laptop 15-fa2xxx",
  "CPU": "13th Gen Intel(R) Core(TM) i5-13420H",
  "Cores": 8,
  "LogicalCores": 12,
  "GPU": "Intel(R) UHD Graphics / NVIDIA GeForce RTX 3050 6GB Laptop GPU"
}
```

### Memory

```json
{
  "TotalGB": 8.0,
  "Modules": 1,
  "IsDualChannel": false
}
```

### Power

```json
{
  "ActiveSchemeGUID": "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c",
  "CpuMinStateAC": 10,
  "CpuMinStateDC": 5
}
```

### Storage (array)

```json
[
  {
    "Name": "SAMSUNG MZVL8512HFLU-00BH1",
    "Type": "SSD",
    "SizeGB": 476.94,
    "Health": "Healthy"
  }
]
```

Type values: `SSD`, `HDD`, `External`, `Unknown`

### WakeLocks (array)

```json
[
  {
    "Category": "DISPLAY",
    "Blocker": "[PROCESS] \\Device\\HarddiskVolume3\\Program Files\\app.exe"
  }
]
```

Empty array when no active locks are present.

### TopProcesses (array)

```json
[
  {
    "Name": "brave",
    "CPU": 3918.08,
    "WorkingSetMB": 127.0
  }
]
```

**Note:** The `CPU` field represents cumulative processor time in seconds since the process started, not real-time CPU percentage.

---

## Diagnostic Rules & Scoring

AGanalyse applies a rule engine with weighted severity scoring.

### Health Grades

| Score | Grade | Meaning |
|-------|-------|---------|
| 0–29 | **HEALTHY** | System within acceptable parameters |
| 30–69 | **NEEDS ATTENTION** | Review flagged issues |
| 70+ | **CRITICAL STATE** | Immediate intervention required |

### Rules

#### Power Rules

| Condition | Severity | Weight | Message |
|-----------|----------|--------|---------|
| CPU min state (AC) = 100% | CRITICAL | 40 | Processor cannot idle — constant heat, fan noise, wasted power |
| CPU min state (AC) > 10% | WARNING | 15 | Above threshold, consider lowering |
| CPU min state (AC) ≤ 10% | INFO | 0 | Within threshold |
| CPU min state (DC) = 100% | CRITICAL | 40 | Full speed on battery — severe drain |
| CPU min state (DC) > 10% | WARNING | 15 | Above threshold for battery mode |
| CPU min state (DC) ≤ 10% | INFO | 0 | Within threshold |

#### Memory Rules

| Condition | Severity | Weight | Message |
|-----------|----------|--------|---------|
| 1 RAM module | WARNING | 50 | Single-channel — bandwidth halved |
| 2+ RAM modules | INFO | 0 | Dual-channel active |
| Total RAM < 4 GB | CRITICAL | 60 | Severely constrained |
| Total RAM < 8 GB | WARNING | 20 | May limit multitasking |
| Total RAM ≥ 8 GB | INFO | 0 | Adequate |

#### Wake Lock Rules

| Condition | Severity | Weight | Message |
|-----------|----------|--------|---------|
| Active wake locks | WARNING | 40–60 | Sleep may be prevented (weight scales with count) |
| No wake locks | INFO | 0 | Sleep/hibernate should function normally |

#### Storage Rules

| Condition | Severity | Weight | Message |
|-----------|----------|--------|---------|
| Health ≠ Healthy | CRITICAL | 70 | Potential data loss — back up immediately |
| HDD detected | WARNING | 25 | Significantly slower than SSD |
| External drive | INFO | 0 | Informational |
| Healthy SSD | INFO | 0 | Informational |

#### Process Rules

| Condition | Severity | Weight | Message |
|-----------|----------|--------|---------|
| Working set > 2 GB | WARNING | 20 | Anomalous RAM consumption |

---

## Decision Tree

Mapping common symptoms to diagnostic signals:

### "System feels slow"

- Check CPU minimum state → if > 10%, power misconfiguration
- Check RAM modules → if 1, bandwidth bottleneck
- Check top processes → high CPU at idle indicates background load

### "Battery drains fast"

- Check wake locks → if present, sleep is being prevented
- Check CPU min state (DC) → if high, processor never idles on battery

### "System cannot sleep"

- Check wake locks → active requests indicate driver/software blocking sleep

### "High fan noise / heat"

- Check CPU min state → if locked at 100%, processor runs full speed constantly
- Check top processes → identify unexpected background load

### Data Source Mapping

| Symptom | Baseline Field | Diagnostic Script |
|---------|---------------|-------------------|
| CPU performance / heat | `Power.CpuMinStateAC` | AGanalyse |
| Memory bottleneck | `Memory.Modules` | AGanalyse |
| Sleep issues | `WakeLocks[]` | AGanalyse |
| System load | `TopProcesses[]` | AGanalyse |
| Storage health | `Storage[].Health` | AGanalyse |

---

## Design Principles

1. **Determinism** — Same system state produces the same diagnostic output
2. **Portability** — Runs on any Windows machine without installation
3. **Transparency** — All diagnostics are derived from observable system data
4. **Separation of Concerns** — Collection, analysis, and comparison are independent stages
5. **Non-Invasive** — AEGIS does not modify system state or apply fixes
6. **Reproducibility** — Results can be repeated across machines and time

---

## Known Limitations

### Structural

- **No schema versioning** — The JSON baseline does not carry a version field. If the schema changes in a future release, there is no mechanism to detect version mismatches between old baselines and new scripts.
- **No input validation** — The analyzer trusts the JSON structure blindly. A corrupted or partial baseline will produce misleading output rather than a clear error.
- **Hardcoded rules** — All diagnostic logic lives inside the scripts. Adding new rules requires editing the core analysis script directly. There is no plugin or external rule definition system.
- **Console-only output** — Analysis and comparison results are printed to the terminal. There is no file export option for automation or archival.

### Data Accuracy

- **Dual-channel detection is approximate** — The system infers dual-channel from module count (2+ modules = dual-channel). This is not always accurate — modules could be in the wrong slots or mismatched. This is a Windows API limitation.
- **SATA SSD misclassification** — When Windows reports `MediaType` as unspecified and `BusType` as SATA, the collector defaults to HDD. SATA-connected SSDs may be misclassified on some systems.
- **powercfg text parsing** — Wake lock detection relies on regex parsing of `powercfg /requests` output. If Microsoft changes the output format in a future Windows update, this detection will fail silently.
- **CPU field semantics** — The `CPU` field in `TopProcesses` represents cumulative processor time in seconds since process start, not real-time percentage. The field name is ambiguous when reading raw JSON.

### Inherent By Design

- **Point-in-time snapshots only** — AEGIS captures the system state at the moment of collection. It cannot detect intermittent issues (e.g., CPU spikes that occur at specific times). It is not a monitoring tool.
- **Windows-only** — The framework depends on WMI, CIM, and powercfg. It will not run on Linux, macOS, or legacy Windows versions without modern PowerShell.
- **No automatic remediation** — AEGIS identifies problems but does not fix them. The user must apply fixes manually between collection cycles.
- **Administrator recommended** — Running without Administrator privileges produces partial baselines (missing power data, limited storage health). There is no clear indication of what data is missing in non-admin mode.

---

## Future Improvements

### High Priority

- [ ] Add Windows version and build number to baseline
- [ ] Add storage free space and capacity usage
- [ ] Add schema version field to JSON baseline format
- [ ] Add input validation before analysis (reject malformed baselines)
- [ ] Add file export option for analysis and comparison results

### Medium Priority

- [ ] Network adapter telemetry
- [ ] Thermal and temperature data collection
- [ ] Vendor-specific service identification (Dell, Lenovo, Asus bloatware detection)
- [ ] AGcompare: run health grade on both baselines and compare grades
- [ ] Externalize diagnostic rules from script into loadable rule definitions

### Low Priority

- [ ] Multi-machine baseline tracking
- [ ] Historical baseline indexing and metadata registry
- [ ] CLI wrapper (`aegis collect`, `aegis analyze`, `aegis compare`)
- [ ] Trend detection across multiple baselines (performance drift over time)
- [ ] BIOS and firmware version collection

### Long-Term

- [ ] Confidence scoring for diagnostic findings
- [ ] Anomaly detection across baseline history
- [ ] Optional dashboard visualization

---

## Troubleshooting

### Script does not run

**Cause:** PowerShell execution policy restrictions.

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
```

### Missing or incomplete JSON output

**Cause:** Insufficient permissions.

**Fix:** Run PowerShell as Administrator.

### Power values show -1 or "Unknown"

**Cause:** powercfg query failed.

**Fix:** Ensure the Windows Power service is running. Some virtual machines and cloud instances do not expose power management.

### No wake lock data

**Cause:** No active sleep blockers.

**Note:** This is normal — it means nothing is preventing sleep.

### Analysis script fails to parse baseline

**Cause:** Corrupted or manually edited JSON file.

**Fix:** Delete the corrupted file and run AGcollect again.

### Comparison shows no changes

**Cause:** Both baselines captured the same system state, or wrong files were selected.

**Fix:** Verify file timestamps correspond to the expected before/after window. Ensure a system change was made between collections.

### LF/CRLF warnings on git operations

**Cause:** Normal on Windows. Git's `autocrlf` setting handles line ending conversion automatically.

**Fix:** No action needed.

---

## Changelog

### v1.0.0 — 2026-04-18

Initial public release.

- Baseline collection engine (CPU, GPU, RAM, storage, power, wake locks, processes)
- Rule-based diagnostic analyzer with weighted severity scoring
- Before/after baseline comparison with delta reporting
- Auto-selection of latest baseline for analysis and comparison
- Baseline age detection and staleness warnings
- Full documentation suite
- Portable execution — no installation required

---

## Project Structure

```
AEGIS/
├── scripts/
│   ├── AGcollect.ps1          # System telemetry collector
│   ├── AGanalyse.ps1          # Weighted rule-based diagnostics
│   └── AGcompare.ps1          # Before/after comparison
├── docs/
│   ├── DOCUMENTATION.md       # This file
│   ├── 00_project_overview.md
│   ├── 01_architecture.md
│   ├── 02_decision_tree.md
│   ├── 03_workflow_lifecycle.md
│   ├── 04_design_principles.md
│   ├── 05_history_origin.md
│   ├── 06_troubleshooting.md
│   ├── 07_future_roadmap.md
│   ├── 08_schema.md
│   └── 09_glossary.md
├── results/                   # Baseline outputs (gitignored)
├── CHANGELOG.md
├── .gitignore
├── LICENSE
└── README.md
```

---

## License

MIT — see [LICENSE](../LICENSE)

---

AEGIS v1.0 — Last updated: 2026-04-18
