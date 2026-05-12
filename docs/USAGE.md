# AEGIS Usage Guide

This guide is designed for technical users, power users, and repair technicians looking to diagnose and optimize Windows machines (especially gaming laptops) using AEGIS.

---

## How to Run AEGIS Daily

The easiest way to interact with AEGIS is through the interactive launcher. 

1. Open PowerShell as Administrator (required for full telemetry gathering).
2. Navigate to your AEGIS folder:
   ```powershell
   cd C:\path\to\AEGIS
   ```
3. Run the launcher:
   ```powershell
   .\AEGIS.ps1
   ```

### The Standard Workflow

For a standard daily checkup on a client's or your own machine:
1. Select **Option 1 (Take a fresh snapshot)** to build a baseline.
2. Select **Option 5 (Full check)** to review the health grade and immediately see the generated Action Plan.

---

## Understanding the Action Plan

AEGIS doesn't just tell you what's broken; it tells you how to fix it, ranked by severity.

### Point System
Every finding subtracts points from your system health. 
- **0–29 points:** HEALTHY
- **30–69 points:** NEEDS ATTENTION
- **70+ points:** CRITICAL STATE

The Action Plan sorts the most critical issues at the top. For example, a **Single-channel memory** warning carries a massive -50 point penalty, making it a high-priority hardware fix. A **Wake lock** issue is -45 points, making it a critical software fix.

---

## How to Use Compare

Once you have applied a fix from the Action Plan (e.g., adding a second stick of RAM, or uninstalling bloatware):

1. Close the loop by capturing a *new* snapshot: **Option 1**.
2. Run a comparison: **Option 4 (Compare before and after a fix)**.

AEGIS will automatically detect your two most recent baselines, compare them, and highlight exactly what changed. It will also show you the point reduction, validating your work.

---

## Examples of Real Fixes

### Scenario A: The Sluggish Gaming Laptop
**Symptom:** Stuttering in games despite decent specs.
**AEGIS Finding:** `Single-channel memory detected (8 GB, 1 module) (+50)`
**Action:** Installed a second 8GB DDR4 stick.
**Result:** Re-ran AEGIS. Score dropped by 50 points. Memory bandwidth effectively doubled, eliminating CPU bottlenecks in games.

### Scenario B: The Overheating Backpack
**Symptom:** Laptop is hot to the touch when pulled from a bag; battery is dead.
**AEGIS Finding:** `Active wake locks detected (1). System sleep may be prevented (+45)` (Originating from a background game launcher).
**Action:** Disabled the launcher from startup using Task Manager.
**Result:** Re-ran AEGIS. Score dropped by 45 points. System now correctly enters S3/Modern Standby sleep.

---

## Troubleshooting Common Issues

### "Execution of scripts is disabled on this system."
PowerShell prevents running unsigned scripts by default. Run this command to temporarily bypass it for your current session:
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
```

### "No baseline found" when running analysis
You must collect a baseline first before analyzing it. Use **Option 1** in the launcher, or run `.\scripts\AGcollect.ps1`.

### "Access Denied" or Missing Telemetry
AEGIS needs elevated privileges to read certain system states (like wake locks and low-level disk health). Always run your PowerShell window as Administrator.
