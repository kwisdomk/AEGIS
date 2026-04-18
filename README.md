# AEGIS

**Automated Environment Gathering & Inspection System**

A portable Windows diagnostic framework that converts any machine into a measurable, analyzable environment. No installation required.

---

## Quick Start

```powershell
# 1. Collect a baseline
.\scripts\AGcollect.ps1

# 2. Analyze (auto-selects latest baseline)
.\scripts\AGanalyse.ps1

# 3. Or analyze a specific baseline
.\scripts\AGanalyse.ps1 -JsonPath .\results\Baseline_YOURPC_20260418_120000.json

# 4. Make changes, collect again, then compare
.\scripts\AGcompare.ps1 -Before .\results\before.json -After .\results\after.json
```

> **Note:** Run PowerShell as Administrator for full telemetry access. If scripts are blocked, run:
> `Set-ExecutionPolicy Bypass -Scope Process -Force`

---

## What It Does

| Step | Command | Output |
|------|---------|--------|
| **Collect** | `AGcollect` | JSON snapshot of CPU, GPU, RAM, storage, power, wake locks, processes |
| **Analyse** | `AGanalyse` | Weighted diagnostic findings with impact score and health grade |
| **Compare** | `AGcompare` | Before/after delta report with improvement validation |

### Severity Weighting

AGanalyse uses a point-based scoring system to prioritize findings:

| Score | Grade | Meaning |
|-------|-------|---------|
| 0–29 | **HEALTHY** | System within acceptable parameters |
| 30–69 | **NEEDS ATTENTION** | Review flagged issues |
| 70+ | **CRITICAL STATE** | Immediate intervention required |

---

## Pipeline

```
AGcollect ──→ JSON BASELINE ──→ AGanalyse ──→ WEIGHTED DIAGNOSIS
                   │
                   └──────────→ AGcompare ──→ DELTA REPORT
```

---

## Project Structure

```
AEGIS/
├── scripts/
│   ├── AGcollect.ps1          # System telemetry collector
│   ├── AGanalyse.ps1          # Weighted rule-based diagnostics
│   └── AGcompare.ps1          # Before/after comparison
├── docs/
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
├── .gitignore
├── LICENSE
└── README.md
```

---

## Design Principles

- **Deterministic** — Same state produces the same output
- **Portable** — No installation, runs on any Windows machine
- **Non-Invasive** — Never modifies system state
- **Transparent** — All diagnostics from observable data
- **Reproducible** — Repeatable across machines and time

---

## Target Systems

- Windows 10 / 11
- Any hardware class (low-end to workstation)
- Works offline

---

## License

MIT — see [LICENSE](LICENSE)

---

AEGIS v1.0
