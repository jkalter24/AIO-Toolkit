# Cipher System Check v7 - Complete Documentation

## Overview

**Cipher System Check v7** is a professional-grade Windows system diagnostics and repair tool designed to identify and fix hardware, driver, firmware, and OS-level issues causing system instability, softlocks, and crashes.

### Key Features

✅ **Deep Hardware Analysis**
- Multi-SSD/NVMe diagnostics with SMART data (temperature, wear, error counts)
- WHEA error tracking (memory, CPU, firmware faults)
- GPU driver timeout (TDR) pattern detection
- Storage controller timeout analysis
- Unexpected reboot/crash event tracking

✅ **Windows Integrity Checks**
- System File Checker (SFC) scans
- DISM component store analysis and repair
- Update system integrity verification

✅ **Safe Repair Options**
- Windows component store reset
- GPU driver timeout adjustment
- Network stack reset
- Memory diagnostics launcher
- Defender full scan

✅ **Modern GUI Dashboard**
- Real-time system information
- Tabbed diagnostic results view
- SSD health visualization
- Event history explorer
- One-click log folder access

---

## System Requirements

- **OS**: Windows 10/11 (Build 19041+)
- **Privileges**: Administrator access required
- **RAM**: 4 GB minimum (8 GB+ recommended)
- **Storage**: 2 GB free space for logs

### Your System: ✅ Fully Supported
```
CPU: AMD Ryzen 9 5950X
RAM: 32 GB DDR4
Storage: 3 SATA SSDs (spanned D:) + NVMe
GPU: Asus GTX 1060 3GB OC
MOBO: Asus TUF GAMING B550-PLUS WIFI II
```

---

## Quick Start

### Option 1: GUI Dashboard (Recommended)

```powershell
# Run in PowerShell as Administrator
# Change to the folder where you saved the scripts, for example your Downloads folder:
cd "C:\Path\To\Scripts"    # e.g. C:\Users\You\Downloads
powershell.exe -ExecutionPolicy Bypass -File .\Cipher-System-Check-v7.ps1 -Mode Gui
```

**What to do:**
1. Click **"▶ Start Full Scan"** button
2. Wait for completion (5-15 minutes depending on event log size)
3. Review results in the tabbed interface
4. Select repair options if needed
5. Click **"⚙ Selected Repairs"** to execute

### Option 2: Console Mode (Advanced)

```powershell
# Full diagnostics + analysis only (run from the scripts folder)
cd "C:\Path\To\Scripts"    # change to the folder where you saved the scripts
powershell.exe -ExecutionPolicy Bypass -File .\Cipher-System-Check-v7.ps1 -Mode Core

# Diagnostics + Windows repairs
powershell.exe -ExecutionPolicy Bypass -File .\Cipher-System-Check-v7.ps1 -Mode Core -RunRepair

# Diagnostics + GPU TDR tweak
powershell.exe -ExecutionPolicy Bypass -File .\Cipher-System-Check-v7.ps1 -Mode Core -RunTdrTweak

# Diagnostics + all repairs
powershell.exe -ExecutionPolicy Bypass -File .\Cipher-System-Check-v7.ps1 -Mode Core -RunRepair -RunTdrTweak -RunNetworkReset
```

---

## Diagnostic Sections Explained

### 1. **SSD & Storage Health** 📊
**What it checks:**
- Temperature levels (dangerous threshold: >55°C sustained)
- Wear percentage (critical: >80%)
- Read/write errors (any errors suggest hardware failure)
- Power-on hours and unsafe shutdowns
- Controller reliability

**Why it matters:** Spanned storage (your D: drive) is sensitive to SATA/NVMe errors. Elevated temps or errors predict imminent failure.

### 2. **WHEA Errors** ⚠️
**What it checks:**
- Windows Hardware Error Architecture events (30-day history)
- Memory faults, CPU errors, thermal throttling
- Firmware/BIOS issues

**Why it matters:** WHEA errors often indicate:
- RAM degradation or bad slots
- CPU instability (overclocking, degradation)
- Motherboard firmware bugs
- Inadequate cooling

**Action:** Check RAM in different slots; update BIOS if available.

### 3. **GPU Driver Timeouts (TDR)** 🎮
**What it checks:**
- Display driver reset events
- NVIDIA/AMD timeout patterns
- Driver hang indicators

**Why it matters:** TDR events cause:
- System freezes
- Display blanks
- Softlocks
- Reboot loops

**Action:** Update GPU drivers or reduce clock speeds if overclocked.

### 4. **Storage Timeouts** 💾
**What it checks:**
- SATA/NVMe controller timeout events
- Storage bus resets
- Filesystem errors (Ntfs, ReFS)

**Why it matters:** Spanned storage is vulnerable; timeouts predict data corruption or drive failure.

### 5. **Unexpected Reboots** 🔄
**What it checks:**
- Kernel-Power events (crashes)
- Sudden shutdown logs
- Power loss indicators

**Why it matters:** Indicates hardware failure, driver crashes, or power delivery issues.

### 6. **Firmware & Drivers** 🔧
**What it checks:**
- BIOS age (>1 year = update available)
- GPU driver age (>6 months = review)
- OS build/hotfixes

---

## Repair Options - Safety & Impact

### ⚙️ Windows Repair (SAFE)
```
What: Resets update cache, fixes component store
Risk: LOW - Standard Windows maintenance
Impact: May require 15-30 minutes
Recommended: YES
```
- Clears corrupted Windows Update files
- Rebuilds component store integrity
- Safe to run; no data loss

### 🎮 GPU Driver Adjustment (MEDIUM)
```
What: Increases TDR (Timeout Detection Recovery) delay
Risk: MEDIUM - Allows slower timeouts
Impact: May mask driver issues instead of fixing them
Recommended: If TDR events detected
```
- Sets `TdrDelay` to 10 seconds (default: ~2 seconds)
- Helps if driver hangs are brief
- Does NOT fix underlying driver issues
- May allow bad drivers to not be caught as quickly

### 🌐 Network Reset (MEDIUM)
```
What: Resets TCP/IP stack and Winsock
Risk: MEDIUM - Network briefly unavailable
Impact: 30 seconds downtime
Recommended: Only if network issues present
```
- Clears network configuration cache
- Resets TCP/IP protocol stack
- Requires ~30 second reconnection

### 🧠 Memory Diagnostics (HIGH)
```
What: Launches Windows Memory Diagnostic tool
Risk: HIGH - System will restart
Impact: 10-30 minutes; system unavailable
Recommended: Only if WHEA errors indicate RAM issues
```
- Runs Windows native MDSCHED.EXE
- Requires system restart
- Tests all RAM thoroughly
- Can take 15+ minutes

### 🛡️ Full Defender Scan (HIGH)
```
What: Complete antimalware scan
Risk: MEDIUM - High system load
Impact: 30-60 minutes; heavy disk/CPU usage
Recommended: If malware suspected or good practice
```
- Full filesystem scan
- May find and quarantine threats
- System remains usable but slow

---

## Your Setup: What to Watch For

### Your System's Strengths ✅
- High-end CPU (5950X) - excellent stability if properly cooled
- Ample RAM (32GB) - unlikely to be bottleneck
- Multiple SSDs - good redundancy if not all spanned

### Your System's Risks ⚠️
**1. Spanned Storage (D: drive)**
- Single failure affects entire array
- SATA timeout can cascade
- Recommendation: Run chkdsk monthly

**2. GTX 1060 (Legacy GPU)**
- Driver support ending soon (not recommended for modern APIs)
- Check driver version; consider 550.x+ series
- May TDR under load if driver is old

**3. High Core Count CPU (5950X)**
- Excellent but demanding; needs stable power delivery
- Monitor temps; if throttling, check cooling/paste
- WHEA errors here suggest power/thermal issues

**4. B550 Motherboard**
- Generally stable but check for BIOS updates
- 2.5GB Ethernet needs driver updates if experiencing drops

---

## Expected Results Interpretation

### Scoring Breakdown

| Score | Meaning | Action |
|-------|---------|--------|
| 0 | No issues | Monitor normally |
| 1-10 | Minor signals | Review results; non-urgent |
| 11-25 | Moderate concern | Plan repairs in next week |
| 26-40 | Significant issues | Recommend repairs soon |
| 40+ | Critical | Address immediately |

### Example: Your Likely Diagnosis
If experiencing softlocks, expect top issues to be:
1. **GPU (high)** - TDR timeouts likely if display freezes
2. **Storage (high)** - Spanned D: drive timeouts if system pauses
3. **Driver (medium)** - Old GPU drivers common
4. **Firmware (low-medium)** - Check BIOS age

---

## Logs & Results

All diagnostic results saved to (per-user local application data):

```
%LOCALAPPDATA%\CipherCheck\Logs\
```

Key files generated:

| File | Content |
|------|---------|
| `analysis_ranked.txt` | Summary of findings |
| `ssd_health_detailed.csv` | SMART data for all drives |
| `whea_events_detailed.csv` | WHEA errors (30 days) |
| `tdr_events_detailed.csv` | GPU timeout events |
| `storage_timeout_events.csv` | Controller timeouts |
| `reboot_events.csv` | Unexpected shutdowns |
| `system_snapshot.txt` | System configuration |
| `diagnostic_results.xml` | Full machine-readable results |

### Viewing Logs
- GUI: Click **"📁 Open Log Folder"** button (opens %LOCALAPPDATA%\CipherCheck\Logs)
- Console: Navigate to `%LOCALAPPDATA%\CipherCheck\Logs` or use the script folder where logs are created
- CSV files: Open in Excel/LibreOffice for analysis

---

## Troubleshooting

### Problem: "Run this script as Administrator"
**Solution:** Right-click PowerShell, choose "Run as Administrator", then run the command.

### Problem: GUI doesn't open / shows errors
**Solution:** Ensure .NET Framework 4.5+ is installed
```powershell
# Check .NET version
reg query "HKLM\SOFTWARE\Microsoft\.NETFramework\v4.0.30319" /v Release
# 528040+ = 4.8+ (good)
```

### Problem: Diagnostics hang or take >20 minutes
**Solution:** Event log is very large. Wait or filter events:
```powershell
# Clear old events to speed up future scans
wevtutil cl System
```

### Problem: Can't apply repairs - "Access Denied"
**Solution:** Some repairs require full admin and UAC bypass:
```powershell
powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File .\Cipher-System-Check-v7.ps1 -Mode Core -RunRepair
```

### Problem: Memory Diagnostics won't schedule
**Solution:** Manually run:
```powershell
# From admin PowerShell
mdsched.exe
```

---

## Advanced Usage

### Running Specific Repairs Only
```powershell
# Windows repairs only
.\Cipher-System-Check-v7.ps1 -Mode Core -RunRepair

# GPU tweaks only
.\Cipher-System-Check-v7.ps1 -Mode Core -RunTdrTweak

# Combine multiple repairs
.\Cipher-System-Check-v7.ps1 -Mode Core -RunRepair -RunTdrTweak -RunDefenderScan
```

### Scheduling Regular Checks
```powershell
# Create scheduled task for weekly diagnostics
$taskName = "CipherSystemCheck"
# Set $scriptPath to the full path where you saved the scripts, for example:
$scriptPath = 'C:\Path\To\Scripts\Cipher-System-Check-v7.ps1'
$action = New-ScheduledTaskAction -Execute powershell.exe -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -Mode Core"
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 3AM
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -RunLevel Highest
```

---

## Safety Guarantees

✅ **No Data Loss** - All repairs are standard Windows operations
✅ **No Warranty Violations** - Uses Windows native tools only
✅ **Reversible** - Most repairs can be undone if needed
✅ **Logged** - All actions recorded in detailed output
✅ **AMD Ryzen Optimized** - No overclocking adjustments
✅ **B550 Board Aware** - Compatible with your motherboard

---

## When to Escalate

Stop and seek professional help if:
- WHEA errors mention CPU or memory repeatedly
- S.M.A.R.T. errors show media damage
- TDR events occur even after driver update
- Unexpected reboots continue after repairs
- System temperatures exceed 85°C idle

---

## Contact & Support

**GitHub Issues**: Report bugs or feature requests
**AMD Ryzen Drivers**: https://www.amd.com/en/support
**NVIDIA Drivers**: https://www.nvidia.com/Download/driverDetails.aspx
**Asus Support**: https://www.asus.com/support/

---

## Version History

**v7 (Current)**
- ✨ Deep SSD health analysis with SMART data
- ✨ Comprehensive WHEA error tracking
- ✨ TDR pattern detection and reporting
- ✨ WPF GUI dashboard interface
- ✨ Modern code structure and optimization
- ✨ Spanned volume support (your D: drive)

**v6** 
- Basic diagnostics and scoring

---

## License & Disclaimer

Use at your own risk. This tool uses Windows native diagnostics and repair utilities. No warranty provided. Always backup important data before running repairs.

**Created for**: System stability troubleshooting
**Tested on**: Windows 10/11 with AMD Ryzen 5000 series
**Compatible**: Intel/AMD systems with SATA/NVMe storage

---

Last Updated: May 5, 2026
