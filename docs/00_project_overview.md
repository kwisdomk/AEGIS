# AEGIS — Project Overview

## What is AEGIS?

**AEGIS** (Automated Environment Gathering & Inspection System) is a portable Windows diagnostic framework designed to convert any machine from an opaque system ("black box") into a measurable and analyzable environment.

It does this by collecting structured system telemetry, analyzing it through rule-based logic, and providing a ranked Action Plan to guide the user in fixing identified issues. Finally, it enables before/after comparison to validate the improvements.

---

## Core Purpose

AEGIS exists to answer four questions:

1. **What is the current system state?**
2. **What is wrong or inefficient?**
3. **How do I fix it?**
4. **Did my changes improve the system?**

---

## Why AEGIS Exists

Most system diagnostics tools:

- Show raw data without interpretation
- Require installation or heavy dependencies
- Do not provide actionable remediation steps
- Do not allow comparison over time
- Do not validate improvement

AEGIS was designed to solve this gap, especially for Gaming Laptops where hidden bottlenecks (like Single-Channel RAM or Wake Locks) cripple performance silently. It introduces:

- Structured baselines
- Deterministic analysis
- Ranked Remediation Action Plans
- Change validation through comparison

---

## Key Capabilities

- System baseline generation (CPU, RAM, storage, power, processes)
- Wake lock and power state analysis
- Rule-based diagnostics with Severity Weighting
- Remediation guidance for common gaming laptop issues
- Before/after system comparison
- Portable execution via an interactive launcher (`AEGIS.ps1`)

---

## Target Systems

- Windows 10 / 11
- Any hardware class (low-end to workstation)
- Offline environments

---

AEGIS v1.1 — Last updated: 2026-05-12
