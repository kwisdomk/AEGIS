# AEGIS Workflow Lifecycle

## Step 1 — Baseline Collection

Run:

```powershell
.\scripts\AGcollect.ps1
```

Output:

- JSON snapshot of system state saved to `results/`

---

## Step 2 — Analysis

Run:

```powershell
.\scripts\AGanalyse.ps1 -JsonPath .\results\Baseline_HOSTNAME_20260418_143200.json
```

Output:

- System diagnosis
- Severity classification (CRITICAL / WARNING / INFO)

---

## Step 3 — Manual Intervention

User applies fixes:

- Power configuration changes
- Driver adjustments
- Process cleanup
- Hardware upgrades

---

## Step 4 — Re-Collection

Run baseline again:

```powershell
.\scripts\AGcollect.ps1
```

---

## Step 5 — Comparison

Run:

```powershell
.\scripts\AGcompare.ps1 -Before .\results\before.json -After .\results\after.json
```

Output:

- Before vs After deltas
- Improvement validation

---

## Example Full CLI Session

### Step 1 — Collect baseline

```powershell
PS C:\AEGIS> .\scripts\AGcollect.ps1
=== AEGIS BASELINE COLLECTOR ===
Machine: ACER-ESPIR
Saving to: results\Baseline_ACER-ESPIR_20260418_143200.json
[+] Baseline saved successfully
```

### Step 2 — Analyze system

```powershell
PS C:\AEGIS> .\scripts\AGanalyse.ps1 -JsonPath .\results\Baseline_ACER-ESPIR_20260418_143200.json
=== AEGIS DIAGNOSIS ===
[CRITICAL]
  CPU minimum state (AC) locked at 100% (+40)
[WARNING]
  Single-channel memory detected (+50)
[INFO]
  SSD healthy

Impact Score : 90 points
[!!!] CRITICAL STATE (90 pts)
```

### Step 3 — Compare (after fix)

```powershell
PS C:\AEGIS> .\scripts\AGcompare.ps1 -Before before.json -After after.json
  CPU Min State (AC) : 100% -> 5% [IMPROVED]
  Active Locks : 2 -> 0 [IMPROVED]
  Total GB : 8 GB (unchanged)

  Improvements : 2
  Regressions  : 0
[OK] System improved.
```

---

AEGIS v1.0 — Last updated: 2026-04-18
