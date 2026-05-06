# Cipher System Check v7 - Core Engine
# Comprehensive diagnostics with deeper hardware analysis, WHEA tracking, driver timeout patterns
# Designed for console or GUI invocation

param(
    [switch]$RunRepair,
    [switch]$RunNetworkReset,
    [switch]$RunTdrTweak,
    [switch]$RunMemDiag,
    [switch]$RunDefenderScan,
    [switch]$RunWindowsUpdate,
    [switch]$QuietMode,
    [switch]$TestMode
)

$ErrorActionPreference = 'SilentlyContinue'
$WarningPreference = 'SilentlyContinue'

# Load configuration
$configPath = Join-Path $PSScriptRoot 'Cipher-System-Check-Config.psd1'
$script:Config = @{ Logging = @{ UseLocalAppData = $true }; Debug = @{ VerboseLogging = $false } }
if (Test-Path $configPath) {
    try {
        $script:Config = Import-PowerShellDataFile $configPath
    } catch {
        Write-Warning "Failed to load config from $configPath; using defaults."
    }
}

# Determine log folder (universal or user-specific)
$LogRoot = $null
if ($script:Config.UserSpecific -and $script:Config.UserSpecific.CustomLogFolder) {
    $LogRoot = $script:Config.UserSpecific.CustomLogFolder
} elseif ($script:Config.Logging.UseLocalAppData -and $env:LOCALAPPDATA) {
    $LogRoot = Join-Path $env:LOCALAPPDATA 'CipherCheck\Logs'
} elseif ($env:LOCALAPPDATA) {
    $LogRoot = Join-Path $env:LOCALAPPDATA 'CipherCheck\Logs'
} else {
    $LogRoot = Join-Path $env:USERPROFILE $script:Config.Logging.FallbackFolder
}
New-Item -ItemType Directory -Force -Path $LogRoot | Out-Null

# Quick test mode: generate a small, valid diagnostic and exit early to allow fast GUI testing.
if ($TestMode) {
    # Initialize global scope for test mode
    if (-not $global:Scores) { $global:Scores = @{} }
    if (-not $global:Reasons) { $global:Reasons = @{} }
    
    $results = [pscustomobject]@{
        SSDs = @(
            [pscustomobject]@{FriendlyName = 'SSD 1 - Samsung 970 EVO'; Temperature = '36C'; Wear = '5%'; ReadErrors = 0; WriteErrors = 0; HealthStatus = 'Healthy'; PowerOnHours = '2400'}
            [pscustomobject]@{FriendlyName = 'SSD 2 - WD Blue 500GB'; Temperature = '42C'; Wear = '8%'; ReadErrors = 0; WriteErrors = 0; HealthStatus = 'Healthy'; PowerOnHours = '1850'}
        )
        WHEAEvents = @()
        TDREvents = @()
        RebootEvents = @()
        StorageTimeouts = @()
        TopIssue = 'Test Mode - No issues detected'
        TopIssueScore = 0
        AllScores = @{ Storage = 0; WHEA = 0; GPU = 0; Memory = 0 }
        Timestamp = (Get-Date).ToString()
    }

    $xmlPath = Join-Path $LogRoot 'diagnostic_results.xml'
    $results | Export-Clixml $xmlPath
    "Test diagnostic generated: $xmlPath" | Out-File (Join-Path $LogRoot 'analysis_ranked.txt') -Encoding utf8 -Force
    exit 0
}

# ===== FUNCTION DEFINITIONS =====
function Write-Section { param([string]$Text, [switch]$Silent)
    $msg = "`n=== $Text ==="
    if (-not $Silent -and -not $QuietMode) { Write-Host $msg -ForegroundColor Cyan }
    return $msg
}

function Save-Text { param([string]$Name, [string]$Value)
    $Value | Out-File -FilePath (Join-Path $LogRoot $Name) -Encoding utf8 -Force
}

$script:ProgressSnapshotPath = Join-Path $LogRoot 'progress_snapshot.json'
$script:ProgressTextPath = Join-Path $LogRoot 'progress_snapshot.txt'
$script:ResultsIncrementalPath = Join-Path $LogRoot 'results_incremental.json'
$script:ProgressStartedAt = Get-Date

function Format-EtaText {
    param([Nullable[int]]$Seconds)

    if ($null -eq $Seconds) {
        return 'Calculating...'
    }

    if ($Seconds -le 0) {
        return 'About now'
    }

    $span = [TimeSpan]::FromSeconds($Seconds)
    if ($span.TotalSeconds -lt 60) {
        return '{0:0}s' -f $span.TotalSeconds
    }
    if ($span.TotalMinutes -lt 60) {
        return '{0:mm\:ss}' -f $span
    }
    if ($span.TotalHours -lt 24) {
        return '{0:hh\:mm}' -f $span
    }
    
    $days = [math]::Floor($span.TotalDays)
    $hours = $span.Hours
    $mins = $span.Minutes
    return "{0:N0}d {1:00}:{2:00}" -f $days, $hours, $mins
}

function Write-ResultsIncremental {
    param(
        [object]$Results
    )
    try {
        $json = $Results | ConvertTo-Json -Depth 5
        $tmp = "$($script:ResultsIncrementalPath).$([guid]::NewGuid().ToString()).tmp"
        $json | Out-File -FilePath $tmp -Encoding utf8 -Force
        Move-Item -Path $tmp -Destination $script:ResultsIncrementalPath -Force
    } catch { }
}

function Write-ProgressSnapshot {
    param(
        [string]$Phase,
        [string]$Message,
        [double]$Percent,
        [string]$Detail,
        [string]$State = 'Running'
    )

    if (-not $script:ProgressStartedAt) {
        $script:ProgressStartedAt = Get-Date
    }

    $safePercent = [math]::Max(0, [math]::Min(100, [math]::Round($Percent, 1)))
    $etaSeconds = $null
    if ($safePercent -gt 0 -and $safePercent -lt 100) {
        $elapsedSeconds = ((Get-Date) - $script:ProgressStartedAt).TotalSeconds
        $etaSeconds = [int][math]::Max(0, [math]::Round($elapsedSeconds * ((100 / $safePercent) - 1), 0))
    }

    $snapshot = [ordered]@{
        Phase      = $Phase
        Message    = $Message
        Detail     = $Detail
        Percent    = $safePercent
        EtaSeconds = $etaSeconds
        EtaText    = (Format-EtaText $etaSeconds)
        State      = $State
        StartedAt  = $script:ProgressStartedAt.ToString('o')
        UpdatedAt  = (Get-Date).ToString('o')
    }

    try {
        $json = $snapshot | ConvertTo-Json -Depth 4
        $tmpSnap = "$($script:ProgressSnapshotPath).$([guid]::NewGuid().ToString()).tmp"
        $json | Out-File -FilePath $tmpSnap -Encoding utf8 -Force
        Move-Item -Path $tmpSnap -Destination $script:ProgressSnapshotPath -Force

        $text = @(
            "Phase: $Phase"
            "Message: $Message"
            "Detail: $Detail"
            ("Percent: {0:0.0}%" -f $safePercent)
            "ETA: $(Format-EtaText $etaSeconds)"
            "State: $State"
            "Updated: $(Get-Date)"
        ) -join "`r`n"
        $tmpText = "$($script:ProgressTextPath).$([guid]::NewGuid().ToString()).tmp"
        $text | Out-File -FilePath $tmpText -Encoding utf8 -Force
        Move-Item -Path $tmpText -Destination $script:ProgressTextPath -Force
    } catch { }
}

function Set-ProgressPhase {
    param(
        [string]$Phase,
        [string]$Message,
        [double]$Percent,
        [string]$Detail = '',
        [string]$State = 'Running'
    )

    Write-ProgressSnapshot -Phase $Phase -Message $Message -Percent $Percent -Detail $Detail -State $State
}

function Complete-Progress {
    param(
        [string]$Phase = 'Complete',
        [string]$Message = 'Diagnostics complete.',
        [string]$Detail = ''
    )

    Write-ProgressSnapshot -Phase $Phase -Message $Message -Percent 100 -Detail $Detail -State 'Completed'
}

function Invoke-Cmd { param([string]$Cmd, [string]$OutName)
    $output = cmd /c "$Cmd" 2>&1
    $output | Out-File -FilePath (Join-Path $LogRoot $OutName) -Encoding utf8 -Force
    return $output
}

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    return (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Add-Score { param([string]$Name, [int]$Points, [string]$Reason)
    $global:Scores[$Name] += $Points
    $global:Reasons[$Name] += @($Reason)
}

function Convert-ToSingleLineText {
    param(
        [object]$Value,
        [int]$MaxLength = 200
    )

    if ($null -eq $Value) { return '' }

    $text = [string]$Value -replace '\r?\n', ' '
    if ($text.Length -gt $MaxLength) {
        return $text.Substring(0, $MaxLength)
    }

    return $text
}

function Get-RecentSystemEvents {
    param([int]$Days = 30)

    try {
        Get-WinEvent -FilterHashtable @{LogName='System'; StartTime=(Get-Date).AddDays(-$Days)} -ErrorAction Stop |
            Sort-Object TimeCreated -Descending
    } catch {
        @()
    }
}

function Invoke-WindowsUpdateMaintenance {
    Write-Section "Windows Update Maintenance" -Silent | Out-Null

    try {
        $usoClient = Join-Path $env:WINDIR 'System32\UsoClient.exe'
        if (Test-Path $usoClient) {
            Start-Process -FilePath $usoClient -ArgumentList 'StartScan' -WindowStyle Hidden -ErrorAction SilentlyContinue | Out-Null
            Start-Process -FilePath $usoClient -ArgumentList 'StartDownload' -WindowStyle Hidden -ErrorAction SilentlyContinue | Out-Null
            Start-Process -FilePath $usoClient -ArgumentList 'StartInstall' -WindowStyle Hidden -ErrorAction SilentlyContinue | Out-Null
        }

        Invoke-Cmd 'powershell -NoProfile -Command "Get-WindowsUpdateLog -ErrorAction SilentlyContinue"' 'windows_update_log.txt' | Out-Null
    } catch { }
}

function Get-SSDHealthDetail {
    <#
    Fetch deep SSD diagnostics: SMART data via storage reliability counters
    #>
    $ssdDetails = @()
    try {
        $physDisks = Get-PhysicalDisk -ErrorAction Stop
        foreach ($disk in $physDisks) {
            $diskInfo = [ordered]@{
                FriendlyName = $disk.FriendlyName
                MediaType = $disk.MediaType
                Size = "{0} GB" -f [math]::Round($disk.Size / 1GB, 2)
                HealthStatus = $disk.HealthStatus
                OperationalStatus = $disk.OperationalStatus
                SerialNumber = ""
                Temperature = "N/A"
                Wear = "N/A"
                ReadErrors = 0
                WriteErrors = 0
                PowerOnHours = "N/A"
                UnsafeShutdowns = 0
            }
            
            # Try to get detailed reliability counters
            if (Get-Command Get-StorageReliabilityCounter -ErrorAction SilentlyContinue) {
                try {
                    $counter = Get-StorageReliabilityCounter -PhysicalDisk $disk
                    if ($counter) {
                        $diskInfo.Temperature = "{0}C" -f $counter.Temperature
                        $diskInfo.Wear = "{0}%" -f $counter.Wear
                        $diskInfo.ReadErrors = $counter.ReadErrorsTotal
                        $diskInfo.WriteErrors = $counter.WriteErrorsTotal
                        $diskInfo.PowerOnHours = $counter.PowerOnHours
                        $diskInfo.UnsafeShutdowns = $counter.UnsafeShutdowns
                    }
                } catch { }
            }
            
            $ssdDetails += [pscustomobject]$diskInfo
        }
    } catch { }
    
    return $ssdDetails
}

function Get-WHEADetails {
    <#
    Deep dive into WHEA (Windows Hardware Error Architecture) events
    WHEA errors indicate memory, CPU, or firmware instability
    #>
    $wheaEvents = @()
    try {
        $events = if ($script:RecentSystemEvents30d) { $script:RecentSystemEvents30d } else { Get-RecentSystemEvents -Days 30 }
        $rawEvents = $events |
            Where-Object { $_.ProviderName -eq 'WHEA-Logger' } |
            Select-Object -First 200
        
        foreach ($event in $rawEvents) {
            $wheaEvents += [pscustomobject]@{
                TimeCreated = $event.TimeCreated
                EventId = $event.Id
                Level = $event.LevelDisplayName
                Message = Convert-ToSingleLineText $event.Message 200
            }
        }
    } catch { }
    
    return $wheaEvents
}

function Get-TDREvents {
    <#
    Timeout Detection and Recovery (TDR) events indicate GPU driver hangs/resets
    #>
    $tdrEvents = @()
    try {
        $events = if ($script:RecentSystemEvents30d) { $script:RecentSystemEvents30d } else { Get-RecentSystemEvents -Days 30 }
        $events = $events |
            Where-Object { 
                $_.ProviderName -match 'Display|nvlddmkm|AMD|Kernel' -and 
                ($_.Id -eq 4101 -or $_.Message -match 'TDR|timeout|recovery|reset')
            } |
            Select-Object -First 200
        
        foreach ($event in $events) {
            $tdrEvents += [pscustomobject]@{
                TimeCreated = $event.TimeCreated
                Provider = $event.ProviderName
                EventId = $event.Id
                Level = $event.LevelDisplayName
                Message = Convert-ToSingleLineText $event.Message 200
            }
        }
    } catch { }
    
    return $tdrEvents
}

function Get-StorageTimeoutEvents {
    <#
    Storage controller timeout/reset events that could indicate SSD or storage subsystem issues
    #>
    $timeoutEvents = @()
    try {
        $ids = @(129, 130, 141, 153, 161, 225, 55, 57)
        $events = if ($script:RecentSystemEvents30d) { $script:RecentSystemEvents30d } else { Get-RecentSystemEvents -Days 30 }
        $events = $events |
            Where-Object { 
                $_.Id -in $ids -or 
                $_.ProviderName -match 'storahci|stornvme|iaStor|volmgr|Disk|Ntfs' 
            } |
            Select-Object -First 100
        
        foreach ($event in $events) {
            $timeoutEvents += [pscustomobject]@{
                TimeCreated = $event.TimeCreated
                Provider = $event.ProviderName
                EventId = $event.Id
                Level = $event.LevelDisplayName
                Message = Convert-ToSingleLineText $event.Message 150
            }
        }
    } catch { }
    
    return $timeoutEvents
}

function Get-UnexpectedRebootEvents {
    <#
    Track unexpected reboots/power events
    #>
    $rebootEvents = @()
    try {
        $ids = @(41, 6008, 1001)
        $events = if ($script:RecentSystemEvents30d) { $script:RecentSystemEvents30d } else { Get-RecentSystemEvents -Days 30 }
        $events = $events |
            Where-Object { $_.Id -in $ids } |
            Select-Object -First 100
        
        foreach ($event in $events) {
            $rebootEvents += [pscustomobject]@{
                TimeCreated = $event.TimeCreated
                EventId = $event.Id
                Level = $event.LevelDisplayName
                Description = if ($event.Id -eq 41) { "Power Loss/Critical Error" } 
                               elseif ($event.Id -eq 6008) { "Unexpected Shutdown" }
                               else { "Unknown" }
            }
        }
    } catch { }
    
    return $rebootEvents
}

# ===== MAIN DIAGNOSTICS =====
if (-not (Test-Admin)) {
    Write-Host 'ERROR: This script requires Administrator privileges.' -ForegroundColor Red
    exit 1
}

Set-ProgressPhase -Phase 'Initialization' -Message 'Preparing diagnostics and writing progress snapshot.' -Percent 1 -Detail 'Starting core analysis'

$global:Scores = [ordered]@{ 
    Storage = 0
    Memory = 0
    GPU = 0
    Firmware = 0
    Driver = 0
    Windows = 0
    Hardware = 0
}

$global:Reasons = [ordered]@{ 
    Storage = @()
    Memory = @()
    GPU = @()
    Firmware = @()
    Driver = @()
    Windows = @()
    Hardware = @()
}

# SYSTEM SNAPSHOT
Set-ProgressPhase -Phase 'System Snapshot' -Message 'Collecting OS, hardware, and storage inventory.' -Percent 8 -Detail 'Reading system details'
Write-Section "System Snapshot" -Silent | Out-Null
$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem
$cpu = Get-CimInstance Win32_Processor
$bios = Get-CimInstance Win32_BIOS
$gpu = Get-CimInstance Win32_VideoController
$vols = Get-Volume | Select-Object DriveLetter, FileSystemLabel, FileSystemType, HealthStatus, DriveType, SizeRemaining, Size

$os, $cs, $cpu, $bios, $gpu | Format-List | Out-String | Save-Text 'system_snapshot.txt'
$vols | Export-Csv (Join-Path $LogRoot 'volumes.csv') -NoTypeInformation

Save-Text 'snapshot_summary.txt' @"
BIOS: $($bios.SMBIOSBIOSVersion) | Release: $($bios.ReleaseDate)
OS: $($os.Caption) Build $($os.BuildNumber)
CPU: $($cpu.Name) | Cores: $($cpu.NumberOfCores)
RAM: $([math]::Round($cs.TotalPhysicalMemory / 1GB, 0)) GB
Uptime: $([math]::Round(((Get-Date) - $os.LastBootUpTime).TotalDays, 1)) days
GPU(s): $(($gpu | Select-Object -ExpandProperty Name) -join '; ')
"@

# WINDOWS INTEGRITY
Set-ProgressPhase -Phase 'Windows Integrity Checks' -Message 'Running SFC and DISM repair checks.' -Percent 20 -Detail 'sfc /scannow'
Write-Section "Windows Integrity Checks" -Silent | Out-Null
# Run SFC non-blocking and emit snapshots while it runs to avoid GUI stall
try {
    $sfcOut = Join-Path $LogRoot 'sfc.txt'
    $sfcCmd = "/c sfc /scannow > `"$sfcOut`" 2>&1"
    $sfcProc = Start-Process -FilePath $env:COMSPEC -ArgumentList $sfcCmd -WindowStyle Hidden -PassThru -ErrorAction Stop
    while (-not $sfcProc.HasExited) {
        Set-ProgressPhase -Phase 'Windows Integrity Checks' -Message 'sfc /scannow (running)' -Percent 20 -Detail 'sfc /scannow'
        Start-Sleep -Seconds 8
    }
} catch {
    Invoke-Cmd 'sfc /scannow' 'sfc.txt' | Out-Null
}
Set-ProgressPhase -Phase 'Windows Integrity Checks' -Message 'Checking component store health.' -Percent 22 -Detail 'DISM /Online /Cleanup-Image /CheckHealth'
try {
    $dismChecks = @(
        @{ Cmd = 'DISM /Online /Cleanup-Image /CheckHealth'; Out = 'dism_checkhealth.txt'; Pct = 22 }
        @{ Cmd = 'DISM /Online /Cleanup-Image /ScanHealth'; Out = 'dism_scanhealth.txt'; Pct = 24 }
        @{ Cmd = 'DISM /Online /Cleanup-Image /RestoreHealth'; Out = 'dism_restorehealth.txt'; Pct = 27 }
        @{ Cmd = 'DISM /Online /Cleanup-Image /AnalyzeComponentStore'; Out = 'dism_componentstore.txt'; Pct = 30 }
    )

    foreach ($d in $dismChecks) {
        Set-ProgressPhase -Phase 'Windows Integrity Checks' -Message $d.Cmd -Percent $d.Pct -Detail $d.Cmd
        $outFile = Join-Path $LogRoot $($d.Out)
        $cmd = "/c $($d.Cmd) > `"$outFile`" 2>&1"
        $proc = Start-Process -FilePath $env:COMSPEC -ArgumentList $cmd -WindowStyle Hidden -PassThru -ErrorAction Stop
        while (-not $proc.HasExited) {
            Set-ProgressPhase -Phase 'Windows Integrity Checks' -Message "$($d.Cmd) (running)" -Percent $d.Pct -Detail $d.Cmd
            Start-Sleep -Seconds 10
        }
    }
} catch {
    # fallback to blocking calls if Start-Process fails
    Invoke-Cmd 'DISM /Online /Cleanup-Image /CheckHealth' 'dism_checkhealth.txt' | Out-Null
    Invoke-Cmd 'DISM /Online /Cleanup-Image /ScanHealth' 'dism_scanhealth.txt' | Out-Null
    Invoke-Cmd 'DISM /Online /Cleanup-Image /RestoreHealth' 'dism_restorehealth.txt' | Out-Null
    Invoke-Cmd 'DISM /Online /Cleanup-Image /AnalyzeComponentStore' 'dism_componentstore.txt' | Out-Null
}

# DETAILED SSD HEALTH
Set-ProgressPhase -Phase 'Deep SSD & Storage Analysis' -Message 'Reviewing disk health and wear signals.' -Percent 40 -Detail 'Storage reliability counters'
Write-Section "Deep SSD & Storage Analysis" -Silent | Out-Null
$ssdHealth = Get-SSDHealthDetail
$ssdHealth | Export-Csv (Join-Path $LogRoot 'ssd_health_detailed.csv') -NoTypeInformation
$ssdHealth | Format-Table -AutoSize | Out-String | Save-Text 'ssd_health_report.txt'

# Write incremental results
$incrementalResults = @{ SSDs = $ssdHealth }
Write-ResultsIncremental $incrementalResults

# Cache event logs once so the downstream analyses do not rescan the System log repeatedly.
$script:RecentSystemEvents30d = Get-RecentSystemEvents -Days 30
$script:RecentSystemEvents14d = Get-RecentSystemEvents -Days 14

# DISK CHECKS
Set-ProgressPhase -Phase 'Disk Checks' -Message 'Scanning volumes for filesystem and dirty-bit issues.' -Percent 46 -Detail 'chkdsk and fsutil checks'
$fixedDriveLetters = $vols | Where-Object { $_.DriveType -eq 'Fixed' -and $_.DriveLetter } | 
    Select-Object -ExpandProperty DriveLetter -Unique
foreach ($driveLetter in $fixedDriveLetters) {
    try {
        $outFile = Join-Path $LogRoot ("chkdsk_{0}_scan.txt" -f $driveLetter)
        $cmd = "/c chkdsk $driveLetter`: /scan > `"$outFile`" 2>&1"
        $proc = Start-Process -FilePath $env:COMSPEC -ArgumentList $cmd -WindowStyle Hidden -PassThru -ErrorAction Stop

        # Poll the running chkdsk and emit frequent progress snapshots so the GUI/watchdog stays informed
        while (-not $proc.HasExited) {
            $driveIndex = [array]::IndexOf($fixedDriveLetters, $driveLetter) + 1
            $totalDrives = ($fixedDriveLetters | Measure-Object).Count
            $pct = 46 + ([math]::Round(($driveIndex / [math]::Max(1, $totalDrives)) * 8, 1))
            Set-ProgressPhase -Phase 'Disk Checks' -Message "Scanning $driveLetter`: (chkdsk running)" -Percent $pct -Detail "chkdsk $driveLetter`: /scan"
            Start-Sleep -Seconds 12
        }
    } catch {
        # fallback to blocking call and capture output if Start-Process or redirection isn't available
        Invoke-Cmd "chkdsk $driveLetter`: /scan" "chkdsk_$($driveLetter)_scan.txt" | Out-Null
    }
    Invoke-Cmd "fsutil dirty query $driveLetter`:" "dirty_$($driveLetter).txt" | Out-Null
}

# WHEA ERROR ANALYSIS
Set-ProgressPhase -Phase 'WHEA Error Deep Dive' -Message 'Checking hardware error events.' -Percent 54 -Detail 'WHEA-Logger events'
Write-Section "WHEA Error Deep Dive" -Silent | Out-Null
$wheaEvents = Get-WHEADetails
$wheaEvents | Export-Csv (Join-Path $LogRoot 'whea_events_detailed.csv') -NoTypeInformation
$wheaCount = $wheaEvents.Count

# Write incremental results
$incrementalResults = @{ SSDs = $ssdHealth; WHEAEvents = $wheaEvents }
Write-ResultsIncremental $incrementalResults

# GPU/DRIVER TIMEOUT EVENTS
Set-ProgressPhase -Phase 'GPU Driver Timeout Analysis' -Message 'Inspecting GPU timeout and hang patterns.' -Percent 60 -Detail 'TDR event scan'
Write-Section "GPU Driver Timeout Analysis" -Silent | Out-Null
$tdrEvents = Get-TDREvents
$tdrEvents | Export-Csv (Join-Path $LogRoot 'tdr_events_detailed.csv') -NoTypeInformation
$tdrCount = $tdrEvents.Count

# Write incremental results
$incrementalResults = @{ SSDs = $ssdHealth; WHEAEvents = $wheaEvents; TDREvents = $tdrEvents }
Write-ResultsIncremental $incrementalResults

# STORAGE TIMEOUT EVENTS
Set-ProgressPhase -Phase 'Storage Controller Event Analysis' -Message 'Correlating storage controller timeouts.' -Percent 66 -Detail 'Disk and controller events'
Write-Section "Storage Controller Event Analysis" -Silent | Out-Null
$storageTimeouts = Get-StorageTimeoutEvents
$storageTimeouts | Export-Csv (Join-Path $LogRoot 'storage_timeout_events.csv') -NoTypeInformation

# Write incremental results
$incrementalResults = @{ SSDs = $ssdHealth; WHEAEvents = $wheaEvents; TDREvents = $tdrEvents; StorageTimeouts = $storageTimeouts }
Write-ResultsIncremental $incrementalResults

# REBOOT/CRASH EVENTS
Set-ProgressPhase -Phase 'Unexpected Reboot/Crash Events' -Message 'Looking for crash and reset evidence.' -Percent 72 -Detail 'Kernel-Power and 6008 events'
Write-Section "Unexpected Reboot/Crash Events" -Silent | Out-Null
$rebootEvents = Get-UnexpectedRebootEvents
$rebootEvents | Export-Csv (Join-Path $LogRoot 'reboot_events.csv') -NoTypeInformation

# Write incremental results
$incrementalResults = @{ SSDs = $ssdHealth; WHEAEvents = $wheaEvents; TDREvents = $tdrEvents; StorageTimeouts = $storageTimeouts; RebootEvents = $rebootEvents }
Write-ResultsIncremental $incrementalResults

# GENERAL SYSTEM EVENTS
Set-ProgressPhase -Phase 'General Event Correlation' -Message 'Filtering the recent system event stream.' -Percent 78 -Detail 'Cross-checking storage, display, and reboot events'
$events = $script:RecentSystemEvents14d |
    Where-Object { 
        $_.Id -in 7,11,15,51,55,57,153,129,130,141,161,219,225,41,6008,1001,4101 -or 
        $_.ProviderName -match 'Disk|Ntfs|storahci|stornvme|nvme|WHEA|Display|volmgr|iaStor|Kernel-Power|nvlddmkm'
    }
$events | Select-Object TimeCreated, Id, ProviderName, LevelDisplayName, Message | 
    Export-Csv (Join-Path $LogRoot 'system_events_14d.csv') -NoTypeInformation

$storageCount = ($events | Where-Object { $_.ProviderName -match 'Disk|Ntfs|storahci|stornvme|nvme|volmgr|iaStor' }).Count
$gpuCount = ($events | Where-Object { $_.Id -eq 4101 -or $_.ProviderName -match 'Display|nvlddmkm' }).Count
$kpowerCount = ($events | Where-Object { $_.Id -eq 41 -or $_.ProviderName -match 'Kernel-Power' }).Count
$unexpectedCount = ($events | Where-Object { $_.Id -eq 6008 }).Count

# DRIVERS & FIRMWARE
Set-ProgressPhase -Phase 'Drivers & Updates' -Message 'Collecting driver and update history.' -Percent 84 -Detail 'PnP drivers and hotfixes'
Write-Section "Drivers & Updates" -Silent | Out-Null
Get-CimInstance Win32_PnPSignedDriver | Select-Object DeviceName, DriverVersion, Manufacturer, DriverDate | 
    Export-Csv (Join-Path $LogRoot 'drivers.csv') -NoTypeInformation
Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object HotFixID, Description, InstalledOn | 
    Export-Csv (Join-Path $LogRoot 'hotfixes.csv') -NoTypeInformation

$gpuDriver = $gpu | Select-Object -First 1
$driverAge = $null
if ($gpuDriver.DriverDate) {
    $driverAge = [math]::Round(((Get-Date) - ([datetime]$gpuDriver.DriverDate)).TotalDays, 0)
}

$biosAgeDays = $null
if ($bios.ReleaseDate) {
    $biosAgeDays = [math]::Round(((Get-Date) - ([datetime]$bios.ReleaseDate)).TotalDays, 0)
}

# PERFORMANCE
Set-ProgressPhase -Phase 'Performance Snapshot' -Message 'Capturing CPU, memory, and disk pressure.' -Percent 89 -Detail 'Process and disk queue sampling'
Write-Section "Performance Snapshot" -Silent | Out-Null
Get-Process | Sort-Object CPU -Descending | Select-Object -First 15 Name, Id, CPU, WorkingSet64 | 
    Export-Csv (Join-Path $LogRoot 'top_cpu.csv') -NoTypeInformation
Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 15 Name, Id, CPU, WorkingSet64 | 
    Export-Csv (Join-Path $LogRoot 'top_memory.csv') -NoTypeInformation

try {
    $typeOut = Join-Path $LogRoot 'disk_queue.txt'
    $typeProc = Start-Process -FilePath 'typeperf' -ArgumentList '\\PhysicalDisk(_Total)\\Avg. Disk Queue Length','-sc','1' -RedirectStandardOutput $typeOut -RedirectStandardError $typeOut -NoNewWindow -PassThru -ErrorAction Stop
    while (-not $typeProc.HasExited) {
        Set-ProgressPhase -Phase 'Performance Snapshot' -Message 'Collecting disk queue metrics' -Percent 89 -Detail 'typeperf sampling'
        Start-Sleep -Seconds 4
    }
} catch {
    Invoke-Cmd 'typeperf "\\PhysicalDisk(_Total)\\Avg. Disk Queue Length" -sc 1' 'disk_queue.txt' | Out-Null
}

# ===== DIAGNOSTIC SCORING =====
Set-ProgressPhase -Phase 'Diagnostic Scoring' -Message 'Ranking findings and preparing the summary.' -Percent 94 -Detail 'Scoring hardware and software signals'
if ($storageCount -ge 20) { Add-Score Storage 40 "High storage event volume ($storageCount events)" }
elseif ($storageCount -ge 5) { Add-Score Storage 20 "Moderate storage event volume ($storageCount events)" }

$highTempDrives = $ssdHealth | Where-Object { $_.Temperature -match '^\d+' -and [int]($_.Temperature -replace '[^\d]') -ge 55 }
if ($highTempDrives) { Add-Score Hardware 25 "SSD(s) running hot: $(($highTempDrives.FriendlyName) -join ', ')" }

$wornDrives = $ssdHealth | Where-Object { $_.Wear -match '^\d+' -and [int]($_.Wear -replace '[^\d]') -ge 80 }
if ($wornDrives) { Add-Score Storage 30 "High wear levels detected on: $(($wornDrives.FriendlyName) -join ', ')" }

$errorDrives = $ssdHealth | Where-Object { $_.ReadErrors -gt 0 -or $_.WriteErrors -gt 0 }
if ($errorDrives) { Add-Score Storage 35 "Media errors on: $(($errorDrives.FriendlyName) -join ', ')" }

if ($wheaCount -ge 10) { 
    Add-Score Memory 35 "Frequent WHEA errors ($wheaCount events) - possible RAM/CPU/firmware issue"
    Add-Score Hardware 20 "WHEA frequency suggests hardware instability"
}
elseif ($wheaCount -ge 1) { 
    Add-Score Memory 15 "WHEA errors present ($wheaCount events)"
}

if ($tdrCount -ge 3) {
    Add-Score GPU 40 "GPU driver timeout pattern ($tdrCount TDR events) - driver hang/crash risk"
    Add-Score Driver 25 "GPU driver stability issues"
}
elseif ($tdrCount -ge 1) {
    Add-Score GPU 20 "GPU driver timeout evidence ($tdrCount TDR events)"
}

if ($null -ne $driverAge -and $driverAge -ge 365) {
    Add-Score Driver 20 "GPU driver very old ($driverAge days)"
}
elseif ($null -ne $driverAge -and $driverAge -ge 180) {
    Add-Score Driver 10 "GPU driver aging ($driverAge days)"
}

if ($null -ne $biosAgeDays -and $biosAgeDays -ge 730) {
    Add-Score Firmware 25 "BIOS is very outdated ($biosAgeDays days old)"
}
elseif ($null -ne $biosAgeDays -and $biosAgeDays -ge 365) {
    Add-Score Firmware 15 "BIOS could use an update ($biosAgeDays days old)"
}

if ($unexpectedCount -ge 2 -or $kpowerCount -ge 2) {
    Add-Score Windows 25 "Multiple unexpected reboots/resets detected ($unexpectedCount/$kpowerCount events)"
}
elseif ($unexpectedCount -ge 1 -or $kpowerCount -ge 1) {
    Add-Score Windows 10 "Unexpected reboot/reset event(s) detected"
}

if (($events | Where-Object { $_.Id -in 129,130,141,153,161,225 }).Count -ge 3) {
    Add-Score Storage 20 "Storage controller timeout/reset pattern detected"
}

# ===== RANKED REPORT =====
Set-ProgressPhase -Phase 'Ranked Report' -Message 'Exporting the ranked diagnosis report.' -Percent 97 -Detail 'Writing analysis_ranked.txt'
$ranked = $global:Scores.GetEnumerator() | Sort-Object Value -Descending
$top = $ranked | Select-Object -First 1

$report = New-Object System.Collections.Generic.List[string]
$report.Add('=== DIAGNOSTIC RESULTS ===')
$report.Add("Generated: $(Get-Date)")
$report.Add('')
$report.Add('RANKED DIAGNOSIS (by severity):')
foreach ($item in $ranked) {
    $reasonText = if ($global:Reasons[$item.Key].Count -gt 0) { 
        ($global:Reasons[$item.Key] -join '; ') 
    } else { 
        'No issues detected' 
    }
    $report.Add(("{0,-15} {1:3} pts  {2}" -f $item.Key, $item.Value, $reasonText))
}
$report.Add('')
$report.Add(('MOST LIKELY CULPRIT: {0} ({1} points)' -f $top.Key, $top.Value))
$report.Add('')
$report.Add(('SSD Count: {0} | WHEA Events: {1} | GPU TDR Events: {2} | Unexpected Reboots: {3}' -f $ssdHealth.Count, $wheaCount, $tdrCount, $unexpectedCount))
$report.Add(('Storage Timeout Events: {0}' -f $storageTimeouts.Count))

Save-Text 'analysis_ranked.txt' ($report -join "`r`n")

# ===== OPTIONAL REPAIRS =====
if ($RunRepair) {
    Set-ProgressPhase -Phase 'Applying Windows Repairs' -Message 'Resetting update services and component caches.' -Percent 98 -Detail 'Windows repair workflow'
    Write-Section "Applying Windows Repairs" -Silent | Out-Null
    Stop-Service wuauserv, bits, cryptsvc, msiserver -Force -ErrorAction SilentlyContinue
    Remove-Item 'C:\Windows\SoftwareDistribution\Download\*' -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item 'C:\Windows\SoftwareDistribution\DataStore\*' -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item 'C:\Windows\System32\catroot2\*' -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service cryptsvc, bits, wuauserv, msiserver -ErrorAction SilentlyContinue
    try {
        $outFile = Join-Path $LogRoot 'dism_restorehealth_after_reset.txt'
        $cmd = "/c DISM /Online /Cleanup-Image /RestoreHealth > `"$outFile`" 2>&1"
        $proc = Start-Process -FilePath $env:COMSPEC -ArgumentList $cmd -WindowStyle Hidden -PassThru -ErrorAction Stop
        while (-not $proc.HasExited) {
            Set-ProgressPhase -Phase 'Applying Windows Repairs' -Message 'DISM RestoreHealth (running)' -Percent 98 -Detail 'DISM /RestoreHealth'
            Start-Sleep -Seconds 10
        }
    } catch {
        Invoke-Cmd 'DISM /Online /Cleanup-Image /RestoreHealth' 'dism_restorehealth_after_reset.txt' | Out-Null
    }
}

if ($RunTdrTweak) {
    Set-ProgressPhase -Phase 'Applying GPU TDR Adjustment' -Message 'Increasing GPU timeout tolerance.' -Percent 99 -Detail 'TdrDelay registry adjustment'
    Write-Section "Applying GPU TDR Adjustment" -Silent | Out-Null
    New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' -Name 'TdrDelay' -Value 10 -PropertyType DWord -Force | Out-Null
}

if ($RunNetworkReset) {
    Set-ProgressPhase -Phase 'Resetting Network Stack' -Message 'Refreshing TCP/IP and Winsock state.' -Percent 99 -Detail 'Network reset workflow'
    Write-Section "Resetting Network Stack" -Silent | Out-Null
    Invoke-Cmd 'netsh winsock reset' 'winsock_reset.txt' | Out-Null
    Invoke-Cmd 'netsh int ip reset' 'ip_reset.txt' | Out-Null
}

if ($RunMemDiag) {
    Set-ProgressPhase -Phase 'Launching Memory Diagnostics' -Message 'Starting Windows Memory Diagnostic.' -Percent 99.5 -Detail 'mdsched.exe'
    Write-Section "Launching Memory Diagnostics" -Silent | Out-Null
    Start-Process mdsched.exe -ErrorAction SilentlyContinue
}

if ($RunDefenderScan) {
    Set-ProgressPhase -Phase 'Starting Full Defender Scan' -Message 'Launching Microsoft Defender full scan.' -Percent 99.7 -Detail 'Start-MpScan FullScan'
    Write-Section "Starting Full Defender Scan" -Silent | Out-Null
    Start-MpScan -ScanType FullScan -ErrorAction SilentlyContinue
}

Complete-Progress -Message 'Diagnostics and requested actions complete.' -Detail 'Final results written to disk'

if ($RunWindowsUpdate) {
    Invoke-WindowsUpdateMaintenance
}

# ===== EXPORT RESULTS =====
$results = [ordered]@{
    LogPath = $LogRoot
    TopIssue = $top.Key
    TopIssueScore = $top.Value
    Timestamp = Get-Date
    SSDs = $ssdHealth
    WHEAEvents = $wheaEvents
    TDREvents = $tdrEvents
    RebootEvents = $rebootEvents
    StorageTimeouts = $storageTimeouts
    AllScores = $global:Scores
}

$results | Export-Clixml (Join-Path $LogRoot 'diagnostic_results.xml') -Force

Write-Host "Diagnostics complete. Logs saved to: $LogRoot" -ForegroundColor Green
Write-Host "Most likely issue: $($top.Key) ($($top.Value) points)" -ForegroundColor Yellow

exit 0
