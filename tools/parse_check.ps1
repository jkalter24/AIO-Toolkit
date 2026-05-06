$files = @('Cipher-System-Check-v7-Core.ps1', 'Cipher-System-Check-v7-GUI.ps1')
$root = Resolve-Path (Join-Path $PSScriptRoot '..')
foreach ($f in $files) {
    $path = Join-Path $root $f
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors) | Out-Null
    if ($errors.Count -gt 0) {
        Write-Host "Parse errors in ${f}:" -ForegroundColor Red
        $errors | Format-List | Out-String | Write-Host
        exit 1
    }
    Write-Host "OK: $f"
}
