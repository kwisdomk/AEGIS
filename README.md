# AEGIS

**Automated Environment Gathering & Inspection System — The Gaming Laptop Shield**

Welcome to AEGIS! AEGIS is a portable Windows diagnostic framework that converts any machine into a measurable, analyzable environment — and guides you through fixing what it finds. No installation required.

---

## Why AEGIS? (For Gaming Laptops)

Modern gaming laptops often suffer from "silent killers"—hidden issues that severely throttle performance without ever triggering an error message or blue screen. AEGIS is specifically designed to hunt down these problems:

- **Single-Channel Memory Bottlenecks:** Up to a 30% loss in FPS because of OEM cost-cutting.
- **Sleep-Killing Wake Locks:** Applications keeping the system awake, draining battery and generating heat in your backpack.
- **Aggressive Power States:** The CPU artificially limiting its own wattage.
- **OEM Bloatware:** Heavy background services consuming valuable CPU cycles.

AEGIS gives you the tools to spot these problems instantly, fix them, and prove that the fix actually worked.

---

## Quick Start

```powershell
# -- Interactive Launcher (Recommended) --
.\AEGIS.ps1

# -- Manual Steps --
# 1. Collect a baseline
.\scripts\AGcollect.ps1

# 2. Analyze (auto-selects latest baseline)
#    Diagnosis + ranked action plan printed at the end
.\scripts\AGanalyse.ps1
```

> **Note:** Run PowerShell as Administrator for full telemetry access. If scripts are blocked, run:
> `Set-ExecutionPolicy Bypass -Scope Process -Force`

---

## How to Close the Loop (The Workflow)

AEGIS is built around a continuous improvement cycle:

1. **Take a Snapshot:** Run `AGcollect.ps1` to grab a system baseline.
2. **Review the Action Plan:** Run `AGanalyse.ps1` (or use the launcher). AEGIS will grade your system and give you a ranked list of fixes.
3. **Apply Fixes:** Follow the step-by-step remedies provided in the Action Plan.
4. **Re-Collect:** Run `AGcollect.ps1` again to capture the new system state.
5. **Verify:** Run `AGcompare.ps1` to compare the old and new baselines. AEGIS will confirm the issues are resolved and show your improved score.

---

## Interpreting Results

AEGIS uses a point-based scoring system to prioritize findings based on their impact:

| Score | Grade | Meaning |
|-------|-------|---------| 
| 0–29 | **HEALTHY** | System within acceptable parameters |
| 30–69 | **NEEDS ATTENTION** | Review flagged issues |
| 70+ | **CRITICAL STATE** | Immediate intervention required |

Your goal is to drop your score down into the "HEALTHY" range by addressing the high-impact items in your Action Plan.

---

## Common Gaming Laptop Issues AEGIS Detects

- **Single-channel RAM:** Reduces memory bandwidth by 50%.
- **Active Wake Locks:** Apps preventing deep sleep, causing overheating.
- **CPU Power States:** Min/Max states capped incorrectly, crippling performance.
- **Storage Bottlenecks:** Over-filled or failing SSDs affecting load times.
- **Memory Constraints:** Low RAM causing excessive paging.

---

## Project Structure

```
AEGIS/
├── AEGIS.ps1                  # Interactive launcher
├── scripts/
│   ├── AGcollect.ps1          # System telemetry collector
│   ├── AGanalyse.ps1          # Weighted rule-based diagnostics + action plan
│   ├── AGremediate.ps1        # Standalone remediation advisor
│   └── AGcompare.ps1          # Before/after comparison
├── docs/
│   ├── 00_project_overview.md
│   ├── USAGE.md               # Detailed user instructions
│   └── ...                    # Other docs
├── results/                   # Baseline outputs (gitignored)
└── README.md
```

---

## Target Systems

- Windows 10 / 11
- Any hardware class (low-end to workstation)
- Works offline

---

## License

MIT — see [LICENSE](LICENSE)

---

AEGIS v1.1
