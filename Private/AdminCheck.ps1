<#
.SYNOPSIS
    Administrator privilege checking and elevation functions

.DESCRIPTION
    Provides functions to check if PowerShell is running with administrator
    privileges and to request elevation when needed. This is required for
    USB HID device access on Windows.

.NOTES
    Windows USB HID access often requires administrator privileges,
    especially for sending feature reports and output reports to devices.
#>

<#
.SYNOPSIS
    Check if PowerShell is running as administrator

.DESCRIPTION
    Determines whether the current PowerShell session has administrator rights
    by checking the WindowsPrincipal identity.

.OUTPUTS
    Boolean - $true if running as admin, $false otherwise

.EXAMPLE
    if (Test-IsAdministrator) {
        Write-Host "Running with admin privileges"
    }
#>
function Test-IsAdministrator {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
        $adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator

        $isAdmin = $principal.IsInRole($adminRole)

        Write-Verbose "Administrator check: $isAdmin"
        return $isAdmin
    }
    catch {
        Write-Error "Failed to check administrator status: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Restart script with administrator privileges

.DESCRIPTION
    Relaunches the current PowerShell script with elevated (administrator)
    privileges using Start-Process with the -Verb RunAs parameter.

.PARAMETER ScriptPath
    Full path to the PowerShell script to elevate

.PARAMETER Arguments
    Optional array of arguments to pass to the elevated script

.OUTPUTS
    Boolean - $true if elevation was requested successfully

.EXAMPLE
    Request-AdminElevation -ScriptPath $PSCommandPath

.EXAMPLE
    Request-AdminElevation -ScriptPath "C:\Scripts\MyScript.ps1" -Arguments @("-Verbose", "-Color Red")

.NOTES
    - This will cause the current PowerShell session to exit
    - A UAC prompt will appear asking for administrator permission
    - The elevated script will run in a new PowerShell window
#>
function Request-AdminElevation {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,

        [Parameter(Mandatory = $false)]
        [string[]]$Arguments
    )

    Write-Verbose "Requesting elevation for: $ScriptPath"

    try {
        # Validate script path exists
        if (-not (Test-Path -Path $ScriptPath -PathType Leaf)) {
            Write-Error "Script path not found: $ScriptPath"
            return $false
        }

        # Build argument list
        $argList = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$ScriptPath`"")

        if ($Arguments -and $Arguments.Count -gt 0) {
            $argList += $Arguments
        }

        $argumentString = $argList -join " "

        Write-Verbose "Launching elevated process with arguments: $argumentString"

        # Start elevated process
        $process = Start-Process -FilePath "powershell.exe" `
                                 -ArgumentList $argumentString `
                                 -Verb RunAs `
                                 -PassThru

        if ($process) {
            Write-Host "Elevated PowerShell session started. This window will close." -ForegroundColor Yellow
            return $true
        }
        else {
            Write-Error "Failed to start elevated process"
            return $false
        }
    }
    catch [System.ComponentModel.Win32Exception] {
        # User cancelled UAC prompt
        Write-Warning "Elevation cancelled by user or access denied"
        return $false
    }
    catch {
        Write-Error "Failed to request elevation: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Execute a script block with administrator privileges

.DESCRIPTION
    Wrapper function that checks if running as administrator. If not,
    it will attempt to restart the script with elevation. If already
    running as admin, executes the script block directly.

.PARAMETER ScriptBlock
    The PowerShell script block to execute

.EXAMPLE
    Invoke-WithAdmin -ScriptBlock {
        Write-Host "This runs as admin"
        # Your code here
    }

.NOTES
    - This is designed for inline script blocks, not full scripts
    - For full script elevation, use Request-AdminElevation directly
    - The script block will execute in the current session if already admin
#>
function Invoke-WithAdmin {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock
    )

    if (Test-IsAdministrator) {
        Write-Verbose "Already running as administrator, executing script block"
        try {
            & $ScriptBlock
        }
        catch {
            Write-Error "Script block execution failed: $_"
            throw
        }
    }
    else {
        Write-Warning "Administrator privileges required but not available"
        Write-Host "This operation requires administrator privileges." -ForegroundColor Yellow
        Write-Host "Please restart PowerShell as Administrator and try again." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Or, use Request-AdminElevation to automatically restart with elevation." -ForegroundColor Cyan
        throw "Administrator privileges required"
    }
}

<#
.SYNOPSIS
    Display administrator status information

.DESCRIPTION
    Helper function to display current administrator status with formatting

.EXAMPLE
    Show-AdminStatus
#>
function Show-AdminStatus {
    [CmdletBinding()]
    param()

    $isAdmin = Test-IsAdministrator

    Write-Host "`nAdministrator Status Check" -ForegroundColor Cyan
    Write-Host ("=" * 40) -ForegroundColor Cyan

    if ($isAdmin) {
        Write-Host "  Status: " -NoNewline -ForegroundColor White
        Write-Host "Running as Administrator" -ForegroundColor Green
        Write-Host "  Access: " -NoNewline -ForegroundColor White
        Write-Host "Full USB HID device access" -ForegroundColor Green
    }
    else {
        Write-Host "  Status: " -NoNewline -ForegroundColor White
        Write-Host "Running as Standard User" -ForegroundColor Yellow
        Write-Host "  Access: " -NoNewline -ForegroundColor White
        Write-Host "Limited (may cause errors)" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  WARNING: USB HID operations may fail without admin rights" -ForegroundColor Red
    }

    Write-Host ("=" * 40) -ForegroundColor Cyan
    Write-Host ""
}

# Export functions for module use
# Note: Export-ModuleMember only works in .psm1 files
# These functions will be available when dot-sourced
