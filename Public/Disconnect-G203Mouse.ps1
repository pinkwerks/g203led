<#
.SYNOPSIS
    Disconnect from G203 mouse

.DESCRIPTION
    Closes the USB HID connection to the G203 mouse.
    Releases both configuration and LED control interface handles.

.EXAMPLE
    Disconnect-G203Mouse
    Disconnects from the mouse

.NOTES
    Always call this when done to properly release USB handles.
#>
function Disconnect-G203Mouse {
    [CmdletBinding()]
    param()

    Write-Verbose "Disconnecting from G203 mouse..."

    try {
        Disconnect-HIDDevice
        Write-Verbose "Disconnected successfully"
    }
    catch {
        Write-Error "Disconnect error: $_"
    }
}
