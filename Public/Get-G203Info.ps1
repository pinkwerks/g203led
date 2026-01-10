<#
.SYNOPSIS
    Get information about connected G203 mouse

.DESCRIPTION
    Displays connection status, device paths, and configuration details
    for the G203 LIGHTSYNC mouse.

.EXAMPLE
    Get-G203Info
    Shows current device information

.OUTPUTS
    PSCustomObject with device details
#>
function Get-G203Info {
    [CmdletBinding()]
    param()

    $status = Get-HIDDeviceStatus
    $deviceIds = Get-G203DeviceIds

    $info = [PSCustomObject]@{
        Connected = $status.IsConnected
        VendorID = "0x$($deviceIds.VendorId.ToString('X4'))"
        ProductID = "0x$($deviceIds.ProductId.ToString('X4'))"
        ProductString = $status.ProductString
        ConfigInterfacePath = $status.ConfigPath
        LEDInterfacePath = $status.LEDPath
        ConfigHandle = if ($status.ConfigHandle) { "Open" } else { "Closed" }
        LEDHandle = if ($status.LEDHandle) { "Open" } else { "Closed" }
    }

    return $info
}
