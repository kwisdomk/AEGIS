# AEGIS Decision Tree

## Purpose

This document maps system symptoms to diagnostic signals.

---

## 1. System Feels Slow

**Check:**

- CPU minimum state
- Background processes
- RAM configuration

**Interpretation:**

- CPU min state > 10% → power misconfiguration
- Single RAM module → bandwidth bottleneck
- High CPU process at idle → background load issue

---

## 2. Battery Drains Fast

**Check:**

- Wake locks
- CPU idle behavior
- Background services

**Interpretation:**

- Wake locks present → sleep prevention
- CPU never idles → power configuration issue

---

## 3. System Cannot Sleep

**Check:**

- `powercfg /requests` output

**Interpretation:**

- Active requests → driver/software blocking sleep

---

## 4. High Fan / Heat

**Check:**

- CPU usage
- Power state
- Background processes

**Interpretation:**

- High idle CPU → misconfiguration or hidden load

---

## Data Source Mapping

Each diagnostic signal originates from a specific field in the baseline:

| Symptom | Source Field | Script |
|---------|-------------|--------|
| CPU slow / heat | `Power.CpuMinStateAC` | AGcollect.ps1 |
| Memory bottleneck | `Memory.Modules` | AGcollect.ps1 |
| Sleep issues | `WakeLocks[]` | AGcollect.ps1 |
| System load | `TopProcesses[]` | AGcollect.ps1 |
| Storage health | `Storage[].Health` | AGcollect.ps1 |

---

AEGIS v1.0 — Last updated: 2026-04-18
