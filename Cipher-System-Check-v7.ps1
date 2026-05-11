# Cipher System Check v7 - Unified Entrypoint
# Official entry script for GUI and automation modes.

[CmdletBinding()]
param(
    [ValidateSet('Gui', 'Core', 'Test')]
    [string]$Mode = 'Gui',

    [switch]$RunRepair,
    [switch]$RunNetworkReset,
    [switch]$RunTdrTweak,
    [switch]$RunMemDiag,
    [switch]$RunDefenderScan,
    [switch]$RunWindowsUpdate,
    [switch]$QuietMode,
    [switch]$TestMode,

    [switch]$NoElevate
)

$ErrorActionPreference = 'Stop'

function Test-IsAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($id)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Resolve-PowerShellHost {
    $candidates = @()
    if ($PSHOME) {
        $candidates += (Join-Path $PSHOME 'powershell.exe')
        $candidates += (Join-Path $PSHOME 'pwsh.exe')
        $candidates += (Join-Path $PSHOME 'pwsh')
    }

    $preferred = if ($PSVersionTable.PSEdition -eq 'Core') { 'pwsh' } else { 'powershell.exe' }
    $resolvedPreferred = Get-Command $preferred -ErrorAction SilentlyContinue
    if ($resolvedPreferred) { $candidates += $resolvedPreferred.Source }

    $resolvedFallback = Get-Command powershell.exe -ErrorAction SilentlyContinue
    if ($resolvedFallback) { $candidates += $resolvedFallback.Source }

    foreach ($candidate in ($candidates | Where-Object { $_ } | Select-Object -Unique)) {
        if (Test-Path $candidate) { return $candidate }
    }

    throw 'Unable to find powershell.exe or pwsh for relaunch.'
}

function Ensure-Elevated {
    param([string[]]$ForwardedArgs)

    if (Test-IsAdmin) { return }
    if ($NoElevate) {
        throw 'Administrator privileges are required for this mode. Relaunch elevated or omit -NoElevate.'
    }

    $hostExe = Resolve-PowerShellHost
    $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"{0}"' -f $PSCommandPath)) + $ForwardedArgs + @('-NoElevate')
    Start-Process -FilePath $hostExe -ArgumentList $argList -Verb RunAs | Out-Null
    exit 0
}

function Invoke-GuiMode {
    param([bool]$GuiTestMode)

    $guiScript = Join-Path $PSScriptRoot 'Cipher-System-Check-v7-GUI.ps1'
    if (-not (Test-Path $guiScript)) {
        throw "GUI script not found at $guiScript"
    }

    $guiArgs = @('-NoProfile', '-STA', '-ExecutionPolicy', 'Bypass', '-File', ('"{0}"' -f $guiScript))
    if ($GuiTestMode) {
        $guiArgs += '-TestMode'
    }

    $hostExe = Resolve-PowerShellHost
    $process = Start-Process -FilePath $hostExe -ArgumentList $guiArgs -Wait -PassThru
    exit $process.ExitCode
}

function Invoke-CoreMode {
    $coreScript = Join-Path $PSScriptRoot 'Cipher-System-Check-v7-Core.ps1'
    if (-not (Test-Path $coreScript)) {
        throw "Core script not found at $coreScript"
    }

    $coreArgs = @()
    if ($RunRepair) { $coreArgs += '-RunRepair' }
    if ($RunNetworkReset) { $coreArgs += '-RunNetworkReset' }
    if ($RunTdrTweak) { $coreArgs += '-RunTdrTweak' }
    if ($RunMemDiag) { $coreArgs += '-RunMemDiag' }
    if ($RunDefenderScan) { $coreArgs += '-RunDefenderScan' }
    if ($RunWindowsUpdate) { $coreArgs += '-RunWindowsUpdate' }
    if ($QuietMode) { $coreArgs += '-QuietMode' }
    if ($TestMode -or $Mode -eq 'Test') { $coreArgs += '-TestMode' }

    & $coreScript @coreArgs
    exit $LASTEXITCODE
}

try {
    switch ($Mode) {
        'Gui' {
            Ensure-Elevated -ForwardedArgs @('-Mode', 'Gui')
            Invoke-GuiMode -GuiTestMode:$TestMode
        }
        'Core' {
            $forward = @('-Mode', 'Core')
            if ($RunRepair) { $forward += '-RunRepair' }
            if ($RunNetworkReset) { $forward += '-RunNetworkReset' }
            if ($RunTdrTweak) { $forward += '-RunTdrTweak' }
            if ($RunMemDiag) { $forward += '-RunMemDiag' }
            if ($RunDefenderScan) { $forward += '-RunDefenderScan' }
            if ($RunWindowsUpdate) { $forward += '-RunWindowsUpdate' }
            if ($QuietMode) { $forward += '-QuietMode' }
            if ($TestMode) { $forward += '-TestMode' }
            Ensure-Elevated -ForwardedArgs $forward
            Invoke-CoreMode
        }
        'Test' {
            Ensure-Elevated -ForwardedArgs @('-Mode', 'Test')
            $TestMode = $true
            Invoke-CoreMode
        }
    }
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
