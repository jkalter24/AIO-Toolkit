@{
    # ==============================================================================
    # Cipher System Check v7 - Configuration File
    # ==============================================================================
    # This file centralizes all configurable settings for portability and flexibility.
    # Works on any Windows desktop/laptop with optional user-specific overrides.
    # ==============================================================================

    # LOGGING & STORAGE
    Logging = @{
        # Use %LOCALAPPDATA% on all machines (universal)
        UseLocalAppData = $true
        
        # Fallback if LOCALAPPDATA unavailable (rare on modern Windows)
        FallbackFolder = 'Desktop\CipherCheckLogs'
        
        # Retention: number of days to keep old log files (0 = keep all)
        RetentionDays = 30
        
        # Max log file size in MB before archiving (0 = no limit)
        MaxLogSizeMB = 50
    }

    # UI & THEME (works universally; customize for specific machines)
    Theme = @{
        # Dark mode colors (universal dark theme)
        DarkMode = $true
        AccentColor = '#4DA3FF'        # Cyan-blue accent
        BackgroundColor = '#0B0D10'    # Deep dark background
        TextColor = '#EAECEF'          # Light text
        
        # Window size
        WindowWidth = 1200
        WindowHeight = 800
        
        # Font (Segoe UI is universal on Windows)
        Font = 'Segoe UI'
        FontSize = 11
    }

    # PERFORMANCE & BEHAVIOR
    Performance = @{
        # GUI polling interval for progress updates (milliseconds)
        GUIPollingIntervalMs = 250
        
        # File read retry attempts when encountering locks
        FileReadRetryAttempts = 8
        
        # Initial backoff delay in milliseconds (increases exponentially)
        FileReadBackoffMs = 40
        
        # Max concurrent external processes
        MaxConcurrentProcesses = 2
        
        # Timeout for external commands (seconds)
        CommandTimeoutSeconds = 600
    }

    # DIAGNOSTIC MODULES (toggle to enable/disable)
    Modules = @{
        EnableSSDAnalysis = $true
        EnableWHEAAnalysis = $true
        EnableTDRAnalysis = $true
        EnableStorageAnalysis = $true
        EnableRebootAnalysis = $true
        EnableNetworkDiagnostics = $true
        EnableMemoryDiagnostics = $true
    }

    # AUTOMATION MODES
    AutomationModes = @{
        'Safe' = @{
            Description = 'Read-only diagnostics; no repairs'
            EnableRepairs = $false
            ScanDays = 7
        }
        'Balanced' = @{
            Description = 'Diagnostics + low-risk recommended repairs'
            EnableRepairs = $true
            RunRepair = $true
            RunTdrTweak = $false
            ScanDays = 30
        }
        'Deep' = @{
            Description = 'Full diagnostics and all recommended repairs'
            EnableRepairs = $true
            RunRepair = $true
            RunTdrTweak = $true
            RunNetworkReset = $false
            RunMemDiag = $false
            ScanDays = 365
        }
    }

    # FEATURE FLAGS (enable/disable major features)
    Features = @{
        EnableTestMode = $true
        EnableAdvancedLiveView = $true
        EnableProgressSnapshots = $true
        EnableIncrementalResults = $true
        EnableLogging = $true
        EnableAutoRepair = $true
        EnableScheduling = $false  # Future feature
    }

    # USER-SPECIFIC OVERRIDES (customize for your machine only)
    # Set $null to use universal defaults
    UserSpecific = @{
        # Machine name this config applies to (leave $null for universal, or 'JKALT-DESKTOP', 'WORKSTATION', etc.)
        MachineName = $null
        
        # Custom log folder (overrides default; leave $null for universal)
        CustomLogFolder = $null
        
        # Email for notifications (future feature; leave $null if not used)
        NotificationEmail = $null
        
        # Run scans on schedule (cron-like; format: 'Daily', 'Weekly', 'Monthly', or $null)
        ScheduledScanFrequency = $null
        
        # Preferred repair mode (Safe, Balanced, Deep, or $null for user choice)
        PreferredRepairMode = $null
        
        # Suppress certain warnings (array of warning IDs or empty)
        SuppressWarnings = @()
    }

    # DIAGNOSTIC EVENT FILTERS (fine-tune event collection)
    EventFilters = @{
        # Number of recent days to scan for events
        EventHistoryDays = 30
        
        # Limit number of events per type (to avoid overwhelming)
        MaxEventsPerType = 200
        
        # Filter by event level (Critical, Error, Warning, Informational)
        MinEventLevel = 'Warning'
    }

    # REPAIR SAFETY PROFILES
    RepairProfiles = @{
        Windows = @{
            Description = 'Windows system repairs'
            Commands = @(
                'DISM /Online /Cleanup-Image /RestoreHealth',
                'SFC /scannow'
            )
            RequireAdmin = $true
            MayRestart = $false
        }
        GPU = @{
            Description = 'GPU driver timeout adjustment'
            RegistryPath = 'HKLM:\System\CurrentControlSet\Control\GraphicsDrivers'
            RegistryKey = 'TdrDelay'
            RegistryValue = 8
            RequireAdmin = $true
            MayRestart = $false
        }
        Network = @{
            Description = 'Network stack reset'
            Commands = @(
                'netsh int ip reset reset.log',
                'netsh winsock reset catalog'
            )
            RequireAdmin = $true
            MayRestart = $true
        }
    }

    # COMPATIBILITY SETTINGS
    Compatibility = @{
        # Minimum Windows version (Build number)
        MinWindowsBuild = 19041  # Windows 10 21H2 / Windows 11
        
        # PowerShell version required
        MinPowerShellVersion = '5.1'
        
        # Required .NET Framework version
        MinDotNetVersion = '4.5'
    }

    # TELEMETRY & FEEDBACK (if implemented in future)
    Telemetry = @{
        Enabled = $false
        SendErrors = $false
        SendDiagnostics = $false
    }

    # ADVANCED / DEBUG SETTINGS
    Debug = @{
        # Enable verbose logging
        VerboseLogging = $false
        
        # Log all file I/O operations
        LogFileOperations = $false
        
        # Log all registry operations
        LogRegistryOperations = $false
        
        # Keep temporary files for inspection
        KeepTempFiles = $false
        
        # Mock/simulation mode (for testing without making changes)
        SimulationMode = $false
    }
}
