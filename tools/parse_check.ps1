Set-StrictMode -Version Latest

$files = @(
    'Cipher-System-Check-v7.ps1'
    'Cipher-System-Check-v7-Core.ps1'
    'Cipher-System-Check-v7-GUI.ps1'
    'tools/parse_check.ps1'
    'fix_glyphs.ps1'
)

$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$hadErrors = $false

foreach ($f in $files) {
    $path = Join-Path $root $f
    if (-not (Test-Path $path)) {
        Write-Host "Missing file: $f" -ForegroundColor Yellow
        continue
    }

    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors) | Out-Null

    if ($errors.Count -gt 0) {
        $hadErrors = $true
        Write-Host "Parse errors in ${f}:" -ForegroundColor Red
        foreach ($err in $errors) {
            $line = if ($err.Extent) { $err.Extent.StartLineNumber } else { 0 }
            $msg = if ($err.Message) { $err.Message } else { 'Unknown parse error' }
            Write-Host ("  L{0}: {1}" -f $line, $msg) -ForegroundColor Red
        }
        continue
    }

    Write-Host "OK: $f" -ForegroundColor Green
}

if ($hadErrors) {
    exit 1
}

Write-Host 'Parse check passed for all scanned scripts.' -ForegroundColor Green
