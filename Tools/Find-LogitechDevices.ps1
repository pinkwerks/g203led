<#
.SYNOPSIS
    Enumerate all Logitech USB HID devices connected to the system

.DESCRIPTION
    This script searches for Logitech devices (Vendor ID: 0x046d) on the USB bus
    and displays detailed information including Product ID, device name, and paths.
    Use this to identify your mouse's exact Product ID for protocol implementation.

.EXAMPLE
    .\Find-LogitechDevices.ps1
    Lists all connected Logitech devices

.NOTES
    Author: G20LED Project
    Requires: PowerShell 5.1+
#>

[CmdletBinding()]
param()

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "Logitech Device Enumeration Tool" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""

# Check PowerShell version
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Gray
Write-Host ""

# Logitech Vendor ID
$LOGITECH_VID = "046D"

Write-Host "Searching for Logitech devices (VID: 0x$LOGITECH_VID)..." -ForegroundColor Yellow
Write-Host ""

try {
    # Method 1: Using Get-PnpDevice (Windows 10/11)
    Write-Host "[Method 1] PnP Device Enumeration:" -ForegroundColor Green
    Write-Host "-" * 80

    $pnpDevices = Get-PnpDevice | Where-Object {
        $_.InstanceId -like "*VID_$LOGITECH_VID*" -and
        $_.Class -eq "HIDClass"
    }

    if ($pnpDevices) {
        foreach ($device in $pnpDevices) {
            # Extract Product ID from Instance ID
            if ($device.InstanceId -match "VID_$LOGITECH_VID&PID_([0-9A-F]{4})") {
                $productId = $Matches[1]

                Write-Host "  Device Found:" -ForegroundColor White
                Write-Host "    Name:          $($device.FriendlyName)" -ForegroundColor Cyan
                Write-Host "    Status:        $($device.Status)" -ForegroundColor $(if ($device.Status -eq 'OK') { 'Green' } else { 'Yellow' })
                Write-Host "    Vendor ID:     0x$LOGITECH_VID" -ForegroundColor Cyan
                Write-Host "    Product ID:    0x$productId" -ForegroundColor Cyan
                Write-Host "    Instance ID:   $($device.InstanceId)" -ForegroundColor Gray
                Write-Host "    Device ID:     $($device.DeviceID)" -ForegroundColor Gray
                Write-Host ""
            }
        }
    } else {
        Write-Host "  No Logitech HID devices found via PnP enumeration" -ForegroundColor Yellow
        Write-Host ""
    }

    # Method 2: Using WMI (Alternative method)
    Write-Host "[Method 2] WMI USB Device Enumeration:" -ForegroundColor Green
    Write-Host "-" * 80

    $usbDevices = Get-WmiObject -Class Win32_PnPEntity | Where-Object {
        $_.DeviceID -like "*VID_$LOGITECH_VID*"
    }

    if ($usbDevices) {
        foreach ($device in $usbDevices) {
            if ($device.DeviceID -match "VID_$LOGITECH_VID&PID_([0-9A-F]{4})") {
                $productId = $Matches[1]

                Write-Host "  Device Found:" -ForegroundColor White
                Write-Host "    Name:        $($device.Name)" -ForegroundColor Cyan
                Write-Host "    Status:      $($device.Status)" -ForegroundColor $(if ($device.Status -eq 'OK') { 'Green' } else { 'Yellow' })
                Write-Host "    Vendor ID:   0x$LOGITECH_VID" -ForegroundColor Cyan
                Write-Host "    Product ID:  0x$productId" -ForegroundColor Cyan
                Write-Host "    Device ID:   $($device.DeviceID)" -ForegroundColor Gray
                Write-Host ""
            }
        }
    } else {
        Write-Host "  No Logitech USB devices found via WMI" -ForegroundColor Yellow
        Write-Host ""
    }

    # Method 3: Registry-based enumeration
    Write-Host "[Method 3] Registry USB Device Enumeration:" -ForegroundColor Green
    Write-Host "-" * 80

    $usbDeviceKeys = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Enum\USB" -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like "*VID_$LOGITECH_VID*" }

    if ($usbDeviceKeys) {
        foreach ($key in $usbDeviceKeys) {
            $keyName = Split-Path $key.Name -Leaf
            if ($keyName -match "VID_$LOGITECH_VID&PID_([0-9A-F]{4})") {
                $productId = $Matches[1]

                # Get device instances under this key
                $instances = Get-ChildItem $key.PSPath -ErrorAction SilentlyContinue
                foreach ($instance in $instances) {
                    $deviceDesc = (Get-ItemProperty -Path $instance.PSPath -Name "DeviceDesc" -ErrorAction SilentlyContinue).DeviceDesc
                    if ($deviceDesc) {
                        # Remove @system32\...dll,- prefix if present
                        $deviceDesc = $deviceDesc -replace '^@.*?;', ''

                        Write-Host "  Device Found:" -ForegroundColor White
                        Write-Host "    Description:  $deviceDesc" -ForegroundColor Cyan
                        Write-Host "    Vendor ID:    0x$LOGITECH_VID" -ForegroundColor Cyan
                        Write-Host "    Product ID:   0x$productId" -ForegroundColor Cyan
                        Write-Host "    Registry Key: $($instance.PSPath)" -ForegroundColor Gray
                        Write-Host ""
                    }
                }
            }
        }
    } else {
        Write-Host "  No Logitech USB devices found in registry" -ForegroundColor Yellow
        Write-Host ""
    }

} catch {
    Write-Error "Error during device enumeration: $_"
}

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "Enumeration Complete" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Identify your mouse from the list above" -ForegroundColor White
Write-Host "  2. Note the Vendor ID (should be 0x046D for Logitech)" -ForegroundColor White
Write-Host "  3. Note the Product ID (e.g., 0xC092 for G203)" -ForegroundColor White
Write-Host "  4. Search for '[your mouse model] LED protocol' on GitHub" -ForegroundColor White
Write-Host ""
Write-Host "Common Logitech Gaming Mouse Product IDs:" -ForegroundColor Gray
Write-Host "  G203 / G203 LIGHTSYNC: 0xC092, 0xC084" -ForegroundColor Gray
Write-Host "  G502 HERO:              0xC08B" -ForegroundColor Gray
Write-Host "  G502 Proteus Spectrum:  0xC332" -ForegroundColor Gray
Write-Host "  G403:                   0xC083" -ForegroundColor Gray
Write-Host "  G305:                   0xC08C" -ForegroundColor Gray
Write-Host "  G300s:                  0xC246" -ForegroundColor Gray
Write-Host ""
