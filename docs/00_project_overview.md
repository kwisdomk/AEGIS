# AEGIS — Project Overview

## What is AEGIS?

**AEGIS** (Automated Environment Gathering & Inspection System) is a portable Windows diagnostic framework designed to convert any machine from an opaque system ("black box") into a measurable and analyzable environment.

It does this by collecting structured system telemetry, analyzing it through rule-based logic, and enabling before/after comparison of system states.

---

## Core Purpose

AEGIS exists to answer three questions:

1. **What is the current system state?**
2. **What is wrong or inefficient?**
3. **Did my changes improve the system?**

---

## Why AEGIS Exists

Most system diagnostics tools:

- Show raw data without interpretation
- Require installation or heavy dependencies
- Do not allow comparison over time
- Do not validate improvement

AEGIS was designed to solve this gap by introducing:

- Structured baselines
- Deterministic analysis
- Change validation through comparison

---

## Key Capabilities

- System baseline generation (CPU, RAM, storage, power, processes)
- Wake lock and power state analysis
- Rule-based diagnostics
- Before/after system comparison
- Portable execution (no installation required)

---

## Target Systems

- Windows 10
- Windows 11
- Any hardware class (low-end to workstation)
- Offline environments

---

AEGIS v1.0 — Last updated: 2026-04-18
