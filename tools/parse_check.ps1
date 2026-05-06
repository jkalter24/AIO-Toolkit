$files = @('Cipher-System-Check-v7-Core.ps1','Cipher-System-Check-v7-GUI.ps1')
$root = Split-Path -Parent $PSScriptRoot
foreach ($f in $files) {
    $path = Join-Path $root $f
    $t = $null; $e = $null
    [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$t, [ref]$e) | Out-Null
    if ($e) {
        Write-Host ("ERROR in {0}:" -f $f)
        $e | ForEach-Object { Write-Host $_.Message }
        exit 1
    } else {
        Write-Host ("{0} OK" -f $f)
    }
}
