# AEGIS Troubleshooting Guide

## Script does not run

**Cause:** Execution policy restrictions

**Fix:**

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
```

---

## Missing JSON output

**Cause:** WMI / powercfg failure

**Fix:** Run PowerShell as Administrator

---

## Power values show "Unknown"

**Cause:** powercfg parsing failure

**Fix:** Ensure Windows power service is active

---

## No wake lock data

**Cause:** No active blockers OR command returned empty

**Note:** This may be normal — it means nothing is blocking sleep.

---

## Analysis script fails

**Cause:** Missing or corrupted baseline JSON

**Fix:** Re-run collection script

---

## Comparison shows no deltas

**Cause:** Both baselines are identical, or wrong files were selected

**Fix:** Verify the file timestamps match the expected before/after window

---

AEGIS v1.0 — Last updated: 2026-04-18
