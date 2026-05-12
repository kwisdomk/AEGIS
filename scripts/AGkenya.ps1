<#
.SYNOPSIS
    AGkenya - Kenya-Specific Rules Module for AEGIS

.DESCRIPTION
    Optional module containing rules and remediation advice tailored for users
    in the Kenyan market, particularly those buying gaming or refurbished (Ex-UK)
    laptops in Nairobi.

    This module is dot-sourced from AGrules.ps1 and hooks into the same
    Add-Finding mechanism. It is purely ADDITIVE -- users outside Kenya are not
    affected in any way.

.NOTES
    Data sourced from the "Nairobi Laptop Sellers Verified Mar 2026" dataset,
    aggregated from r/Kenya, r/nairobitechies, local tech blogs, and corporate
    websites.

    Market snapshot: 50+ shops verified as of March 2026.
    Top trusted (brand new): Text Book Centre, Saruk Digital, Bright Technologies,
      Devices Technology Store, Buytec/Shopit, Dove Computers.
    Top trusted (gaming-focused): Albelian Technology, Roadmap Tech, Acetech IT,
      Zentech Electronics.
    Highly trusted online/delivery: ECB Technologies (via X/Twitter).
    High-risk / confirmed scams: Rikel Technologies, "Mr Bingo Laptops",
      Jiji/Instagram ghost shops, Facebook "customs clearance" ads.
#>

# ---------------------------------------------------------------------------
# TRUSTED SELLER REFERENCE STRINGS
# (Compact summaries -- intentionally not an exhaustive list)
# ---------------------------------------------------------------------------

$script:KE_TrustedNew = @(
    "  - Text Book Centre (textbookcentre.com) :: Sarit/Village Market/CBD :: safest for brand-new",
    "  - Saruk Digital (saruk.co.ke)           :: Kimathi House, CBD       :: premium business/gaming",
    "  - Bright Technologies (bright.co.ke)    :: Kimathi Street, CBD      :: Asus/gaming specialist",
    "  - Devices Technology (devicestech.co.ke):: Nairobi/Online           :: large genuine inventory",
    "  - Buytec/Shopit (shopit.co.ke)          :: CBD/Online               :: reliable corporate vendor",
    "  - Dove Computers (dovecomputers.co.ke)  :: Revlon Plaza, CBD        :: solid warranties"
)

$script:KE_TrustedGaming = @(
    "  - Albelian Technology (albeliantech.co.ke) :: premium Legion/RTX 4060+",
    "  - Roadmap Tech (roadmaptech.co.ke)         :: HP Omen/RTX 4070, latest Intel Ultra",
    "  - Acetech IT (acetechit.co.ke)             :: mid-range Victus/RTX 3050, clear specs",
    "  - Zentech Electronics (Bazaar Plaza, CBD)  :: Victus/Nitro, verified original software",
    "  - ECB Technologies (ecbtechnologies.co.ke) :: online/delivery via X, highly trusted"
)

$script:KE_HighRisk = @(
    "  - Rikel Technologies            :: multiple Reddit users report hard-core scams",
    '  - "Mr Bingo Laptops"            :: dead laptops sold; seller changes location and blocks numbers',
    "  - Jiji/Instagram ghost shops    :: bait-and-switch, pay-delivery-fee-first schemes",
    '  - Facebook "Customs Sale" ads   :: ask for KES 500-1000 delivery fee, then disappear'
)

# ---------------------------------------------------------------------------
# PUBLIC FUNCTION: Invoke-AEGISKenyaAnalysis
# Called by AGrules.ps1 after its own Add-Finding closure is established.
# ---------------------------------------------------------------------------

function Invoke-AEGISKenyaAnalysis {
    <#
    .SYNOPSIS
        Adds Kenya-specific findings to the AEGIS analysis pipeline.

    .PARAMETER baseline
        The same baseline object passed to Invoke-AEGISAnalysis.

    .PARAMETER AddFinding
        A scriptblock reference to the inner Add-Finding function defined
        inside Invoke-AEGISAnalysis.  Pass it via the proxy: { Add-Finding @args }.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [object]$baseline,

        [Parameter(Mandatory=$true)]
        [scriptblock]$AddFinding
    )

    if ($null -eq $baseline) { return }

    $trustedNewList    = ($script:KE_TrustedNew    | ForEach-Object { $_ }) -join "`n"
    $trustedGamingList = ($script:KE_TrustedGaming  | ForEach-Object { $_ }) -join "`n"
    $highRiskList      = ($script:KE_HighRisk        | ForEach-Object { $_ }) -join "`n"

    # -----------------------------------------------------------------------
    # KE-RAM-01 : Single-Channel RAM -- Kenya context
    # Supplements the base single-channel finding with Nairobi-specific advice.
    # Weight = 0 (base rule already applied the penalty; this is advisory text).
    # -----------------------------------------------------------------------
    if ($null -ne $baseline.Memory.Modules -and $baseline.Memory.Modules -eq 1) {
        $totalGB = $baseline.Memory.TotalGB
        $remedy = @(
            "KENYA CONTEXT: Single-channel RAM is EXTREMELY common in budget gaming",
            "laptops (HP Victus 15, Lenovo IdeaPad Gaming 3, LOQ) sold in Nairobi CBD",
            "shops. OEMs ship with one stick to cut costs; sellers rarely disclose this.",
            "",
            "What to do:",
            "  1. Confirm the slot is open: use CPU-Z (free) SPD tab.",
            "  2. Buy a matching DDR4/DDR5 stick (same speed, capacity, CAS latency).",
            "     A 2nd 8 GB stick typically costs KES 2,500-4,500 locally.",
            "  3. For gaming laptops, dual-channel can improve in-game FPS by 15-30%",
            "     especially on integrated/shared-GPU workloads.",
            "",
            "Where to buy RAM in Nairobi (verified sellers for new/compatible sticks):",
            $trustedNewList,
            "",
            "Pro-Tip: If you bought from a CBD stall and the spec sheet said '8 GB Dual',",
            "but AEGIS shows 1 module -- the listing was misleading. This is common",
            "practice in Moi Avenue/River Road shops. Keep your receipt."
        ) -join "`n"
        & $AddFinding "WARNING" 0 "[KE] Single-channel RAM in a Nairobi gaming laptop: very common cost-cut. See remedy for local upgrade options." $remedy
    }

    # -----------------------------------------------------------------------
    # KE-STORAGE-01 : HDD detected -- Kenya Ex-UK context
    # -----------------------------------------------------------------------
    $hasHDD = $false
    if ($null -ne $baseline.Storage -and @($baseline.Storage).Count -gt 0) {
        $hasHDD = (@($baseline.Storage | Where-Object { $_.Type -eq "HDD" }).Count -gt 0)
    }
    if ($hasHDD) {
        $remedy = @(
            "KENYA CONTEXT: Many Ex-UK (refurbished) laptops imported from the UK/EU",
            "arrive with their original HDDs intact. Sellers rarely upgrade them before",
            "resale. An SSD swap is the single highest-impact upgrade for a refurb unit.",
            "",
            "Recommended action:",
            "  1. Get a SATA or NVMe SSD (check your slot type via HWiNFO64, free).",
            "     Prices in Nairobi: KES 3,500 (256 GB SATA) to KES 8,000 (512 GB NVMe).",
            "  2. Clone with Macrium Reflect Free or perform a fresh Windows install.",
            "  3. Verified local sellers with SSD stock:",
            $trustedNewList,
            "",
            "For Ex-UK ThinkPads and EliteBooks, also check:",
            "  - Laptop Clinic (laptopclinic.co.ke) -- professionally verified refurbs",
            "    and in-store upgrade service."
        ) -join "`n"
        & $AddFinding "WARNING" 0 "[KE] HDD on a likely Ex-UK/refurbished machine: SSD upgrade strongly recommended. See local sourcing advice." $remedy
    }

    # -----------------------------------------------------------------------
    # KE-BLOAT-01 : Suspicious Ex-UK / Refurb OEM Bloat Detection
    # Checks for process names common in Ex-UK corporate refurb builds.
    # -----------------------------------------------------------------------
    $suspectProcesses = @()
    $knownExUKBloat = @(
        "CCleaner",        # Often pre-installed by refurb shops
        "Avast",           # Common on UK corporate refurbs
        "AVG",
        "McAfeeCSP",       # McAfee remnants on ex-corporate HP/Dell
        "McAfee",
        "HPSAService",     # HP Sure Sense / HP Wolf Security agent
        "CiscoAnyConnect", # Ex-corporate VPN clients
        "vpnagent",
        "BESClient",       # BlackBerry Enterprise -- ex-corporate MDM
        "ManagementAgent", # Various MDM agents from ex-corporate pools
        "SccmAgent",       # Microsoft SCCM / Endpoint Config Manager
        "MaaS360",         # IBM MaaS360 MDM
        "VMware",          # Ex-corporate VMware Horizon clients
        "AbsoluteAgent",   # Computrace/Absolute anti-theft -- can be locked to prior owner
        "rpcnetp"          # Computrace low-level persistence agent
    )

    if ($null -ne $baseline.TopProcesses -and @($baseline.TopProcesses).Count -gt 0) {
        foreach ($proc in $baseline.TopProcesses) {
            foreach ($bloat in $knownExUKBloat) {
                if ($proc.Name -like "*$bloat*") {
                    $suspectProcesses += $proc.Name
                }
            }
        }
    }

    if (@($suspectProcesses).Count -gt 0) {
        $suspectList = ($suspectProcesses | Sort-Object -Unique | ForEach-Object { "    - $_" }) -join "`n"
        $remedy = @(
            "KENYA CONTEXT: The following processes are commonly found on Ex-UK",
            "(refurbished) machines imported from the UK/EU corporate pool. They may",
            "indicate the laptop was not properly wiped before resale.",
            "",
            "Detected suspect processes:",
            $suspectList,
            "",
            "What to investigate:",
            "  1. AbsoluteAgent / rpcnetp (Computrace): BIOS-level anti-theft agent.",
            "     If active, the previous owner may still have remote access.",
            "     Ask the seller for a clean deactivation certificate.",
            "  2. MDM agents (MaaS360, SccmAgent, BESClient): Allow a prior corporate",
            "     IT department to remotely manage your device. Uninstall via",
            "     Control Panel -> Programs, or use the vendor's removal tool.",
            "  3. Antivirus remnants (McAfee, Avast, AVG): Use dedicated removal tools",
            "     such as MCPR for McAfee, AvastClear for Avast.",
            "  4. VPN clients (CiscoAnyConnect): Uninstall via Control Panel.",
            "",
            "If in doubt, perform a clean install from the official Microsoft ISO:",
            "  microsoft.com/en-us/software-download/windows11",
            "",
            "Where to get a reliable Ex-UK machine with proper wipe guarantees:",
            "  - ECB Technologies (ecbtechnologies.co.ke) -- verified clean deliveries",
            "  - Laptop Clinic (laptopclinic.co.ke)       -- professionally refurbished",
            "  - Mombasa Computers -- Moi Avenue, CBD     -- trusted clean Ex-UK"
        ) -join "`n"
        $suspectCount = @($suspectProcesses).Count
        & $AddFinding "WARNING" 20 "[KE] Possible Ex-UK corporate bloat/MDM agents detected ($suspectCount process(es)). May indicate incomplete refurb wipe." $remedy
    }

    # -----------------------------------------------------------------------
    # KE-INTEGRITY-01 : Pirated / Tampered Windows Signals
    # Soft heuristic -- flags conditions consistent with KMS-activated builds.
    # -----------------------------------------------------------------------
    $integrityFlags = @()
    $kmsSignals = @("KMSAuto", "KMSpico", "AAct", "HEU_KMS", "Re-Loader", "KMSTools")

    if ($null -ne $baseline.TopProcesses) {
        foreach ($proc in $baseline.TopProcesses) {
            foreach ($sig in $kmsSignals) {
                if ($proc.Name -like "*$sig*") {
                    $integrityFlags += "KMS activator process running: $($proc.Name)"
                }
            }
        }
    }

    if ($null -ne $baseline.WakeLocks) {
        foreach ($lock in $baseline.WakeLocks) {
            foreach ($sig in $kmsSignals) {
                if ($lock.Blocker -like "*$sig*") {
                    $integrityFlags += "KMS activator wake lock: $($lock.Blocker)"
                }
            }
        }
    }

    if (@($integrityFlags).Count -gt 0) {
        $flagList = ($integrityFlags | ForEach-Object { "    - $_" }) -join "`n"
        $remedy = @(
            "KENYA CONTEXT: Signals consistent with a KMS-activated (pirated) Windows",
            "installation have been detected. This is very common on budget laptops",
            "purchased from small CBD stalls on Luthuli Avenue and River Road.",
            "",
            "Detected signals:",
            $flagList,
            "",
            "Risks of pirated Windows:",
            "  - KMS activators frequently bundle spyware, miners, or backdoors.",
            "  - System updates are often blocked, leaving critical security gaps.",
            "  - Microsoft may remotely deactivate the license, locking you out.",
            "  - BSOD and stability issues are common on tampered activation builds.",
            "",
            "Recommended actions:",
            "  1. Verify your Windows license: Settings -> System -> Activation.",
            "     A genuine license shows 'Windows is activated with a digital license'.",
            "  2. If pirated: perform a clean install from the official Microsoft ISO.",
            "     You can buy a genuine Windows 11 Home key for ~KES 1,500-3,000.",
            "  3. Run Malwarebytes Free (malwarebytes.com) before wiping to scan for",
            "     bundled malware if you need to recover data first.",
            "",
            "CAUTION -- High-risk sellers known for this issue:",
            $highRiskList,
            "",
            "For a laptop with verified, clean software from the start, prefer:",
            $trustedNewList
        ) -join "`n"
        & $AddFinding "CRITICAL" 30 "[KE] Possible pirated/KMS-activated Windows detected. Common on CBD budget laptops. See integrity remedy." $remedy
    }

    # -----------------------------------------------------------------------
    # KE-INFO-01 : General Nairobi buyer advisory (informational, once only)
    # Only emitted if at least one Kenya finding was triggered above.
    # -----------------------------------------------------------------------
    $kenyaFindingTriggered = (@($suspectProcesses).Count -gt 0) -or
                              (@($integrityFlags).Count   -gt 0) -or
                              $hasHDD -or
                              ($null -ne $baseline.Memory.Modules -and $baseline.Memory.Modules -eq 1)

    if ($kenyaFindingTriggered) {
        $remedy = @(
            "Trusted sellers for NEW GAMING laptops in Nairobi:",
            $trustedGamingList,
            "",
            "Trusted sellers for BRAND-NEW / warranted machines:",
            $trustedNewList,
            "",
            "Reddit Pro-Tip: For high-end gaming laptops, many Nairobi tech pros",
            "buy directly from Amazon/Newegg (USA) and ship via freight forwarders",
            "like Kentex Cargo, Savostore, or APS Logistix (~USD 15/kg).",
            "This typically saves 15-30% vs. local CBD pricing on RTX 4060+ machines.",
            "",
            "Sellers to AVOID:",
            $highRiskList
        ) -join "`n"
        & $AddFinding "INFO" 0 "[KE] Nairobi buying guide: trusted shops and high-risk sellers summarized in remedy." $remedy
    }
}
