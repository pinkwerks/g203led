<#
.SYNOPSIS
    Set solid color on G203 mouse

.DESCRIPTION
    Sets the G203 LED to a solid color. Accepts hex color codes, named colors,
    or individual RGB component values.

.PARAMETER Color
    Color in hex format (#RRGGBB or RRGGBB) or named color (Red, Blue, Green, etc.)

.PARAMETER Red
    Red component value (0-255). Use with -Green and -Blue parameters.

.PARAMETER Green
    Green component value (0-255). Use with -Red and -Blue parameters.

.PARAMETER Blue
    Blue component value (0-255). Use with -Red and -Green parameters.

.EXAMPLE
    Set-G203Color -Color "#FF0000"
    Sets mouse to red using hex code

.EXAMPLE
    Set-G203Color -Color "Blue"
    Sets mouse to blue using named color

.EXAMPLE
    Set-G203Color -Red 255 -Green 0 -Blue 255
    Sets mouse to magenta using RGB values

.EXAMPLE
    Set-G203Color "Cyan"
    Sets mouse to cyan (positional parameter)

.NOTES
    Requires active connection via Connect-G203Mouse.
    Available named colors: Black, White, Red, Green, Blue, Yellow, Cyan, Magenta,
    Orange, Purple, Pink, Lime, Teal, Navy, Maroon, Gray, Silver, Gold, Brown,
    Violet, Indigo
#>
function Set-G203Color {
    [CmdletBinding(DefaultParameterSetName = 'ByColorString')]
    param(
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'ByColorString')]
        [string]$Color,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByRGB')]
        [ValidateRange(0, 255)]
        [byte]$Red,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByRGB')]
        [ValidateRange(0, 255)]
        [byte]$Green,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByRGB')]
        [ValidateRange(0, 255)]
        [byte]$Blue
    )

    # Check if device is connected
    $status = Get-HIDDeviceStatus
    if (-not $status.IsConnected) {
        Write-Error "Not connected to G203 mouse. Use Connect-G203Mouse first."
        return
    }

    # Parse color
    if ($PSCmdlet.ParameterSetName -eq 'ByColorString') {
        try {
            $rgb = ConvertTo-RGBBytes -Color $Color
            $Red = $rgb.Red
            $Green = $rgb.Green
            $Blue = $rgb.Blue
        }
        catch {
            Write-Error $_
            return
        }
    }

    Write-Verbose "Setting color: R=$Red, G=$Green, B=$Blue"

    # Build and send command
    try {
        $command = Build-G203FixedColorCommand -Red $Red -Green $Green -Blue $Blue
        $result = Send-HIDIOControl -Data $command

        if ($result) {
            $hexColor = ConvertFrom-RGBBytes -Red $Red -Green $Green -Blue $Blue
            Write-Host "Color set to $hexColor" -ForegroundColor Green
            return $true
        }
        else {
            Write-Error "Failed to set color"
            return $false
        }
    }
    catch {
        Write-Error "Error setting color: $_"
        return $false
    }
}
