<#
.SYNOPSIS
    G20LED - Logitech G203 LIGHTSYNC LED Controller Module

.DESCRIPTION
    PowerShell module for controlling LED lighting on Logitech G203 LIGHTSYNC mouse
    without requiring Logitech G HUB software. Provides direct USB HID control.

.NOTES
    Module Name: G20LED
    Author: Christopher Bonnstetter
    Version: 1.0.0
    Requires: PowerShell 5.1+, Windows 10/11
    Device: Logitech G203 LIGHTSYNC (VID:0x046D, PID:0xC092)
#>

#Requires -Version 5.1

# Module root path
$ModuleRoot = $PSScriptRoot

Write-Verbose "Loading G20LED module from $ModuleRoot"

# Load Private functions
$PrivateFunctions = @(
    'AdminCheck.ps1',
    'ColorHelpers.ps1',
    'Protocol.ps1',
    'HIDDevice-IOControl.ps1',
    'NonAdminHelper.ps1',
    'GUIHelpers.ps1'
)

foreach ($function in $PrivateFunctions) {
    $functionPath = Join-Path $ModuleRoot "Private\$function"
    if (Test-Path $functionPath) {
        Write-Verbose "  Loading Private\$function"
        . $functionPath
    }
    else {
        Write-Warning "Private function not found: $functionPath"
    }
}

# Load Public functions (cmdlets)
$PublicFunctions = @(
    'Connect-G203Mouse.ps1',
    'Disconnect-G203Mouse.ps1',
    'Get-G203Info.ps1',
    'Set-G203Color.ps1',
    'Set-G203Brightness.ps1',
    'Set-G203Effect.ps1',
    'Show-G203Help.ps1',
    'Show-G203GUI.ps1'
)

foreach ($function in $PublicFunctions) {
    $functionPath = Join-Path $ModuleRoot "Public\$function"
    if (Test-Path $functionPath) {
        Write-Verbose "  Loading Public\$function"
        . $functionPath
    }
    else {
        Write-Warning "Public function not found: $functionPath"
    }
}

# Export Public cmdlets
Export-ModuleMember -Function @(
    'Connect-G203Mouse',
    'Disconnect-G203Mouse',
    'Get-G203Info',
    'Set-G203Color',
    'Set-G203Brightness',
    'Set-G203Effect',
    'Show-G203Help',
    'Show-G203GUI'
)

# Module startup message
Write-Verbose "G20LED module loaded successfully"
Write-Verbose "Use 'Get-Command -Module G20LED' to see available commands"
