# Remove problematic Segoe MDL2 glyph elements from the local GUI script.
$file = Join-Path $PSScriptRoot 'Cipher-System-Check-v7-GUI.ps1'
if (-not (Test-Path $file)) {
    throw "GUI script not found at $file"
}

$content = Get-Content $file -Raw

# Remove FontFamily="Segoe MDL2 Assets" attributes and any empty TextBlocks left behind.
$content = $content -replace ' FontFamily="Segoe MDL2 Assets"', ''
$content = $content -replace '<TextBlock\s+Text="[^"]*"\s+FontSize="\d+"\s+Margin="[^"]*"\s*/>', ''

Set-Content $file $content -Encoding UTF8
Write-Host "Glyph cleanup complete: $file"
