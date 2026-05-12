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

---

## Buying Laptops in Nairobi

> **Who this section is for:** Kenyan users — especially those buying gaming or refurbished laptops in Nairobi CBD. AEGIS automatically surfaces relevant advice when it detects issues common to the local market (single-channel RAM, Ex-UK bloat, KMS-activated Windows).

This guide is drawn from the *Nairobi Laptop Sellers Verified Dataset (March 2026)*, aggregating 50+ shops from r/Kenya, r/nairobitechies, and local tech blogs.

---

### Tier 1 — Trusted (Brand-New, Warranted)

The safest sources. Generally the most expensive, but you get a factory seal and a valid manufacturer warranty.

| Shop | Location | Speciality |
|------|----------|------------|
| **Text Book Centre (TBC)** | Sarit Centre, Village Market, CBD | All-round — safest for brand-new |
| **Saruk Digital** | Kimathi House, CBD | Premium business (ThinkPad, XPS) & gaming |
| **Bright Technologies** | Kimathi Street, CBD | Asus specialist, gaming laptops since 2016 |
| **Devices Technology Store** | Nairobi / Online | Large inventory of Dell, Lenovo, HP |
| **Buytec / Shopit** | CBD / Online | Corporate & consumer, massive catalog |
| **Dove Computers** | Revlon Plaza, CBD | Solid warranties, corporate sourcing |

---

### Tier 2 — Trusted (Gaming-Focused)

Specialists that stock RTX-equipped machines and high-refresh-rate panels.

| Shop | Location | Speciality |
|------|----------|------------|
| **Albelian Technology** | Nairobi | Lenovo Legion, RTX 4060+ |
| **Roadmap Tech Computers** | Nairobi | HP Omen 14/16, RTX 4070, Intel Ultra 9 |
| **Acetech IT** | Rahimtulla Trust Bldg, Moi Ave | Mid-range Victus, LOQ, RTX 3050 |
| **Zentech Electronics** | Bazaar Plaza, CBD | Victus, Nitro — verified original software |
| **ECB Technologies** | Online / X (Twitter) | Highly trusted delivery; clean machines |

---

### Tier 3 — Mid-Tier / Ex-UK (Requires Buyer Knowledge)

These shops offer great deals on refurbished ("Ex-UK") laptops, but **you must inspect in person**:
- Check RAM module count (single vs. dual-channel).
- Check battery health (run `powercfg /batteryreport` in PowerShell).
- Verify storage type (SSD or HDD) before paying.
- Ask for the Windows activation status (Settings → Activation).

Notable shops: **Bestsella** (Yala Towers), **Yellow Apple Technologies** (HH Towers), **Mombasa Computers** (Moi Ave), **OneTech** (Old Nation), **ECB Technologies** (online), **Laptop Clinic** (multiple).

---

### High-Risk / Confirmed Scams — Avoid

> [!CAUTION]
> These entities have been flagged repeatedly on r/Kenya and r/nairobitechies. Do not pay upfront, do not engage remotely.

- **Rikel Technologies** — multiple Reddit reports of hard-core scams.
- **"Mr Bingo Laptops"** — dead laptops sold; seller changes location and blocks numbers.
- **Jiji / Instagram "ghost shops"** — bait-and-switch, pay-delivery-fee-first schemes.
- **Facebook "Customs Clearance Sale" ads** — ask for KES 500–1,000 "delivery fee", then disappear.

**Rule of thumb:** Never pay before physically inspecting the machine. A legitimate seller in Nairobi will always let you walk in.

---

### What AEGIS Flags for Kenyan Users

When AEGIS detects the following conditions, it will automatically add Kenya-specific remediation advice:

| AEGIS Finding | Kenya Context |
|---------------|---------------|
| **Single-channel RAM** | Extremely common on Victus / LOQ / IdeaPad Gaming 3 sold in CBD shops. OEMs ship with one stick to cut costs — sellers rarely disclose this. |
| **HDD detected** | Most Ex-UK refurb machines arrive with original HDDs. An SSD swap is the single biggest performance upgrade. |
| **Suspicious processes** | Ex-UK corporate machines often have MDM agents (Computrace/Absolute, SCCM, MaaS360) that were never properly wiped. These can give a prior owner remote access. |
| **KMS activator signals** | Pirated Windows is common on budget CBD stalls (Luthuli Ave / River Road). Carries spyware risk and blocked updates. |

---

### The Reddit Pro-Tip: Import Instead

> Many Nairobi tech professionals skip local shops entirely for high-end gaming laptops due to significant local markups (often 20–35% above US pricing on RTX 4060+ machines).
>
> **Alternative:** Buy from **Amazon** or **Newegg** (USA) and ship via a freight forwarder:
> - **Kentex Cargo** — popular in r/Kenya
> - **Savostore**
> - **APS Logistix**
>
> Average cost: ~**$15/kg**. A typical 2 kg gaming laptop ships for ~$30, saving KES 15,000–30,000 on premium models.
