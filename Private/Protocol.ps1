<#
.SYNOPSIS
    G203 LIGHTSYNC USB HID Protocol Implementation

.DESCRIPTION
    Contains command builders for the G203 LIGHTSYNC LED control protocol.
    Based on reverse-engineered protocol from existing open-source projects.

.NOTES
    Protocol Details:
    - Command length: 20 bytes
    - Header: 11 FF 0E 3B
    - Vendor ID: 0x046D (Logitech)
    - Product ID: 0xC092 (G203 LIGHTSYNC)
#>

# G203 Protocol Constants
$script:G203_VID = 0x046D
$script:G203_PID = 0xC092
$script:COMMAND_LENGTH = 20

# Command header (constant for all LED commands)
$script:CMD_HEADER = @(0x11, 0xFF, 0x0E)

# Command types
$script:CMD_LED_CONTROL_PRODIGY = 0x3B     # Original G203
$script:CMD_LED_CONTROL_LIGHTSYNC = 0x1B   # G203 LIGHTSYNC
$script:CMD_LED_CONTROL = $script:CMD_LED_CONTROL_LIGHTSYNC  # Use LIGHTSYNC by default
$script:CMD_BRIGHTNESS = 0x11

# Effect modes
$script:MODE_FIXED = 0x01      # Solid color
$script:MODE_CYCLE = 0x02      # Rainbow cycle (Prodigy)
$script:MODE_BREATHE = 0x03    # Breathing/pulsing effect (Prodigy)
$script:MODE_BREATHE_LIGHTSYNC = 0x04  # Breathing for LIGHTSYNC
$script:MODE_CYCLE_LIGHTSYNC = 0x03    # Cycle for LIGHTSYNC

<#
.SYNOPSIS
    Build a G203 LED control command

.DESCRIPTION
    Creates a 20-byte command packet for controlling G203 LED effects

.PARAMETER Mode
    Effect mode: Fixed (0x01), Cycle (0x02), or Breathe (0x03)

.PARAMETER Red
    Red color component (0-255)

.PARAMETER Green
    Green color component (0-255)

.PARAMETER Blue
    Blue color component (0-255)

.PARAMETER Speed
    Effect speed in milliseconds (for Breathe and Cycle modes)

.EXAMPLE
    Build-G203LEDCommand -Mode 0x01 -Red 255 -Green 0 -Blue 0
    Creates a solid red color command

.OUTPUTS
    byte[] - 20-byte command array
#>
function Build-G203LEDCommand {
    [CmdletBinding()]
    [OutputType([byte[]])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateRange(0x01, 0x04)]
        [byte]$Mode,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 255)]
        [byte]$Red = 0,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 255)]
        [byte]$Green = 0,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 255)]
        [byte]$Blue = 0,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 65535)]
        [int]$Speed = 5000
    )

    Write-Verbose "Building G203 LED command: Mode=$Mode, RGB=($Red,$Green,$Blue), Speed=$Speed"

    # Create 20-byte command array
    $command = New-Object byte[] $script:COMMAND_LENGTH

    # Set command header
    $command[0] = $script:CMD_HEADER[0]  # 0x11
    $command[1] = $script:CMD_HEADER[1]  # 0xFF
    $command[2] = $script:CMD_HEADER[2]  # 0x0E
    $command[3] = $script:CMD_LED_CONTROL  # 0x3B

    # Zone (always 0x00 for all zones on G203)
    $command[4] = 0x00

    # Effect mode
    $command[5] = $Mode

    # RGB color values
    $command[6] = $Red
    $command[7] = $Green
    $command[8] = $Blue

    # For LIGHTSYNC: Speed bytes are at different positions depending on mode
    # For Fixed/Solid color: speed doesn't apply, use zeros
    # For Breathe/Cycle: speed goes in different positions

    if ($Mode -eq $script:MODE_FIXED) {
        # LIGHTSYNC Solid color: remaining bytes are 00 except byte 16 = 0x01
        $command[9] = 0x00
        $command[10] = 0x00
        $command[11] = 0x00
        $command[12] = 0x00
        $command[13] = 0x00
        $command[14] = 0x00
        $command[15] = 0x00
        $command[16] = 0x01  # LIGHTSYNC specific flag at position 16!
        $command[17] = 0x00
        $command[18] = 0x00
        $command[19] = 0x00
    } elseif ($Mode -eq $script:MODE_BREATHE_LIGHTSYNC) {
        # LIGHTSYNC Breathe: 11 FF 0E 1B 00 04 RR GG BB SSSS 00 BB 00 00 00 00 01 00 00 00
        # Bytes 9-10: Speed (big-endian)
        $command[9] = [byte](($Speed -shr 8) -band 0xFF)  # High byte
        $command[10] = [byte]($Speed -band 0xFF)          # Low byte
        $command[11] = 0x00
        # Byte 12: Brightness (0x64 = 100)
        $command[12] = 0x64
        # Bytes 13-15: padding
        $command[13] = 0x00
        $command[14] = 0x00
        $command[15] = 0x00
        # Byte 16: LIGHTSYNC flag
        $command[16] = 0x01
        $command[17] = 0x00
        $command[18] = 0x00
        $command[19] = 0x00
    } else {
        # LIGHTSYNC Cycle: 11 FF 0E 1B 00 02 00 00 00 00 00 SSSS BB 00 00 01 00 00 00
        # Bytes 6-10: zeros
        $command[6] = 0x00
        $command[7] = 0x00
        $command[8] = 0x00
        $command[9] = 0x00
        $command[10] = 0x00
        # Bytes 11-12: Speed (big-endian)
        $command[11] = [byte](($Speed -shr 8) -band 0xFF)  # High byte
        $command[12] = [byte]($Speed -band 0xFF)          # Low byte
        # Byte 13: Brightness (0x64 = 100)
        $command[13] = 0x64
        # Bytes 14-15: padding
        $command[14] = 0x00
        $command[15] = 0x00
        # Byte 16: LIGHTSYNC flag
        $command[16] = 0x01
        $command[17] = 0x00
        $command[18] = 0x00
        $command[19] = 0x00
    }

    $hexBytes = ($command | ForEach-Object { '{0:X2}' -f $_ }) -join ' '
    Write-Verbose "Command bytes: $hexBytes"

    return $command
}

<#
.SYNOPSIS
    Build a solid color command for G203

.PARAMETER Red
    Red color component (0-255)

.PARAMETER Green
    Green color component (0-255)

.PARAMETER Blue
    Blue color component (0-255)

.EXAMPLE
    Build-G203FixedColorCommand -Red 255 -Green 0 -Blue 0
    Creates a solid red color command

.OUTPUTS
    byte[] - 20-byte command array
#>
function Build-G203FixedColorCommand {
    [CmdletBinding()]
    [OutputType([byte[]])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 255)]
        [byte]$Red,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 255)]
        [byte]$Green,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 255)]
        [byte]$Blue
    )

    return Build-G203LEDCommand -Mode $script:MODE_FIXED -Red $Red -Green $Green -Blue $Blue
}

<#
.SYNOPSIS
    Build a breathing effect command for G203

.PARAMETER Red
    Red color component (0-255)

.PARAMETER Green
    Green color component (0-255)

.PARAMETER Blue
    Blue color component (0-255)

.PARAMETER Speed
    Breathing speed in milliseconds (default: 5000)

.EXAMPLE
    Build-G203BreatheCommand -Red 0 -Green 0 -Blue 255 -Speed 3000
    Creates a blue breathing effect at 3 second intervals

.OUTPUTS
    byte[] - 20-byte command array
#>
function Build-G203BreatheCommand {
    [CmdletBinding()]
    [OutputType([byte[]])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 255)]
        [byte]$Red,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 255)]
        [byte]$Green,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 255)]
        [byte]$Blue,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1000, 65535)]
        [int]$Speed = 5000
    )

    # Use LIGHTSYNC breathe mode (0x04)
    return Build-G203LEDCommand -Mode $script:MODE_BREATHE_LIGHTSYNC -Red $Red -Green $Green -Blue $Blue -Speed $Speed
}

<#
.SYNOPSIS
    Build a color cycle (rainbow) command for G203

.PARAMETER Speed
    Cycle speed in milliseconds (default: 10000)

.EXAMPLE
    Build-G203CycleCommand -Speed 8000
    Creates a rainbow cycle effect at 8 second intervals

.OUTPUTS
    byte[] - 20-byte command array
#>
function Build-G203CycleCommand {
    [CmdletBinding()]
    [OutputType([byte[]])]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateRange(1000, 65535)]
        [int]$Speed = 10000
    )

    # Cycle mode doesn't use RGB values (cycles through all colors)
    return Build-G203LEDCommand -Mode $script:MODE_CYCLE -Red 0 -Green 0 -Blue 0 -Speed $Speed
}

<#
.SYNOPSIS
    Build a brightness control command for G203

.PARAMETER Brightness
    Brightness level (0-100 percent)

.EXAMPLE
    Build-G203BrightnessCommand -Brightness 50
    Sets brightness to 50%

.OUTPUTS
    byte[] - 20-byte command array
#>
function Build-G203BrightnessCommand {
    [CmdletBinding()]
    [OutputType([byte[]])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 100)]
        [int]$Brightness
    )

    Write-Verbose "Building G203 brightness command: $Brightness%"

    # Create 20-byte command array
    $command = New-Object byte[] $script:COMMAND_LENGTH

    # Set command header
    $command[0] = $script:CMD_HEADER[0]  # 0x11
    $command[1] = $script:CMD_HEADER[1]  # 0xFF
    $command[2] = $script:CMD_HEADER[2]  # 0x0E
    $command[3] = $script:CMD_BRIGHTNESS  # 0x11

    # Zone (always 0x00)
    $command[4] = 0x00

    # Brightness value (0x00-0x64 for 0-100%)
    $command[5] = [byte]$Brightness

    # Remaining bytes are padding (already 0x00)

    $hexBytes = ($command | ForEach-Object { '{0:X2}' -f $_ }) -join ' '
    Write-Verbose "Brightness command bytes: $hexBytes"

    return $command
}

<#
.SYNOPSIS
    Get G203 device identifiers

.OUTPUTS
    hashtable with VendorId and ProductId
#>
function Get-G203DeviceIds {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    return @{
        VendorId = $script:G203_VID
        ProductId = $script:G203_PID
    }
}

# Functions are available when dot-sourced
# Export-ModuleMember only works in .psm1 module files
