# Changelog

## v1.2.0 — 2026-05-12

Bug fixes and polish.

- Fixed `The property 'Count' cannot be found on this object` crash when baseline fields (`WakeLocks`, `Storage`, `TopProcesses`) are `$null` under `Set-StrictMode`. All `.Count` accesses in `AGrules.ps1` and `AGkenya.ps1` now use `@(...)` array cast for null safety.
- Added `if ($null -eq $baseline) { return }` null guard at the top of `Invoke-AEGISKenyaAnalysis` in `AGkenya.ps1`.
- Fixed `AEGIS.ps1` menu printing multiple times: all child script invocations are now wrapped in `try/catch` so a downstream terminating error no longer propagates unhandled into the `do/while` loop.
- Removed duplicate greeting (`Hello, I am AEGIS. Whachu wanna do...`) from `AGanalyse.ps1` and `AGremediate.ps1`. The greeting now appears exactly once — at launcher startup in `AEGIS.ps1`.

---

## v1.1.0 — 2026-05-12

Phase 2: Close the Gap (Remediation)
- Added `AEGIS.ps1` interactive launcher to the project root for simplified execution.
- Added minimal greeting to root launcher and analysis scripts.
- Extracted shared rule engine into `AGrules.ps1` to eliminate duplication between analysis and remediation.
- Polished `=== ACTION PLAN ===` formatting for better readability, clear problem titles, and improved spacing.
- Updated `AGanalyse.ps1` with a new `=== ACTION PLAN ===` section, ranking findings by impact.
- Added `Remedy` support to the `Add-Finding` function.
- Created `AGremediate.ps1` as a standalone script to print only the ranked action plan.
- Added remediation guidance for Wake Locks, Single-channel RAM, CPU Power States, Storage health, and Memory constraints.
- Updated documentation with remediation pipeline steps.

## v1.0.0 — 2026-04-18

Initial release.

- Baseline collection engine (CPU, GPU, RAM, storage, power, wake locks, processes)
- Rule-based diagnostic analyzer with weighted severity scoring
- Before/after baseline comparison with delta reporting
- Auto-selection of latest baseline for analysis and comparison
- Baseline age detection and staleness warnings
- Full documentation suite (architecture, schema, workflow, troubleshooting)
- Portable execution — no installation required
- Tested on Windows 10/11
