<#
.SYNOPSIS
    Set lighting effect on G203 mouse

.DESCRIPTION
    Sets various lighting effects including breathe (pulsing) and cycle (rainbow).
    Each effect has configurable parameters.

.PARAMETER Effect
    Effect type: Breathe, Cycle, or Fixed

.PARAMETER Color
    Color for the effect (hex or named). Required for Breathe and Fixed effects.

.PARAMETER Red
    Red component (0-255). Use with -Green and -Blue for RGB specification.

.PARAMETER Green
    Green component (0-255). Use with -Red and -Blue for RGB specification.

.PARAMETER Blue
    Blue component (0-255). Use with -Red and -Green for RGB specification.

.PARAMETER Speed
    Effect speed in milliseconds (1000-65535). Default: 5000 for Breathe, 10000 for Cycle.
    Lower values = faster effect.

.PARAMETER Brightness
    Brightness level (0-100). Default: 100

.EXAMPLE
    Set-G203Effect -Effect Breathe -Color "Blue" -Speed 3000
    Sets blue breathing effect at 3 second intervals

.EXAMPLE
    Set-G203Effect -Effect Cycle -Speed 8000
    Sets rainbow color cycle at 8 second intervals

.EXAMPLE
    Set-G203Effect -Effect Fixed -Color "#FF00FF"
    Sets solid magenta color (same as Set-G203Color)

.EXAMPLE
    Set-G203Effect Breathe -Red 255 -Green 0 -Blue 0 -Speed 2000
    Sets red breathing effect at 2 second intervals using RGB values

.NOTES
    Requires active connection via Connect-G203Mouse.

    Effect Details:
    - Breathe: Pulsing effect with specified color
    - Cycle: Rainbow effect cycling through all colors
    - Fixed: Solid color (prefer Set-G203Color for simplicity)
#>
function Set-G203Effect {
    [CmdletBinding(DefaultParameterSetName = 'ByColorString')]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet('Breathe', 'Cycle', 'Fixed')]
        [string]$Effect,

        [Parameter(Mandatory = $false, ParameterSetName = 'ByColorString')]
        [string]$Color,

        [Parameter(Mandatory = $false, ParameterSetName = 'ByRGB')]
        [ValidateRange(0, 255)]
        [byte]$Red,

        [Parameter(Mandatory = $false, ParameterSetName = 'ByRGB')]
        [ValidateRange(0, 255)]
        [byte]$Green,

        [Parameter(Mandatory = $false, ParameterSetName = 'ByRGB')]
        [ValidateRange(0, 255)]
        [byte]$Blue,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1000, 65535)]
        [int]$Speed,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 100)]
        [int]$Brightness
    )

    # Check if device is connected
    $status = Get-HIDDeviceStatus
    if (-not $status.IsConnected) {
        Write-Error "Not connected to G203 mouse. Use Connect-G203Mouse first."
        return
    }

    # Validate color requirement
    if ($Effect -in @('Breathe', 'Fixed')) {
        if ($PSCmdlet.ParameterSetName -eq 'ByColorString' -and -not $Color) {
            Write-Error "$Effect effect requires -Color parameter"
            return
        }
        if ($PSCmdlet.ParameterSetName -eq 'ByRGB' -and (-not $PSBoundParameters.ContainsKey('Red'))) {
            Write-Error "$Effect effect requires color (use -Color or -Red/-Green/-Blue)"
            return
        }
    }

    # Parse color if provided
    if ($PSCmdlet.ParameterSetName -eq 'ByColorString' -and $Color) {
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

    # Set defaults
    if (-not $Red) { $Red = 0 }
    if (-not $Green) { $Green = 0 }
    if (-not $Blue) { $Blue = 0 }

    # Build command based on effect
    try {
        switch ($Effect) {
            'Fixed' {
                Write-Verbose "Setting fixed color: R=$Red, G=$Green, B=$Blue"
                $command = Build-G203FixedColorCommand -Red $Red -Green $Green -Blue $Blue
            }
            'Breathe' {
                if (-not $Speed) { $Speed = 5000 }
                Write-Verbose "Setting breathe effect: R=$Red, G=$Green, B=$Blue, Speed=$Speed"
                $command = Build-G203BreatheCommand -Red $Red -Green $Green -Blue $Blue -Speed $Speed
            }
            'Cycle' {
                if (-not $Speed) { $Speed = 10000 }
                Write-Verbose "Setting cycle effect: Speed=$Speed"
                $command = Build-G203CycleCommand -Speed $Speed
            }
        }

        # Send LED command
        $result = Send-HIDIOControl -Data $command

        if (-not $result) {
            Write-Error "Failed to set $Effect effect"
            return $false
        }

        # Send brightness command if specified
        if ($PSBoundParameters.ContainsKey('Brightness')) {
            $brightnessCommand = Build-G203BrightnessCommand -Brightness $Brightness
            $brightnessResult = Send-HIDIOControl -Data $brightnessCommand

            if (-not $brightnessResult) {
                Write-Warning "Effect set but brightness adjustment failed"
            }
        }

        Write-Host "$Effect effect applied successfully" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Error setting effect: $_"
        return $false
    }
}
