<#
.SYNOPSIS
    Color parsing and conversion utilities for G203 LED control

.DESCRIPTION
    Provides functions to parse various color formats (hex, RGB, named colors)
    and convert them to RGB byte values for the G203 protocol
#>

# Named color definitions (standard CSS/HTML colors)
$script:NamedColors = @{
    # Basic colors
    'Black'   = @(0, 0, 0)
    'White'   = @(255, 255, 255)
    'Red'     = @(255, 0, 0)
    'Green'   = @(0, 255, 0)
    'Blue'    = @(0, 0, 255)
    'Yellow'  = @(255, 255, 0)
    'Cyan'    = @(0, 255, 255)
    'Magenta' = @(255, 0, 255)

    # Extended colors
    'Orange'  = @(255, 165, 0)
    'Purple'  = @(128, 0, 128)
    'Pink'    = @(255, 192, 203)
    'Lime'    = @(0, 255, 0)
    'Teal'    = @(0, 128, 128)
    'Navy'    = @(0, 0, 128)
    'Maroon'  = @(128, 0, 0)
    'Gray'    = @(128, 128, 128)
    'Silver'  = @(192, 192, 192)
    'Gold'    = @(255, 215, 0)
    'Brown'   = @(165, 42, 42)
    'Violet'  = @(238, 130, 238)
    'Indigo'  = @(75, 0, 130)
}

<#
.SYNOPSIS
    Convert a color string to RGB bytes

.PARAMETER Color
    Color in hex format (#RRGGBB or RRGGBB) or named color

.EXAMPLE
    ConvertTo-RGBBytes -Color "#FF0000"
    Returns: @{Red=255; Green=0; Blue=0}

.EXAMPLE
    ConvertTo-RGBBytes -Color "Red"
    Returns: @{Red=255; Green=0; Blue=0}

.OUTPUTS
    Hashtable with Red, Green, Blue keys
#>
function ConvertTo-RGBBytes {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Color
    )

    # Remove whitespace
    $Color = $Color.Trim()

    # Check if it's a hex color
    if ($Color -match '^#?([0-9A-Fa-f]{6})$') {
        $hexColor = $Matches[1]

        $red = [Convert]::ToByte($hexColor.Substring(0, 2), 16)
        $green = [Convert]::ToByte($hexColor.Substring(2, 2), 16)
        $blue = [Convert]::ToByte($hexColor.Substring(4, 2), 16)

        return @{
            Red = [byte]$red
            Green = [byte]$green
            Blue = [byte]$blue
        }
    }

    # Check if it's a named color
    if ($script:NamedColors.ContainsKey($Color)) {
        $rgb = $script:NamedColors[$Color]
        return @{
            Red = [byte]$rgb[0]
            Green = [byte]$rgb[1]
            Blue = [byte]$rgb[2]
        }
    }

    # Invalid format
    throw "Invalid color format: '$Color'. Use hex (#RRGGBB) or named color (Red, Blue, Green, etc.)"
}

<#
.SYNOPSIS
    Test if a color string is valid

.PARAMETER Color
    Color string to test

.OUTPUTS
    Boolean - true if valid, false otherwise
#>
function Test-ColorFormat {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Color
    )

    try {
        ConvertTo-RGBBytes -Color $Color | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

<#
.SYNOPSIS
    Get list of available named colors

.OUTPUTS
    Array of color names
#>
function Get-AvailableColors {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    return $script:NamedColors.Keys | Sort-Object
}

<#
.SYNOPSIS
    Convert RGB bytes to hex color string

.PARAMETER Red
    Red component (0-255)

.PARAMETER Green
    Green component (0-255)

.PARAMETER Blue
    Blue component (0-255)

.EXAMPLE
    ConvertFrom-RGBBytes -Red 255 -Green 0 -Blue 0
    Returns: "#FF0000"

.OUTPUTS
    String - hex color code
#>
function ConvertFrom-RGBBytes {
    [CmdletBinding()]
    [OutputType([string])]
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

    return "#{0:X2}{1:X2}{2:X2}" -f $Red, $Green, $Blue
}

# Functions are available when dot-sourced
