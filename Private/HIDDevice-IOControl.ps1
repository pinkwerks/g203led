<#
.SYNOPSIS
    Windows HID Device Communication Functions using DeviceIOControl

.DESCRIPTION
    Provides USB HID device access using Windows API via DeviceIOControl
    Alternative implementation to WriteFile-based approach
    Functional approach for PowerShell 5.1 compatibility

.NOTES
    Uses Windows HID API (hid.dll, setupapi.dll, kernel32.dll)
    Zero external dependencies
    Uses IOCTL_HID_SET_FEATURE and IOCTL_HID_SET_OUTPUT_REPORT
#>

# Module-level device state
$script:G203Device = @{
    DevicePath = ""
    DeviceHandle = $null
    IsConnected = $false
    VendorId = 0
    ProductId = 0
    ProductString = ""
    # G203 requires two interfaces:
    ConfigHandle = $null  # COL04 - for config commands (report ID 0x10)
    LEDHandle = $null     # COL05 - for LED commands (report ID 0x11)
}

# Define Windows API structures and functions
if (-not ([System.Management.Automation.PSTypeName]'HIDDeviceIO.NativeMethods').Type) {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using Microsoft.Win32.SafeHandles;

namespace HIDDeviceIO
{
    [StructLayout(LayoutKind.Sequential)]
    public struct HIDD_ATTRIBUTES
    {
        public int Size;
        public ushort VendorID;
        public ushort ProductID;
        public ushort VersionNumber;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct SP_DEVICE_INTERFACE_DATA
    {
        public int cbSize;
        public Guid InterfaceClassGuid;
        public int Flags;
        public IntPtr Reserved;
    }

    public static class NativeMethods
    {
        // hid.dll functions
        [DllImport("hid.dll", SetLastError = true)]
        public static extern void HidD_GetHidGuid(out Guid hidGuid);

        [DllImport("hid.dll", SetLastError = true)]
        public static extern bool HidD_GetAttributes(
            SafeFileHandle hDevice,
            ref HIDD_ATTRIBUTES attributes);

        [DllImport("hid.dll", SetLastError = true, CharSet = CharSet.Auto)]
        public static extern bool HidD_GetProductString(
            SafeFileHandle hDevice,
            IntPtr buffer,
            int bufferLength);

        [DllImport("hid.dll", SetLastError = true)]
        public static extern bool HidD_SetFeature(
            SafeFileHandle hDevice,
            byte[] reportBuffer,
            int reportBufferLength);

        // kernel32.dll DeviceIoControl for output reports
        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool DeviceIoControl(
            SafeFileHandle hDevice,
            uint dwIoControlCode,
            byte[] lpInBuffer,
            int nInBufferSize,
            IntPtr lpOutBuffer,
            int nOutBufferSize,
            out int lpBytesReturned,
            IntPtr lpOverlapped);

        // setupapi.dll functions
        [DllImport("setupapi.dll", SetLastError = true)]
        public static extern IntPtr SetupDiGetClassDevs(
            ref Guid classGuid,
            IntPtr enumerator,
            IntPtr hwndParent,
            int flags);

        [DllImport("setupapi.dll", SetLastError = true)]
        public static extern bool SetupDiEnumDeviceInterfaces(
            IntPtr deviceInfoSet,
            IntPtr deviceInfoData,
            ref Guid interfaceClassGuid,
            int memberIndex,
            ref SP_DEVICE_INTERFACE_DATA deviceInterfaceData);

        [DllImport("setupapi.dll", SetLastError = true, CharSet = CharSet.Auto)]
        public static extern bool SetupDiGetDeviceInterfaceDetail(
            IntPtr deviceInfoSet,
            ref SP_DEVICE_INTERFACE_DATA deviceInterfaceData,
            IntPtr deviceInterfaceDetailData,
            int deviceInterfaceDetailDataSize,
            out int requiredSize,
            IntPtr deviceInfoData);

        [DllImport("setupapi.dll", SetLastError = true)]
        public static extern bool SetupDiDestroyDeviceInfoList(
            IntPtr deviceInfoSet);

        // kernel32.dll functions
        [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Auto)]
        public static extern SafeFileHandle CreateFile(
            string fileName,
            uint desiredAccess,
            uint shareMode,
            IntPtr securityAttributes,
            uint creationDisposition,
            uint flagsAndAttributes,
            IntPtr templateFile);

        // Constants
        public const int DIGCF_PRESENT = 0x00000002;
        public const int DIGCF_DEVICEINTERFACE = 0x00000010;
        public const uint GENERIC_READ = 0x80000000;
        public const uint GENERIC_WRITE = 0x40000000;
        public const uint FILE_SHARE_READ = 0x00000001;
        public const uint FILE_SHARE_WRITE = 0x00000002;
        public const uint OPEN_EXISTING = 3;

        // HID IOCTL codes (from hidclass.h)
        public const uint IOCTL_HID_SET_FEATURE = 0x000B0191;         // HID Set Feature Report
        public const uint IOCTL_HID_SET_OUTPUT_REPORT = 0x000B0195;   // HID Set Output Report (CORRECT VALUE!)
        public const uint IOCTL_HID_GET_FEATURE = 0x000B0192;         // HID Get Feature Report (for reference)
    }
}
"@
}

<#
.SYNOPSIS
    Find HID devices matching vendor and product ID

.PARAMETER VendorId
    USB Vendor ID (e.g., 0x046D for Logitech)

.PARAMETER ProductId
    USB Product ID (e.g., 0xC092 for G203 LIGHTSYNC)

.OUTPUTS
    Array of device paths
#>
function Find-HIDDevices {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory = $true)]
        [uint16]$VendorId,

        [Parameter(Mandatory = $true)]
        [uint16]$ProductId
    )

    Write-Verbose "Searching for HID devices: VID=0x$($VendorId.ToString('X4')), PID=0x$($ProductId.ToString('X4'))"

    $devicePaths = @()
    $hidGuid = [Guid]::Empty
    [HIDDeviceIO.NativeMethods]::HidD_GetHidGuid([ref]$hidGuid)

    $deviceInfoSet = [HIDDeviceIO.NativeMethods]::SetupDiGetClassDevs(
        [ref]$hidGuid,
        [IntPtr]::Zero,
        [IntPtr]::Zero,
        [HIDDeviceIO.NativeMethods]::DIGCF_PRESENT -bor [HIDDeviceIO.NativeMethods]::DIGCF_DEVICEINTERFACE
    )

    if ($deviceInfoSet -eq [IntPtr]::Zero) {
        Write-Error "Failed to get device info set"
        return $devicePaths
    }

    try {
        $memberIndex = 0
        while ($true) {
            $deviceInterfaceData = New-Object HIDDeviceIO.SP_DEVICE_INTERFACE_DATA
            $deviceInterfaceData.cbSize = [System.Runtime.InteropServices.Marshal]::SizeOf($deviceInterfaceData)

            $result = [HIDDeviceIO.NativeMethods]::SetupDiEnumDeviceInterfaces(
                $deviceInfoSet,
                [IntPtr]::Zero,
                [ref]$hidGuid,
                $memberIndex,
                [ref]$deviceInterfaceData
            )

            if (-not $result) { break }

            # Get required size
            $requiredSize = 0
            [HIDDeviceIO.NativeMethods]::SetupDiGetDeviceInterfaceDetail(
                $deviceInfoSet,
                [ref]$deviceInterfaceData,
                [IntPtr]::Zero,
                0,
                [ref]$requiredSize,
                [IntPtr]::Zero
            ) | Out-Null

            # Get detail data
            $detailDataBuffer = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($requiredSize)
            try {
                $sizeField = if ([IntPtr]::Size -eq 8) { 8 } else { 4 + [System.Runtime.InteropServices.Marshal]::SystemDefaultCharSize }
                [System.Runtime.InteropServices.Marshal]::WriteInt32($detailDataBuffer, $sizeField)

                $result = [HIDDeviceIO.NativeMethods]::SetupDiGetDeviceInterfaceDetail(
                    $deviceInfoSet,
                    [ref]$deviceInterfaceData,
                    $detailDataBuffer,
                    $requiredSize,
                    [ref]$requiredSize,
                    [IntPtr]::Zero
                )

                if ($result) {
                    $pathPtr = [IntPtr]::Add($detailDataBuffer, 4)
                    $devicePath = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($pathPtr)

                    # Check VID/PID
                    $handle = [HIDDeviceIO.NativeMethods]::CreateFile(
                        $devicePath,
                        [HIDDeviceIO.NativeMethods]::GENERIC_READ -bor [HIDDeviceIO.NativeMethods]::GENERIC_WRITE,
                        [HIDDeviceIO.NativeMethods]::FILE_SHARE_READ -bor [HIDDeviceIO.NativeMethods]::FILE_SHARE_WRITE,
                        [IntPtr]::Zero,
                        [HIDDeviceIO.NativeMethods]::OPEN_EXISTING,
                        0,
                        [IntPtr]::Zero
                    )

                    if (-not $handle.IsInvalid) {
                        try {
                            $attributes = New-Object HIDDeviceIO.HIDD_ATTRIBUTES
                            $attributes.Size = [System.Runtime.InteropServices.Marshal]::SizeOf($attributes)

                            if ([HIDDeviceIO.NativeMethods]::HidD_GetAttributes($handle, [ref]$attributes)) {
                                if ($attributes.VendorID -eq $VendorId -and $attributes.ProductID -eq $ProductId) {
                                    Write-Verbose "Found matching device: $devicePath"
                                    $devicePaths += $devicePath
                                }
                            }
                        }
                        finally {
                            $handle.Dispose()
                        }
                    }
                }
            }
            finally {
                [System.Runtime.InteropServices.Marshal]::FreeHGlobal($detailDataBuffer)
            }

            $memberIndex++
        }
    }
    finally {
        [HIDDeviceIO.NativeMethods]::SetupDiDestroyDeviceInfoList($deviceInfoSet) | Out-Null
    }

    Write-Verbose "Found $($devicePaths.Count) matching device(s)"
    return $devicePaths
}

<#
.SYNOPSIS
    Connect to G203 HID device

.PARAMETER VendorId
    USB Vendor ID

.PARAMETER ProductId
    USB Product ID

.OUTPUTS
    Boolean - true if connected successfully
#>
function Connect-HIDDevice {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [uint16]$VendorId,

        [Parameter(Mandatory = $true)]
        [uint16]$ProductId
    )

    Write-Verbose "Connecting to device: VID=0x$($VendorId.ToString('X4')), PID=0x$($ProductId.ToString('X4'))"

    $devices = Find-HIDDevices -VendorId $VendorId -ProductId $ProductId

    if ($devices.Count -eq 0) {
        Write-Error "No matching HID devices found"
        return $false
    }

    # G203 requires TWO interfaces:
    # COL04 - for config commands (disable onboard memory, etc.) - Report ID 0x10
    # COL05 - for LED commands - Report ID 0x11
    $configDevice = $devices | Where-Object { $_ -like '*mi_01*col04*' } | Select-Object -First 1
    $ledDevice = $devices | Where-Object { $_ -like '*mi_01*col05*' } | Select-Object -First 1

    if (-not $configDevice) {
        Write-Warning "Could not find config interface (MI_01&COL04)"
    } else {
        Write-Verbose "Found config interface: $configDevice"
    }

    if (-not $ledDevice) {
        Write-Error "Could not find LED control interface (MI_01&COL05)"
        return $false
    } else {
        Write-Verbose "Found LED control interface: $ledDevice"
    }

    # Open config interface (COL04)
    if ($configDevice) {
        $script:G203Device.ConfigHandle = [HIDDeviceIO.NativeMethods]::CreateFile(
            $configDevice,
            [HIDDeviceIO.NativeMethods]::GENERIC_READ -bor [HIDDeviceIO.NativeMethods]::GENERIC_WRITE,
            [HIDDeviceIO.NativeMethods]::FILE_SHARE_READ -bor [HIDDeviceIO.NativeMethods]::FILE_SHARE_WRITE,
            [IntPtr]::Zero,
            [HIDDeviceIO.NativeMethods]::OPEN_EXISTING,
            0,
            [IntPtr]::Zero
        )

        if ($script:G203Device.ConfigHandle.IsInvalid) {
            Write-Warning "Failed to open config interface handle"
            $script:G203Device.ConfigHandle = $null
        }
    }

    # Open LED interface (COL05) - REQUIRED
    $script:G203Device.LEDHandle = [HIDDeviceIO.NativeMethods]::CreateFile(
        $ledDevice,
        [HIDDeviceIO.NativeMethods]::GENERIC_READ -bor [HIDDeviceIO.NativeMethods]::GENERIC_WRITE,
        [HIDDeviceIO.NativeMethods]::FILE_SHARE_READ -bor [HIDDeviceIO.NativeMethods]::FILE_SHARE_WRITE,
        [IntPtr]::Zero,
        [HIDDeviceIO.NativeMethods]::OPEN_EXISTING,
        0,
        [IntPtr]::Zero
    )

    if ($script:G203Device.LEDHandle.IsInvalid) {
        Write-Error "Failed to open LED interface handle"
        if ($script:G203Device.ConfigHandle) {
            $script:G203Device.ConfigHandle.Dispose()
        }
        return $false
    }

    # Keep main device path as LED interface for backward compatibility
    $script:G203Device.DevicePath = $ledDevice
    $script:G203Device.DeviceHandle = $script:G203Device.LEDHandle

    # Get attributes
    $attributes = New-Object HIDDeviceIO.HIDD_ATTRIBUTES
    $attributes.Size = [System.Runtime.InteropServices.Marshal]::SizeOf($attributes)

    if ([HIDDeviceIO.NativeMethods]::HidD_GetAttributes($script:G203Device.DeviceHandle, [ref]$attributes)) {
        $script:G203Device.VendorId = $attributes.VendorID
        $script:G203Device.ProductId = $attributes.ProductID
    }

    # Get product string
    $buffer = [System.Runtime.InteropServices.Marshal]::AllocHGlobal(256)
    try {
        if ([HIDDeviceIO.NativeMethods]::HidD_GetProductString($script:G203Device.DeviceHandle, $buffer, 256)) {
            $script:G203Device.ProductString = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($buffer)
        }
    }
    finally {
        [System.Runtime.InteropServices.Marshal]::FreeHGlobal($buffer)
    }

    $script:G203Device.IsConnected = $true
    Write-Host "Connected to device: $($script:G203Device.ProductString)" -ForegroundColor Green

    # CRITICAL: Disable onboard memory mode before LED commands work
    Write-Verbose "Initializing device..."
    $initResult = Disable-G203OnboardMemory
    if (-not $initResult) {
        Write-Warning "Device connected but initialization failed - LED commands may not work"
    } else {
        Write-Verbose "Device initialized successfully"
    }

    return $true
}

<#
.SYNOPSIS
    Send data using DeviceIOControl with IOCTL_HID_SET_OUTPUT_REPORT

.PARAMETER Data
    Byte array to send (must include report ID as first byte)

.OUTPUTS
    Boolean - true if sent successfully
#>
function Send-HIDIOControl {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [byte[]]$Data
    )

    if (-not $script:G203Device.IsConnected) {
        Write-Error "Device not connected"
        return $false
    }

    if (-not $script:G203Device.LEDHandle -or $script:G203Device.LEDHandle.IsInvalid) {
        Write-Error "LED interface handle not available"
        return $false
    }

    Write-Verbose "Sending LED data via DeviceIOControl with IOCTL_HID_SET_OUTPUT_REPORT ($($Data.Length) bytes)"

    # Display the data being sent
    $hexBytes = ($Data | ForEach-Object { '{0:X2}' -f $_ }) -join ' '
    Write-Verbose "Data bytes: $hexBytes"

    # Use DeviceIOControl with IOCTL_HID_SET_OUTPUT_REPORT on LED interface (COL05)
    $bytesReturned = 0
    $result = [HIDDeviceIO.NativeMethods]::DeviceIoControl(
        $script:G203Device.LEDHandle,
        [HIDDeviceIO.NativeMethods]::IOCTL_HID_SET_OUTPUT_REPORT,
        $Data,
        $Data.Length,
        [IntPtr]::Zero,
        0,
        [ref]$bytesReturned,
        [IntPtr]::Zero
    )

    if (-not $result) {
        $errorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
        Write-Error "DeviceIOControl (IOCTL_HID_SET_OUTPUT_REPORT) failed (Error: $errorCode)"
        Write-Host "  Error code $errorCode typically means:" -ForegroundColor Yellow
        switch ($errorCode) {
            1 { Write-Host "    - Incorrect function / Invalid IOCTL or report format" -ForegroundColor Yellow }
            5 { Write-Host "    - Access denied / Insufficient permissions" -ForegroundColor Yellow }
            87 { Write-Host "    - Invalid parameter / Wrong buffer size or report ID" -ForegroundColor Yellow }
            1167 { Write-Host "    - Device not connected" -ForegroundColor Yellow }
            default { Write-Host "    - Unknown error" -ForegroundColor Yellow }
        }
        return $false
    }

    Write-Verbose "LED data sent successfully via DeviceIOControl (returned $bytesReturned bytes)"
    Write-Host "  [SUCCESS] LED command sent via COL05 interface!" -ForegroundColor Green
    return $true
}

<#
.SYNOPSIS
    Disable onboard memory mode on G203 (required before sending LED commands)

.OUTPUTS
    Boolean - true if sent successfully
#>
function Disable-G203OnboardMemory {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    if (-not $script:G203Device.IsConnected) {
        Write-Error "Device not connected"
        return $false
    }

    if (-not $script:G203Device.ConfigHandle -or $script:G203Device.ConfigHandle.IsInvalid) {
        Write-Warning "Config interface (COL04) not available - skipping disable onboard memory"
        return $false
    }

    Write-Verbose "Disabling G203 onboard memory mode via COL04 interface"

    # Command to disable onboard memory: Report ID 0x10, then command bytes
    # 10 FF 0E 5B 01 03 05, padded to 20 bytes
    $command = @(0x10, 0xFF, 0x0E, 0x5B, 0x01, 0x03, 0x05, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)

    $hexBytes = ($command | ForEach-Object { '{0:X2}' -f $_ }) -join ' '
    Write-Verbose "Disable onboard memory command: $hexBytes"

    # Use DeviceIOControl with IOCTL_HID_SET_OUTPUT_REPORT on config interface (COL04)
    $bytesReturned = 0
    $result = [HIDDeviceIO.NativeMethods]::DeviceIoControl(
        $script:G203Device.ConfigHandle,
        [HIDDeviceIO.NativeMethods]::IOCTL_HID_SET_OUTPUT_REPORT,
        $command,
        $command.Length,
        [IntPtr]::Zero,
        0,
        [ref]$bytesReturned,
        [IntPtr]::Zero
    )

    if (-not $result) {
        $errorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
        Write-Warning "Failed to disable onboard memory (Error: $errorCode)"
        return $false
    }

    Write-Verbose "Onboard memory disabled successfully via COL04"
    return $true
}


<#
.SYNOPSIS
    Disconnect from HID device
#>
function Disconnect-HIDDevice {
    [CmdletBinding()]
    param()

    if ($script:G203Device.ConfigHandle -and -not $script:G203Device.ConfigHandle.IsInvalid) {
        Write-Verbose "Closing config interface handle (COL04)"
        $script:G203Device.ConfigHandle.Dispose()
        $script:G203Device.ConfigHandle = $null
    }

    if ($script:G203Device.LEDHandle -and -not $script:G203Device.LEDHandle.IsInvalid) {
        Write-Verbose "Closing LED interface handle (COL05)"
        $script:G203Device.LEDHandle.Dispose()
        $script:G203Device.LEDHandle = $null
    }

    $script:G203Device.DeviceHandle = $null
    $script:G203Device.IsConnected = $false
    $script:G203Device.DevicePath = ""
    Write-Verbose "Disconnected from device"
}

<#
.SYNOPSIS
    Get current device connection status
#>
function Get-HIDDeviceStatus {
    [CmdletBinding()]
    param()

    return $script:G203Device
}

# Functions are available when dot-sourced
# Export-ModuleMember only works in .psm1 module files
