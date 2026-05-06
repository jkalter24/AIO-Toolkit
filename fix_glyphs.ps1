# Remove problematic Segoe MDL2 glyph elements from GUI
$file = 'c:\Users\jkalt\Documents\Projects\AIO TOOLKIT\Cipher-System-Check-v7-GUI.ps1'
$content = Get-Content $file -Raw

# Use regex to remove the Segoe MDL2 TextBlock elements
# Pattern: <TextBlock FontFamily="Segoe MDL2 Assets" Text="..." Margin="..." FontSize="14"/>
$pattern = '<TextBlock FontFamily="Segoe MDL2 Assets" Text="[^"]*" Margin="[^"]*" FontSize="14"\s*/>'
$content = $content -replace $pattern, ''

# Clean up any double spacing that may result
$content = $content -replace '\s{2,}', ' '

Set-Content $file -Value $content -NoNewline
Write-Host 'Removed Segoe MDL2 glyph elements successfully'
