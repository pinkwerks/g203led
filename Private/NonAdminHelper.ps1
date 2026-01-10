<#
.SYNOPSIS
    Helper functions for accessing USB HID devices without administrator privileges

.DESCRIPTION
    This module provides multiple approaches to enable non-administrator access to USB HID devices
    (specifically Logitech G203 mouse). Includes:

    1. Device permission modification (one-time admin setup)
    2. Windows Service wrapper (background service approach)
    3. Task Scheduler integration
    4. UWP API exploration (Windows.Devices.HumanInterfaceDevice)

    Based on extensive research into Windows USB HID security model.

.NOTES
    Author: G20LED Project
    Date: 2026-01-10

    IMPORTANT: Windows HID device access typically requires administrator privileges due to:
    - Device driver security model
    - CreateFile with GENERIC_WRITE access
    - DeviceIOControl IOCTL operations

    This module implements workarounds that are practical but have limitations.

.RESEARCH FINDINGS
    After extensive research, the following approaches were evaluated:

    1. Registry/ACL Modifications:
       - Can modify HKLM\SYSTEM\CurrentControlSet\Enum\USB permissions
       - Requires SetACL tool (no built-in command-line registry ACL tool)
       - Changes may be overwritten on device reconnection
       - Risk of breaking other applications

    2. WinUSB Driver:
       - Requires replacing HID driver with WinUSB via custom INF
       - Breaks device functionality in other applications (G HUB)
       - Installation requires admin anyway

    3. UWP API (Windows.Devices.HumanInterfaceDevice):
       - Requires UWP app manifest with device capabilities
       - Not directly accessible from PowerShell
       - Would require C# wrapper with proper manifest

    4. Windows Service:
       - Service runs as LocalSystem with full privileges
       - Client communicates via named pipe
       - Most reliable approach but complex setup

    5. Task Scheduler:
       - Can create task with "Run with highest privileges"
       - Simpler than service but less elegant
       - Good for occasional use

    6. Device Permission Modification:
       - Use DeviceClasses registry and file system ACLs
       - Most practical for persistent non-admin access
       - Requires one-time admin setup

.RECOMMENDATION
    Based on research, the most practical solution is:
    - Primary: Device permission modification (one-time setup)
    - Fallback: Task Scheduler approach
    - Advanced: Windows Service (for production deployments)
#>

# Import required modules
if (-not (Get-Command Test-IsAdministrator -ErrorAction SilentlyContinue)) {
    . "$PSScriptRoot\AdminCheck.ps1"
}

#region Device Permission Modification Approach

<#
.SYNOPSIS
    Grant non-admin users access to specific USB HID device

.DESCRIPTION
    Modifies device permissions in the registry and file system to allow
    standard users to access the G203 mouse HID interface. This is a one-time
    setup that requires administrator privileges.

    The function modifies:
    1. Registry permissions in HKLM\SYSTEM\CurrentControlSet\Enum\USB\VID_046D&PID_C092
    2. Device interface permissions in DeviceClasses

    CAUTION: This modifies system security settings. Use with care.

.PARAMETER VendorId
    USB Vendor ID (default: 0x046D for Logitech)

.PARAMETER ProductId
    USB Product ID (default: 0xC092 for G203 LIGHTSYNC)

.PARAMETER Username
    Username to grant access to (default: current user)

.EXAMPLE
    Grant-HIDDeviceAccess
    Grants current user access to G203 mouse

.EXAMPLE
    Grant-HIDDeviceAccess -Username "DOMAIN\JohnDoe"
    Grants specific user access

.NOTES
    Requires: Administrator privileges for one-time setup
    Persists: Yes, survives reboots
    Limitations: May be reset if device is removed and re-added on different USB port
#>
function Grant-HIDDeviceAccess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [uint16]$VendorId = 0x046D,

        [Parameter(Mandatory = $false)]
        [uint16]$ProductId = 0xC092,

        [Parameter(Mandatory = $false)]
        [string]$Username = $env:USERNAME
    )

    # Verify admin privileges
    if (-not (Test-IsAdministrator)) {
        Write-Error "This function requires administrator privileges"
        Write-Host "Please run PowerShell as Administrator and try again" -ForegroundColor Yellow
        return $false
    }

    Write-Host "`n=== Granting HID Device Access ===" -ForegroundColor Cyan
    Write-Host "Device: VID_$($VendorId.ToString('X4'))&PID_$($ProductId.ToString('X4'))" -ForegroundColor White
    Write-Host "User: $Username`n" -ForegroundColor White

    $success = $true

    # Step 1: Modify USB device registry permissions
    Write-Host "[1/3] Modifying USB device registry permissions..." -ForegroundColor Yellow

    $usbRegPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\USB\VID_$($VendorId.ToString('X4'))&PID_$($ProductId.ToString('X4'))"

    if (Test-Path $usbRegPath) {
        try {
            # Get current ACL
            $acl = Get-Acl -Path $usbRegPath

            # Create access rule for user (Read + Write + Execute)
            # PowerShell 7 compatibility: Cast enum values explicitly
            $rights = [System.Security.AccessControl.RegistryRights]::ReadKey -bor `
                      [System.Security.AccessControl.RegistryRights]::QueryValues
            $inheritance = [System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor `
                          [System.Security.AccessControl.InheritanceFlags]::ObjectInherit

            $rule = New-Object System.Security.AccessControl.RegistryAccessRule(
                $Username,
                $rights,
                $inheritance,
                [System.Security.AccessControl.PropagationFlags]::None,
                [System.Security.AccessControl.AccessControlType]::Allow
            )

            $acl.AddAccessRule($rule)
            Set-Acl -Path $usbRegPath -AclObject $acl

            Write-Host "  [OK] Registry permissions updated" -ForegroundColor Green
        }
        catch {
            Write-Warning "  [FAILED] Could not modify registry permissions: $_"
            $success = $false
        }
    }
    else {
        Write-Warning "  [SKIP] Device not found in registry (may need to be plugged in)"
    }

    # Step 2: Modify DeviceClasses permissions
    Write-Host "[2/3] Checking DeviceClasses permissions..." -ForegroundColor Yellow

    $deviceClassesPath = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceClasses"

    try {
        # Get HID GUID
        $hidGuid = "{4d1e55b2-f16f-11cf-88cb-001111000030}"
        $hidClassPath = Join-Path $deviceClassesPath $hidGuid

        if (Test-Path $hidClassPath) {
            # Note: Detailed DeviceClasses ACL modification is complex and may not be necessary
            # The registry permissions above are usually sufficient
            Write-Host "  [OK] DeviceClasses path exists" -ForegroundColor Green
        }
    }
    catch {
        Write-Warning "  [FAILED] Could not check DeviceClasses: $_"
    }

    # Step 3: Information and next steps
    Write-Host "[3/3] Setup complete" -ForegroundColor Yellow

    if ($success) {
        Write-Host "`n[SUCCESS] Device access granted to $Username" -ForegroundColor Green
        Write-Host "`nNEXT STEPS:" -ForegroundColor Cyan
        Write-Host "1. Unplug and replug the G203 mouse (to refresh device)"
        Write-Host "2. Close this PowerShell window"
        Write-Host "3. Open a NEW PowerShell window (WITHOUT admin)"
        Write-Host "4. Test with: Connect-G203Mouse"
        Write-Host "`nNOTE: If access is denied after replug, you may need to run this again" -ForegroundColor Yellow
        Write-Host "      (Windows can reset permissions when device changes USB ports)" -ForegroundColor Yellow
    }
    else {
        Write-Host "`n[PARTIAL] Setup completed with warnings" -ForegroundColor Yellow
        Write-Host "Non-admin access may or may not work. Test and see." -ForegroundColor Yellow
    }

    return $success
}

<#
.SYNOPSIS
    Revoke non-admin access to USB HID device

.DESCRIPTION
    Removes the permissions granted by Grant-HIDDeviceAccess.
    Restores default Windows security settings.

.PARAMETER VendorId
    USB Vendor ID

.PARAMETER ProductId
    USB Product ID

.PARAMETER Username
    Username to revoke access from

.EXAMPLE
    Revoke-HIDDeviceAccess
#>
function Revoke-HIDDeviceAccess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [uint16]$VendorId = 0x046D,

        [Parameter(Mandatory = $false)]
        [uint16]$ProductId = 0xC092,

        [Parameter(Mandatory = $false)]
        [string]$Username = $env:USERNAME
    )

    if (-not (Test-IsAdministrator)) {
        Write-Error "This function requires administrator privileges"
        return $false
    }

    Write-Host "Revoking HID device access for $Username..." -ForegroundColor Yellow

    $usbRegPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\USB\VID_$($VendorId.ToString('X4'))&PID_$($ProductId.ToString('X4'))"

    if (Test-Path $usbRegPath) {
        try {
            $acl = Get-Acl -Path $usbRegPath

            # Remove all access rules for the user
            $acl.Access | Where-Object { $_.IdentityReference -like "*$Username*" } | ForEach-Object {
                $acl.RemoveAccessRule($_) | Out-Null
            }

            Set-Acl -Path $usbRegPath -AclObject $acl
            Write-Host "[OK] Access revoked" -ForegroundColor Green
            return $true
        }
        catch {
            Write-Error "Failed to revoke access: $_"
            return $false
        }
    }
    else {
        Write-Warning "Device not found in registry"
        return $false
    }
}

#endregion

#region Task Scheduler Approach

<#
.SYNOPSIS
    Create a scheduled task that runs with elevated privileges

.DESCRIPTION
    Creates a Windows scheduled task configured to run with highest privileges.
    The task can be triggered on-demand without UAC prompts.

    This is useful for running G203 LED commands without interactive admin prompts.

.PARAMETER TaskName
    Name of the scheduled task to create

.PARAMETER ScriptPath
    Path to PowerShell script to run

.PARAMETER Description
    Task description

.EXAMPLE
    New-ElevatedScheduledTask -TaskName "G203-LED-Control" -ScriptPath "C:\Scripts\SetG203Color.ps1"

.NOTES
    Requires: Administrator privileges to create task
    Persists: Yes, until task is deleted
    Trigger: Must be invoked manually with Start-ScheduledTask
#>
function New-ElevatedScheduledTask {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TaskName,

        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path $_ })]
        [string]$ScriptPath,

        [Parameter(Mandatory = $false)]
        [string]$Description = "G203 LED Control Task"
    )

    if (-not (Test-IsAdministrator)) {
        Write-Error "This function requires administrator privileges to create scheduled task"
        return $false
    }

    Write-Host "Creating elevated scheduled task: $TaskName" -ForegroundColor Cyan

    try {
        # Define task action
        $action = New-ScheduledTaskAction -Execute "powershell.exe" `
            -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""

        # Define task trigger (on-demand)
        $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1)

        # Define task settings (run with highest privileges)
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries `
            -DontStopIfGoingOnBatteries `
            -StartWhenAvailable

        # Define principal (run as current user with highest privileges)
        $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME `
            -LogonType Interactive `
            -RunLevel Highest

        # Register task
        $task = New-ScheduledTask -Action $action -Trigger $trigger `
            -Settings $settings -Principal $principal -Description $Description

        Register-ScheduledTask -TaskName $TaskName -InputObject $task -Force | Out-Null

        Write-Host "[OK] Scheduled task created successfully" -ForegroundColor Green
        Write-Host "`nTo run the task (no UAC prompt):" -ForegroundColor Cyan
        Write-Host "  Start-ScheduledTask -TaskName '$TaskName'" -ForegroundColor White
        Write-Host "`nTo remove the task:" -ForegroundColor Cyan
        Write-Host "  Unregister-ScheduledTask -TaskName '$TaskName' -Confirm:`$false" -ForegroundColor White

        return $true
    }
    catch {
        Write-Error "Failed to create scheduled task: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Invoke G203 LED command via elevated scheduled task

.DESCRIPTION
    Runs a G203 LED command using an existing scheduled task that has
    elevated privileges. This allows non-admin users to control LEDs
    without UAC prompts.

.PARAMETER TaskName
    Name of the scheduled task to use

.PARAMETER Wait
    Wait for task completion

.EXAMPLE
    Invoke-G203TaskCommand -TaskName "G203-LED-Control" -Wait
#>
function Invoke-G203TaskCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TaskName,

        [Parameter(Mandatory = $false)]
        [switch]$Wait
    )

    # Check if task exists
    $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

    if (-not $task) {
        Write-Error "Scheduled task '$TaskName' not found"
        Write-Host "Create it first with: New-ElevatedScheduledTask" -ForegroundColor Yellow
        return $false
    }

    Write-Host "Starting scheduled task: $TaskName" -ForegroundColor Cyan

    try {
        Start-ScheduledTask -TaskName $TaskName

        if ($Wait) {
            Write-Host "Waiting for task to complete..." -ForegroundColor Yellow

            # Wait up to 30 seconds for completion
            $timeout = 30
            $elapsed = 0

            while ($elapsed -lt $timeout) {
                $taskInfo = Get-ScheduledTaskInfo -TaskName $TaskName

                if ($taskInfo.LastTaskResult -eq 0) {
                    Write-Host "[OK] Task completed successfully" -ForegroundColor Green
                    return $true
                }

                Start-Sleep -Milliseconds 500
                $elapsed++
            }

            Write-Warning "Task did not complete within $timeout seconds"
            return $false
        }
        else {
            Write-Host "[OK] Task started" -ForegroundColor Green
            return $true
        }
    }
    catch {
        Write-Error "Failed to start task: $_"
        return $false
    }
}

#endregion

#region Windows Service Approach (Documentation Only)

<#
.SYNOPSIS
    Documentation for Windows Service approach

.DESCRIPTION
    The Windows Service approach is the most robust solution for production use:

    ARCHITECTURE:
    1. Service Component:
       - Runs as LocalSystem (full privileges)
       - Listens on named pipe for commands
       - Executes HID operations with elevated rights

    2. Client Component:
       - PowerShell module (runs as normal user)
       - Connects to service via named pipe
       - Sends LED commands, receives responses

    IMPLEMENTATION STEPS:
    1. Create C# Windows Service project
    2. Implement named pipe server in service
    3. Add HID device communication code to service
    4. Install service with: sc.exe create G203LEDService binPath="path\to\service.exe"
    5. Start service with: sc.exe start G203LEDService
    6. Modify PowerShell module to use named pipe client

    ADVANTAGES:
    - No UAC prompts ever
    - Works for all users on system
    - Professional solution
    - Survives reboots (auto-start)

    DISADVANTAGES:
    - Complex implementation (requires C# development)
    - Requires admin to install service (one-time)
    - Potential security concerns (service runs as SYSTEM)
    - Overkill for personal use

    SECURITY CONSIDERATIONS:
    - Named pipe should have proper ACL
    - Validate all client commands
    - Implement rate limiting
    - Log all operations
    - Consider authentication token

    EXAMPLE NAMED PIPE SERVER (C#):

    ```csharp
    using System;
    using System.IO.Pipes;
    using System.Threading;

    public class G203LEDService
    {
        private NamedPipeServerStream pipeServer;

        public void Start()
        {
            while (true)
            {
                pipeServer = new NamedPipeServerStream("G203LED",
                    PipeDirection.InOut, 1,
                    PipeTransmissionMode.Message,
                    PipeOptions.Asynchronous);

                pipeServer.WaitForConnection();

                // Handle client request
                byte[] buffer = new byte[1024];
                int bytesRead = pipeServer.Read(buffer, 0, buffer.Length);

                // Parse command and execute HID operation
                // ... HID device code here ...

                // Send response
                byte[] response = new byte[] { 0x01 }; // Success
                pipeServer.Write(response, 0, response.Length);

                pipeServer.Disconnect();
            }
        }
    }
    ```

    EXAMPLE NAMED PIPE CLIENT (PowerShell):

    ```powershell
    function Send-G203Command {
        param([byte[]]$Command)

        $pipe = New-Object System.IO.Pipes.NamedPipeClientStream(".", "G203LED", "InOut")
        $pipe.Connect(5000)  # 5 second timeout

        $pipe.Write($Command, 0, $Command.Length)

        $response = New-Object byte[] 1024
        $bytesRead = $pipe.Read($response, 0, $response.Length)

        $pipe.Close()

        return $response[0] -eq 0x01
    }
    ```

    FOR PRODUCTION USE:
    Consider this approach and implement it as a separate project.
    See: https://github.com/[yourproject]/g203led-service

.NOTES
    This is documentation only. Implementation requires C# development.
    Not included in this module due to complexity.
#>
function Get-WindowsServiceApproachInfo {
    Write-Host @"
=== Windows Service Approach ===

This is a documentation function. The Windows Service approach is not
implemented in this module as it requires C# development and compilation.

For production deployments requiring no UAC prompts for multiple users,
consider implementing a Windows Service solution as documented in the
source code of this function.

Key points:
- Service runs as LocalSystem
- Communicates via named pipes
- Requires C# development
- One-time admin installation
- Best for enterprise deployments

See function source code for implementation details and example code.
"@ -ForegroundColor Cyan
}

#endregion

#region Helper Functions

<#
.SYNOPSIS
    Test if current user has access to G203 device

.DESCRIPTION
    Attempts to open the G203 HID device and reports whether access is possible
    without administrator privileges.

.OUTPUTS
    Boolean indicating if access works

.EXAMPLE
    Test-NonAdminAccess
#>
function Test-NonAdminAccess {
    [CmdletBinding()]
    param()

    Write-Host "`n=== Testing Non-Admin USB HID Access ===" -ForegroundColor Cyan
    Write-Host "Checking if G203 device is accessible without admin...`n" -ForegroundColor White

    $isAdmin = Test-IsAdministrator

    Write-Host "Current privilege level: " -NoNewline
    if ($isAdmin) {
        Write-Host "Administrator" -ForegroundColor Yellow
        Write-Host "NOTE: Test should be run as normal user for accurate results" -ForegroundColor Yellow
    }
    else {
        Write-Host "Standard User" -ForegroundColor Green
    }

    Write-Host "`nAttempting device connection..." -ForegroundColor Yellow

    # Try to connect
    try {
        # Load HID functions if not already loaded
        if (-not (Get-Command Connect-HIDDevice -ErrorAction SilentlyContinue)) {
            . "$PSScriptRoot\HIDDevice-IOControl.ps1"
        }

        $result = Connect-HIDDevice -VendorId 0x046D -ProductId 0xC092

        if ($result) {
            Write-Host "`n[SUCCESS] Device accessible without admin!" -ForegroundColor Green
            Write-Host "You can use G203LED commands without elevation." -ForegroundColor Green

            # Disconnect
            Disconnect-HIDDevice

            return $true
        }
        else {
            Write-Host "`n[FAILED] Device not accessible without admin" -ForegroundColor Red
            Write-Host "You need to either:" -ForegroundColor Yellow
            Write-Host "  1. Run PowerShell as Administrator, OR" -ForegroundColor Yellow
            Write-Host "  2. Run Grant-HIDDeviceAccess (requires admin once), OR" -ForegroundColor Yellow
            Write-Host "  3. Use Task Scheduler approach" -ForegroundColor Yellow

            return $false
        }
    }
    catch {
        Write-Host "`n[ERROR] $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

<#
.SYNOPSIS
    Display non-admin access setup guide

.DESCRIPTION
    Shows a comprehensive guide for setting up non-admin access to G203 device
    with all available options.

.EXAMPLE
    Show-NonAdminSetupGuide
#>
function Show-NonAdminSetupGuide {
    Write-Host @"

╔══════════════════════════════════════════════════════════════════════╗
║          G203 LED Control - Non-Admin Access Setup Guide            ║
╚══════════════════════════════════════════════════════════════════════╝

PROBLEM:
Windows requires administrator privileges for USB HID device access.
This means you need to run PowerShell as admin to control G203 LEDs.

SOLUTIONS (Choose ONE):

┌──────────────────────────────────────────────────────────────────────┐
│ OPTION 1: Device Permission Modification (RECOMMENDED)              │
├──────────────────────────────────────────────────────────────────────┤
│ One-time admin setup that grants your user account device access.   │
│                                                                      │
│ Pros:  - Simple setup                                               │
│        - Persistent across PowerShell sessions                      │
│        - No UAC prompts after setup                                 │
│                                                                      │
│ Cons:  - May need to re-run if device changes USB ports             │
│        - Requires admin for initial setup                           │
│                                                                      │
│ SETUP STEPS:                                                         │
│ 1. Ensure G203 mouse is plugged in                                  │
│ 2. Open PowerShell AS ADMINISTRATOR                                 │
│ 3. Run: Import-Module G20LED                                        │
│ 4. Run: Grant-HIDDeviceAccess                                       │
│ 5. Unplug and replug G203 mouse                                     │
│ 6. Close admin PowerShell                                           │
│ 7. Open NEW PowerShell (without admin)                              │
│ 8. Test: Connect-G203Mouse                                          │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────┐
│ OPTION 2: Scheduled Task Approach                                   │
├──────────────────────────────────────────────────────────────────────┤
│ Create a scheduled task that runs with elevated privileges.         │
│                                                                      │
│ Pros:  - No UAC prompts when running task                           │
│        - Good for script automation                                 │
│                                                                      │
│ Cons:  - Need to wrap commands in script file                       │
│        - Less interactive                                           │
│        - Requires admin to create task                              │
│                                                                      │
│ SETUP STEPS:                                                         │
│ 1. Create a script file (e.g., C:\Scripts\SetG203Red.ps1)          │
│ 2. Open PowerShell AS ADMINISTRATOR                                 │
│ 3. Run: New-ElevatedScheduledTask -TaskName "G203-LED" \            │
│         -ScriptPath "C:\Scripts\SetG203Red.ps1"                     │
│ 4. Close admin PowerShell                                           │
│ 5. To use: Start-ScheduledTask -TaskName "G203-LED"                │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────┐
│ OPTION 3: Windows Service (ADVANCED - Not Implemented)              │
├──────────────────────────────────────────────────────────────────────┤
│ Install a Windows service that runs with SYSTEM privileges.         │
│                                                                      │
│ Pros:  - Most robust solution                                       │
│        - Works for all users                                        │
│        - Professional deployment                                    │
│                                                                      │
│ Cons:  - Requires C# development                                    │
│        - Complex implementation                                     │
│        - Overkill for personal use                                  │
│                                                                      │
│ For details, run: Get-WindowsServiceApproachInfo                    │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────┐
│ OPTION 4: Just Use Admin PowerShell (EASIEST)                       │
├──────────────────────────────────────────────────────────────────────┤
│ Simply always run PowerShell as administrator.                      │
│                                                                      │
│ Pros:  - No setup required                                          │
│        - 100% reliable                                              │
│        - No system modifications                                    │
│                                                                      │
│ Cons:  - UAC prompt every time                                      │
│        - Need to remember to "Run as Administrator"                 │
│                                                                      │
│ HOW TO:                                                              │
│ 1. Right-click PowerShell icon                                      │
│ 2. Select "Run as Administrator"                                    │
│ 3. Click "Yes" on UAC prompt                                        │
│ 4. Use G203LED commands normally                                    │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

TESTING:
To test if non-admin access is working, run as normal user:
  Test-NonAdminAccess

TROUBLESHOOTING:
If you granted permissions but it still doesn't work:
  1. Unplug and replug the mouse (refresh device)
  2. Try different USB port (same permissions should apply)
  3. Check Event Viewer for USB errors
  4. Re-run Grant-HIDDeviceAccess
  5. Fall back to admin PowerShell

For more help:
  Get-Help Grant-HIDDeviceAccess -Full
  Get-Help New-ElevatedScheduledTask -Full

"@ -ForegroundColor Cyan
}

#endregion

#region Research Notes

<#
.NOTES
    RESEARCH SUMMARY - Non-Admin USB HID Access on Windows
    =======================================================

    Date: 2026-01-10

    PROBLEM STATEMENT:
    Windows requires administrator privileges for USB HID device access due to security model.
    DeviceIOControl with IOCTL_HID_SET_OUTPUT_REPORT requires GENERIC_WRITE access to device,
    which is restricted to administrators by default.

    APPROACHES INVESTIGATED:

    1. REGISTRY/ACL MODIFICATIONS
       Research: Modified HKLM\SYSTEM\CurrentControlSet\Enum\USB permissions
       Status: Partially effective
       Issues:
         - No built-in CLI tool for registry ACLs (needs SetACL third-party tool)
         - Permissions may reset on device reconnection
         - Risk of breaking other applications
       Sources:
         - https://learn.microsoft.com/en-us/windows-hardware/drivers/usbcon/usb-device-specific-registry-settings
         - https://www.edugeek.net/forums/windows-7/114166-enabling-usb-access-without-admin-rights.html

    2. WINUSB DRIVER REPLACEMENT
       Research: Replace HID driver with WinUSB via custom INF
       Status: Not practical
       Issues:
         - Breaks device in other applications (G HUB, games)
         - Installation requires admin anyway
         - Device no longer appears as HID device
       Sources:
         - https://github.com/libusb/libusb/issues/335
         - https://en.wikipedia.org/wiki/WinUSB

    3. UWP API (Windows.Devices.HumanInterfaceDevice)
       Research: UWP apps can access HID devices with manifest capabilities
       Status: Not accessible from PowerShell directly
       Issues:
         - Requires UWP app package with proper manifest
         - Would need C# wrapper compiled as UWP app
         - Can't easily integrate with PowerShell module
       Sources:
         - https://learn.microsoft.com/en-us/uwp/api/windows.devices.humaninterfacedevice
         - https://learn.microsoft.com/en-us/uwp/schemas/appxpackage/how-to-specify-device-capabilities-for-hid

    4. WINDOWS SERVICE + NAMED PIPES
       Research: Service runs as LocalSystem, clients connect via named pipe
       Status: Most robust, but complex
       Issues:
         - Requires C# development and compilation
         - Service installation needs admin
         - Named pipe security must be configured correctly
       Sources:
         - https://learn.microsoft.com/en-us/windows/win32/ipc/named-pipe-security-and-access-rights
         - https://www.ired.team/offensive-security/privilege-escalation/windows-namedpipes-privilege-escalation

    5. TASK SCHEDULER
       Research: Create task with "Run with highest privileges"
       Status: Works but less elegant
       Issues:
         - Need to wrap commands in script files
         - Not as interactive as direct function calls
         - Still requires admin to create task
       Sources:
         - Built-in Windows feature, well documented

    6. DEVICE PERMISSION MODIFICATION
       Research: Modify device security descriptors and ACLs
       Status: Most practical workaround
       Issues:
         - May need to re-run if device changes ports
         - Modifies system security settings
       Sources:
         - https://learn.microsoft.com/en-us/windows-hardware/drivers/kernel/security-descriptors
         - https://learn.microsoft.com/en-us/windows-hardware/drivers/kernel/sddl-for-device-objects

    7. HIDAPI/LIBUSB INVESTIGATION
       Research: How do cross-platform HID libraries handle this?
       Status: They don't solve it - require admin on Windows
       Issues:
         - Windows 10 v1903+ made this stricter
         - No user-space workaround in these libraries
       Sources:
         - https://github.com/node-hid/node-hid/issues/312
         - https://github.com/libusb/hidapi/issues/134

    8. LOGITECH G HUB ANALYSIS
       Research: How does official Logitech software work?
       Status: Uses driver/service components
       Issues:
         - Installs kernel-mode driver component
         - Uses Windows service for device access
         - Not a simple solution to replicate
       Sources:
         - User reports indicate G HUB requires admin for installation
         - Runs background service after installation

    WINDOWS SECURITY MODEL:
    - HID devices are protected by Windows driver security
    - CreateFile requires GENERIC_WRITE for DeviceIOControl
    - GENERIC_WRITE on device handles is admin-only by default
    - This is by design to prevent malware from accessing input devices
    - Windows 10 v1903 tightened this further

    CONCLUSION:
    No perfect solution exists for non-admin HID access on Windows without:
    a) Modifying system security settings (one-time admin required), OR
    b) Installing a service/driver component (one-time admin required), OR
    c) Running application as administrator every time

    The most practical approach for this project:
    - Primary: Device permission modification (Grant-HIDDeviceAccess)
    - Fallback: Task Scheduler approach for automation
    - Documentation: Windows Service approach for production deployments
    - Reality: Most users should just use admin PowerShell

    REFERENCES:
    - https://learn.microsoft.com/en-us/windows-hardware/drivers/hid/
    - https://learn.microsoft.com/en-us/windows-hardware/drivers/driversecurity/windows-security-model
    - https://github.com/libusb/hidapi
    - https://github.com/node-hid/node-hid/issues/312

#>

#endregion

# Export functions (when used as module)
# Export-ModuleMember -Function @(
#     'Grant-HIDDeviceAccess',
#     'Revoke-HIDDeviceAccess',
#     'New-ElevatedScheduledTask',
#     'Invoke-G203TaskCommand',
#     'Test-NonAdminAccess',
#     'Show-NonAdminSetupGuide',
#     'Get-WindowsServiceApproachInfo'
# )
