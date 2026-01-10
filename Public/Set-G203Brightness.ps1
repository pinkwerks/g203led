<#
.SYNOPSIS
    Set brightness level on G203 mouse

.DESCRIPTION
    Sets the LED brightness level from 0% (off) to 100% (full brightness).

.PARAMETER Percent
    Brightness level as a percentage (0-100)

.EXAMPLE
    Set-G203Brightness -Percent 50
    Sets brightness to 50%

.EXAMPLE
    Set-G203Brightness 80
    Sets brightness to 80% (positional parameter)

.NOTES
    Requires active connection via Connect-G203Mouse.
    Brightness applies to all LED effects.
#>
function Set-G203Brightness {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateRange(0, 100)]
        [int]$Percent
    )

    # Check if device is connected
    $status = Get-HIDDeviceStatus
    if (-not $status.IsConnected) {
        Write-Error "Not connected to G203 mouse. Use Connect-G203Mouse first."
        return
    }

    Write-Verbose "Setting brightness to $Percent%"

    # Build and send command
    try {
        $command = Build-G203BrightnessCommand -Brightness $Percent
        $result = Send-HIDIOControl -Data $command

        if ($result) {
            Write-Host "Brightness set to $Percent%" -ForegroundColor Green
            return $true
        }
        else {
            Write-Error "Failed to set brightness"
            return $false
        }
    }
    catch {
        Write-Error "Error setting brightness: $_"
        return $false
    }
}
