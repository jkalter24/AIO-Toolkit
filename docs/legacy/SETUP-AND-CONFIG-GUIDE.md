# Cipher System Check v7 - Universal Setup & Configuration Guide

## Quick Start

### Run the GUI (Recommended)
```powershell
# From PowerShell (Admin not required for diagnostics)
.\Cipher-System-Check-v7-GUI.ps1
```

### Run from Command Line
```batch
REM Run GUI
powershell -NoProfile -ExecutionPolicy Bypass -File Cipher-System-Check-v7-GUI.ps1

REM Run diagnostics only (Safe mode)
powershell -NoProfile -ExecutionPolicy Bypass -File Cipher-System-Check-v7-Core.ps1 -QuietMode

REM Run diagnostics + auto-repairs (Balanced)
powershell -NoProfile -ExecutionPolicy Bypass -File Cipher-System-Check-v7-Core.ps1 -QuietMode -RunRepair

REM Quick test/validation
powershell -NoProfile -ExecutionPolicy Bypass -File Cipher-System-Check-v7-Core.ps1 -TestMode
```

## Configuration

### Universal (Default) Mode
- Works on **any** Windows 10/11 machine without customization
- Logs stored in: `%LOCALAPPDATA%\CipherCheck\Logs`
- Uses sensible defaults for all settings
- **No configuration needed** — just run the scripts

### Machine-Specific Mode
Edit `Cipher-System-Check-Config.psd1` to customize for a specific machine:

```powershell
UserSpecific = @{
    MachineName = 'MY-LAPTOP'              # Only apply config to this machine
    CustomLogFolder = 'D:\MyLogs'           # Custom log location
    PreferredRepairMode = 'Balanced'       # Auto-select repair mode (Safe, Balanced, Deep)
    SuppressWarnings = @('WHEA-001')       # Ignore specific warnings
}
```

**Important**: When `UserSpecific.MachineName = $null`, the config applies **universally** to all machines.

## Automation Modes

### Safe Mode (Read-Only)
- Scans for issues
- **No repairs applied**
- Lowest risk
- Best for initial diagnosis

### Balanced Mode (Recommended)
- Scans for issues
- Applies **low-risk repairs**:
  - Windows component store repair
  - GPU driver timeout adjustment
- Good for most users

### Deep Mode (Advanced)
- Full diagnostics
- All recommended repairs:
  - Windows component store repair
  - GPU driver timeout adjustment
  - Network stack reset (if storage issues detected)
  - Memory diagnostics (if WHEA errors detected)
- Highest risk; may require restart

## File Structure

```
Cipher-System-Check-v7/
├── Cipher-System-Check-v7-Core.ps1          # Diagnostic engine
├── Cipher-System-Check-v7-GUI.ps1           # WPF UI
├── Cipher-System-Check-Config.psd1          # Configuration (optional customization)
├── Cipher-System-Check-v7-README.md         # This file
├── Cipher-System-Check-v7-Launcher.bat      # Windows batch launcher
├── Cipher-System-Check-v7-Launcher.bat     # Official launcher
├── tools/
│   └── parse_check.ps1                     # Parser validation tool
└── %LOCALAPPDATA%\CipherCheck\Logs/        # Generated logs (automatic)
    ├── progress_snapshot.json              # Live progress tracking
    ├── progress_snapshot.txt               # Text version of progress
    ├── results_incremental.json            # Real-time result updates
    ├── diagnostic_results.xml              # Final detailed results
    ├── analysis_ranked.txt                 # Human-readable summary
    ├── ssd_health_detailed.csv             # SSD diagnostics
    └── *.txt, *.csv, *.json               # Additional logs
```

## Performance Settings

Configured in `Cipher-System-Check-Config.psd1`:

```powershell
Performance = @{
    GUIPollingIntervalMs = 250       # GUI refreshes every 250ms
    FileReadRetryAttempts = 8        # Retry reading snapshot files 8 times
    FileReadBackoffMs = 40           # Initial retry delay (exponential backoff)
    CommandTimeoutSeconds = 600      # External commands timeout after 10 minutes
}
```

### Adjust for Your System
- **Slower systems** (old laptops): increase `GUIPollingIntervalMs` to 500-1000ms
- **Faster systems** (modern desks): decrease to 100ms for snappier UI
- **Network drives / slow storage**: increase `FileReadRetryAttempts` to 12-16

## Diagnostic Modules

Enable/disable individual diagnostic components:

```powershell
Modules = @{
    EnableSSDAnalysis = $true          # Storage device health
    EnableWHEAAnalysis = $true         # Hardware error detection
    EnableTDRAnalysis = $true          # GPU driver timeout analysis
    EnableStorageAnalysis = $true      # Storage controller events
    EnableRebootAnalysis = $true       # Unexpected restart tracking
    # ... others
}
```

Set to `$false` to skip slow or problematic diagnostics on your system.

## UI Customization

### Change Theme
```powershell
Theme = @{
    AccentColor = '#4DA3FF'           # Change accent color (hex)
    BackgroundColor = '#0B0D10'       # Background color
    TextColor = '#EAECEF'             # Text color
    WindowWidth = 1200                # Window width (pixels)
    WindowHeight = 800                # Window height
}
```

### Supported Colors
- **Accents**: `#4DA3FF` (blue), `#2D8A57` (green), `#C94B20` (orange)
- **Backgrounds**: `#0B0D10` (deep dark), `#141923` (medium dark), `#1A1F28` (light dark)

## Troubleshooting

### Issue: "Access Denied" or File Lock Errors
**Status**: Fixed in latest version (v7.1+)
- Uses FileStream with ReadWrite sharing
- Automatic retry with exponential backoff
- Falls back to plain-text snapshot if JSON read fails

### Issue: GUI Not Responding During Scan
**Solution**: 
- This is normal for long-running diagnostics
- Progress bar and phase updates show actual progress
- Do **not** force-close the application; let it complete or click "Cancel Scan"

### Issue: Repairs Won't Run / "Admin Required"
**Solution**:
- Repairs require **Administrator** privileges
- Right-click GUI launcher → "Run as Administrator"
- Or run from elevated PowerShell

### Issue: Some Diagnostics Run Slowly
**Solution**:
- Disable unused modules in config: set to `$false`
- Increase timeout in `Performance.CommandTimeoutSeconds` if scans hang
- Run `Safe` mode (diagnostics only) instead of repair modes

### Issue: Logs Not Being Saved
**Solution**:
- Verify log folder exists: `%LOCALAPPDATA%\CipherCheck\Logs`
- Check folder permissions (folder must be writable)
- Try custom log path in config: `UserSpecific.CustomLogFolder`

## Advanced Usage

### Command-Line Automation
```powershell
# Run Balanced mode and exit
.\Cipher-System-Check-v7-Core.ps1 -QuietMode -RunRepair

# Run specific repairs only
.\Cipher-System-Check-v7-Core.ps1 -RunRepair -RunTdrTweak -RunNetworkReset

# Test mode (fast validation)
.\Cipher-System-Check-v7-Core.ps1 -TestMode
```

### Scheduled Tasks
To schedule automatic scans (requires Administrator):

```powershell
# Create a scheduled task (Balanced mode, daily at 2 AM)
$trigger = New-ScheduledTaskTrigger -Daily -At 2AM
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File C:\Path\To\Cipher-System-Check-v7-Core.ps1 -QuietMode -RunRepair"
Register-ScheduledTask -TaskName "CipherSystemCheck-Daily" -Trigger $trigger -Action $action -RunLevel Highest
```

### Debug Mode
Enable verbose logging:

```powershell
Debug = @{
    VerboseLogging = $true              # Detailed log output
    LogFileOperations = $true           # Log all file I/O
    LogRegistryOperations = $true       # Log all registry changes
    KeepTempFiles = $true               # Keep intermediate files
}
```

## Supported Systems

- **Windows 10** Build 19041+ (21H2 and later)
- **Windows 11** all versions
- **PowerShell 5.1+** (includes Windows 10/11)
- **Administrator** not required for diagnostics; required for repairs

## Features

✅ **Deep Hardware Diagnostics**
- SSD health, SMART analysis
- WHEA hardware error tracking
- GPU driver timeout (TDR) analysis
- Memory and storage reliability

✅ **Live Progress Tracking**
- Real-time phase/ETA updates
- Live result streaming
- Advanced detailed log view

✅ **Automated Repairs**
- Windows component store repair
- GPU driver timeout adjustment
- Network stack reset
- Safe, Balanced, and Deep modes

✅ **Universal Portability**
- Works on any Windows 10/11
- Optional machine-specific configuration
- Sensible defaults for all settings

✅ **Modern UI**
- Dark theme WPF interface
- Responsive progress bar
- Expandable sidebar
- Collapsible advanced views

## Support & Updates

For issues or feature requests, include:
1. Windows version and build number
2. Output from `diagnostic_results.xml` in logs folder
3. Error messages and stack traces
4. System specs (CPU, RAM, storage type)

## License

Freeware — use and modify for personal/commercial use.

---

**Version**: 7.1 (File Locking Fixed)  
**Last Updated**: May 6, 2026
