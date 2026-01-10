<#
.SYNOPSIS
    Show quick reference for G203 LED control

.DESCRIPTION
    Displays available colors, effects, and usage examples

.EXAMPLE
    Show-G203Help
#>
function Show-G203Help {
    [CmdletBinding()]
    param()

    Write-Host "`n" + ("=" * 70) -ForegroundColor Cyan
    Write-Host "G203 LIGHTSYNC LED Control - Quick Reference" -ForegroundColor Cyan
    Write-Host "=" * 70 -ForegroundColor Cyan

    Write-Host "`nAVAILABLE COLORS:" -ForegroundColor Yellow
    Write-Host "  Named: " -NoNewline
    Write-Host "Black, White, Red, Green, Blue, Yellow, Cyan, Magenta" -ForegroundColor White
    Write-Host "         Orange, Purple, Pink, Lime, Teal, Navy, Maroon, Gray" -ForegroundColor White
    Write-Host "         Silver, Gold, Brown, Violet, Indigo" -ForegroundColor White
    Write-Host "  Hex:   #RRGGBB (e.g., #FF0000 for red)" -ForegroundColor White
    Write-Host "  RGB:   -Red 255 -Green 0 -Blue 255" -ForegroundColor White

    Write-Host "`nAVAILABLE EFFECTS:" -ForegroundColor Yellow
    Write-Host "  Fixed   " -NoNewline; Write-Host "- Solid color" -ForegroundColor White
    Write-Host "  Breathe " -NoNewline; Write-Host "- Pulsing/breathing effect" -ForegroundColor White
    Write-Host "  Cycle   " -NoNewline; Write-Host "- Rainbow color cycle" -ForegroundColor White

    Write-Host "`nBASIC COMMANDS:" -ForegroundColor Yellow
    Write-Host "  Connect-G203Mouse              " -NoNewline; Write-Host "# Connect to mouse" -ForegroundColor Gray
    Write-Host "  Set-G203Color 'Red'            " -NoNewline; Write-Host "# Solid color" -ForegroundColor Gray
    Write-Host "  Set-G203Color '#FF00FF'        " -NoNewline; Write-Host "# Hex color (magenta)" -ForegroundColor Gray
    Write-Host "  Set-G203Brightness 50          " -NoNewline; Write-Host "# 50% brightness" -ForegroundColor Gray
    Write-Host "  Disconnect-G203Mouse           " -NoNewline; Write-Host "# Disconnect" -ForegroundColor Gray

    Write-Host "`nEFFECT COMMANDS:" -ForegroundColor Yellow
    Write-Host "  # Breathing effect" -ForegroundColor Gray
    Write-Host "  Set-G203Effect Breathe -Color 'Blue' -Speed 3000"
    Write-Host ""
    Write-Host "  # Rainbow cycle" -ForegroundColor Gray
    Write-Host "  Set-G203Effect Cycle -Speed 8000"
    Write-Host ""
    Write-Host "  # Solid color (alternative)" -ForegroundColor Gray
    Write-Host "  Set-G203Effect Fixed -Color 'Purple'"

    Write-Host "`nPARAMETERS:" -ForegroundColor Yellow
    Write-Host "  -Color      " -NoNewline; Write-Host "Any named color, hex (#RRGGBB), or -Red/-Green/-Blue" -ForegroundColor White
    Write-Host "  -Speed      " -NoNewline; Write-Host "1000-65535 milliseconds (lower = faster)" -ForegroundColor White
    Write-Host "  -Brightness " -NoNewline; Write-Host "0-100 percent" -ForegroundColor White

    Write-Host "`nEXAMPLES:" -ForegroundColor Yellow
    Write-Host "  # Quick color change" -ForegroundColor Gray
    Write-Host "  Connect-G203Mouse; Set-G203Color 'Cyan'; Disconnect-G203Mouse"
    Write-Host ""
    Write-Host "  # Gaming mode (breathing red)" -ForegroundColor Gray
    Write-Host "  Connect-G203Mouse"
    Write-Host "  Set-G203Effect Breathe -Color '#FF0000' -Speed 2000"
    Write-Host "  Set-G203Brightness 90"
    Write-Host ""
    Write-Host "  # Party mode (fast rainbow)" -ForegroundColor Gray
    Write-Host "  Connect-G203Mouse"
    Write-Host "  Set-G203Effect Cycle -Speed 3000"

    Write-Host "`nMORE HELP:" -ForegroundColor Yellow
    Write-Host "  Get-Help Set-G203Color -Full" -ForegroundColor White
    Write-Host "  Get-Help Set-G203Effect -Examples" -ForegroundColor White
    Write-Host "  Get-Command -Module G20LED" -ForegroundColor White

    Write-Host "`n" + ("=" * 70) -ForegroundColor Cyan
    Write-Host ""
}
