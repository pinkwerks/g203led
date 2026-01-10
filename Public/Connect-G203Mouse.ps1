<#
.SYNOPSIS
    Connect to Logitech G203 LIGHTSYNC mouse

.DESCRIPTION
    Establishes connection to the G203 mouse via USB HID interfaces.
    Opens both configuration (COL04) and LED control (COL05) interfaces.
    Initializes the mouse by disabling onboard memory mode.

.PARAMETER RequireAdmin
    If specified, checks for administrator privileges and fails if not admin.
    Otherwise, attempts connection and shows warning if it fails.

.EXAMPLE
    Connect-G203Mouse
    Connects to the G203 mouse

.EXAMPLE
    Connect-G203Mouse -RequireAdmin
    Connects only if running as administrator

.OUTPUTS
    Boolean - $true if connected successfully, $false otherwise

.NOTES
    Requires administrator privileges for USB HID access on Windows.
    The G203 requires two interfaces: COL04 for config, COL05 for LED commands.
#>
function Connect-G203Mouse {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$RequireAdmin
    )

    Write-Verbose "Connecting to G203 LIGHTSYNC mouse..."

    # Check admin privileges if required
    if ($RequireAdmin) {
        if (-not (Test-IsAdministrator)) {
            Write-Error "Administrator privileges required. Run PowerShell as Administrator or use Request-AdminElevation."
            return $false
        }
    }

    # Get device IDs from protocol
    $deviceIds = Get-G203DeviceIds
    $vendorId = $deviceIds.VendorId
    $productId = $deviceIds.ProductId

    Write-Verbose "Searching for device: VID=0x$($vendorId.ToString('X4')), PID=0x$($productId.ToString('X4'))"

    # Connect using IOControl method
    try {
        $result = Connect-HIDDevice -VendorId $vendorId -ProductId $productId

        if ($result) {
            $status = Get-HIDDeviceStatus
            Write-Host "Connected to G203 LIGHTSYNC" -ForegroundColor Green
            Write-Verbose "  Config Interface: $($status.ConfigPath)"
            Write-Verbose "  LED Interface: $($status.LEDPath)"
            return $true
        }
        else {
            Write-Error "Failed to connect to G203 mouse"

            # Show helpful message if not admin
            if (-not (Test-IsAdministrator)) {
                Write-Warning "USB HID access requires administrator privileges."
                Write-Warning "Try: Right-click PowerShell → Run as Administrator"
            }

            return $false
        }
    }
    catch {
        Write-Error "Connection error: $_"
        return $false
    }
}
