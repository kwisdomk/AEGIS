# AEGIS JSON Schema v1

## Purpose

Defines the strict structure of all baseline outputs.

---

## Root Object

```json
{
  "Timestamp": "string (ISO 8601)",
  "System": {},
  "Memory": {},
  "Storage": [],
  "Power": {},
  "WakeLocks": [],
  "TopProcesses": []
}
```

---

## System Object

```json
{
  "Manufacturer": "string",
  "Model": "string",
  "CPU": "string",
  "Cores": "number",
  "LogicalCores": "number",
  "GPU": "string"
}
```

---

## Memory Object

```json
{
  "TotalGB": "number",
  "Modules": "number",
  "IsDualChannel": "boolean"
}
```

---

## Power Object

```json
{
  "ActiveSchemeGUID": "string",
  "CpuMinStateAC": "number",
  "CpuMinStateDC": "number"
}
```

---

## Storage Array

```json
[
  {
    "Name": "string",
    "Type": "HDD | SSD",
    "SizeGB": "number",
    "Health": "string"
  }
]
```

---

## WakeLocks Array

```json
[
  {
    "Category": "string",
    "Blocker": "string"
  }
]
```

---

## TopProcesses Array

```json
[
  {
    "Name": "string",
    "CPU": "number",
    "WorkingSetMB": "number"
  }
]
```

---

## Rule

All scripts **MUST** conform to this schema.

Any deviation is considered a **breaking change**.

---

AEGIS v1.0 — Last updated: 2026-04-18
