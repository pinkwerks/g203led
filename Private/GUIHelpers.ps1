<#
.SYNOPSIS
    GUI helper functions for Show-G203GUI

.DESCRIPTION
    Provides utility functions for the WPF GUI including color conversion,
    validation, and error handling.
#>

<#
.SYNOPSIS
    Convert RGB bytes to WPF Color object

.PARAMETER Red
    Red component (0-255)

.PARAMETER Green
    Green component (0-255)

.PARAMETER Blue
    Blue component (0-255)

.OUTPUTS
    System.Windows.Media.Color object
#>
function ConvertTo-WPFColor {
    [CmdletBinding()]
    [OutputType([System.Windows.Media.Color])]
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

    return [System.Windows.Media.Color]::FromRgb($Red, $Green, $Blue)
}

<#
.SYNOPSIS
    Validate and clamp RGB input value

.PARAMETER Value
    String value to validate

.OUTPUTS
    Clamped byte value (0-255)
#>
function Get-ClampedRGBValue {
    [CmdletBinding()]
    [OutputType([byte])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Value
    )

    # Handle empty string
    if ([string]::IsNullOrWhiteSpace($Value)) {
        return [byte]0
    }

    # Try to parse as integer
    $intValue = 0
    if (-not [int]::TryParse($Value, [ref]$intValue)) {
        return [byte]0
    }

    # Clamp to 0-255 range
    if ($intValue -lt 0) {
        return [byte]0
    }
    if ($intValue -gt 255) {
        return [byte]255
    }

    return [byte]$intValue
}

<#
.SYNOPSIS
    Parse hex color string to RGB values

.PARAMETER HexString
    Hex color string (#RRGGBB or RRGGBB)

.OUTPUTS
    Hashtable with Red, Green, Blue keys, or $null if invalid
#>
function ConvertFrom-HexString {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$HexString
    )

    # Remove whitespace and # prefix
    $hex = $HexString.Trim() -replace '^#', ''

    # Validate format
    if ($hex -notmatch '^[0-9A-Fa-f]{6}$') {
        return $null
    }

    try {
        $red = [Convert]::ToByte($hex.Substring(0, 2), 16)
        $green = [Convert]::ToByte($hex.Substring(2, 2), 16)
        $blue = [Convert]::ToByte($hex.Substring(4, 2), 16)

        return @{
            Red = [byte]$red
            Green = [byte]$green
            Blue = [byte]$blue
        }
    }
    catch {
        return $null
    }
}

<#
.SYNOPSIS
    Convert RGB values to hex string

.PARAMETER Red
    Red component (0-255)

.PARAMETER Green
    Green component (0-255)

.PARAMETER Blue
    Blue component (0-255)

.OUTPUTS
    Hex color string (#RRGGBB)
#>
function ConvertTo-HexString {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [byte]$Red,

        [Parameter(Mandatory = $true)]
        [byte]$Green,

        [Parameter(Mandatory = $true)]
        [byte]$Blue
    )

    return "#{0:X2}{1:X2}{2:X2}" -f $Red, $Green, $Blue
}

<#
.SYNOPSIS
    Show error message dialog

.PARAMETER Message
    Error message to display

.PARAMETER Title
    Dialog title (default: "Error")
#>
function Show-ErrorDialog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$Title = "Error"
    )

    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show($Message, $Title,
        [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]::Error) | Out-Null
}

<#
.SYNOPSIS
    Show warning message dialog

.PARAMETER Message
    Warning message to display

.PARAMETER Title
    Dialog title (default: "Warning")

.OUTPUTS
    MessageBoxResult (Yes/No if buttons specified)
#>
function Show-WarningDialog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$Title = "Warning",

        [Parameter(Mandatory = $false)]
        [System.Windows.MessageBoxButton]$Buttons = [System.Windows.MessageBoxButton]::OK
    )

    Add-Type -AssemblyName PresentationFramework
    return [System.Windows.MessageBox]::Show($Message, $Title,
        $Buttons,
        [System.Windows.MessageBoxImage]::Warning)
}

<#
.SYNOPSIS
    Convert RGB to HSV

.PARAMETER Red
    Red component (0-255)

.PARAMETER Green
    Green component (0-255)

.PARAMETER Blue
    Blue component (0-255)

.OUTPUTS
    Hashtable with H (0-360), S (0-100), V (0-100)
#>
function ConvertTo-HSV {
    [CmdletBinding()]
    [OutputType([hashtable])]
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

    $r = $Red / 255.0
    $g = $Green / 255.0
    $b = $Blue / 255.0

    $max = [Math]::Max($r, [Math]::Max($g, $b))
    $min = [Math]::Min($r, [Math]::Min($g, $b))
    $delta = $max - $min

    # Hue calculation
    $h = 0
    if ($delta -ne 0) {
        if ($max -eq $r) {
            $h = 60 * ((($g - $b) / $delta) % 6)
        }
        elseif ($max -eq $g) {
            $h = 60 * ((($b - $r) / $delta) + 2)
        }
        else {
            $h = 60 * ((($r - $g) / $delta) + 4)
        }
    }
    if ($h -lt 0) { $h += 360 }

    # Saturation calculation
    $s = 0
    if ($max -ne 0) {
        $s = ($delta / $max) * 100
    }

    # Value calculation
    $v = $max * 100

    return @{
        H = [int]$h
        S = [int]$s
        V = [int]$v
    }
}

<#
.SYNOPSIS
    Convert HSV to RGB

.PARAMETER Hue
    Hue (0-360)

.PARAMETER Saturation
    Saturation (0-100)

.PARAMETER Value
    Value (0-100)

.OUTPUTS
    Hashtable with Red, Green, Blue (0-255)
#>
function ConvertFrom-HSV {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 360)]
        [int]$Hue,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 100)]
        [int]$Saturation,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 100)]
        [int]$Value
    )

    $s = $Saturation / 100.0
    $v = $Value / 100.0

    $c = $v * $s
    $x = $c * (1 - [Math]::Abs((($Hue / 60.0) % 2) - 1))
    $m = $v - $c

    $r = 0; $g = 0; $b = 0

    if ($Hue -ge 0 -and $Hue -lt 60) {
        $r = $c; $g = $x; $b = 0
    }
    elseif ($Hue -ge 60 -and $Hue -lt 120) {
        $r = $x; $g = $c; $b = 0
    }
    elseif ($Hue -ge 120 -and $Hue -lt 180) {
        $r = 0; $g = $c; $b = $x
    }
    elseif ($Hue -ge 180 -and $Hue -lt 240) {
        $r = 0; $g = $x; $b = $c
    }
    elseif ($Hue -ge 240 -and $Hue -lt 300) {
        $r = $x; $g = 0; $b = $c
    }
    else {
        $r = $c; $g = 0; $b = $x
    }

    return @{
        Red = [byte](($r + $m) * 255)
        Green = [byte](($g + $m) * 255)
        Blue = [byte](($b + $m) * 255)
    }
}
