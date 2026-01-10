# G20LED - Logitech G203 LIGHTSYNC LED Controller
## Pure PowerShell Module for Windows

✨ Control your Logitech G203 LIGHTSYNC mouse LEDs with simple PowerShell commands

## 🚀 Why Use This?

**100% Native Windows Solution**
- ✅ **Zero Dependencies** - Pure PowerShell using built-in Windows APIs
- ✅ **No Logitech Software** - Direct USB HID control via Windows DeviceIOControl
- ✅ **No External Tools** - No Python, Node.js, or third-party executables
- ✅ **WPF GUI Included** - Native Windows interface (`Show-G203GUI`)
- ✅ **Open Source** - Full transparency, audit the code yourself

**Direct Hardware Access**
- Uses Windows HID API (hidapi) built into every Windows 10/11 system
- Communicates directly with USB device via kernel32.dll and hid.dll
- No middleware, no background services, no registry changes

## ⚡ Quick Start

**Why Administrator?** Direct USB HID device access requires administrator privileges on Windows. This is a Windows security feature - the module talks directly to your mouse hardware via kernel-level APIs (kernel32.dll/hid.dll). Alternative: See "Non-Admin Access" section below for one-time setup.

**Run PowerShell as Administrator, then:**

### Option 1: GUI (Easiest)
```powershell
# Clone or download the repo, then navigate to it
cd path\to\g203led

# Import and launch the GUI
Import-Module .\G20LED.psd1
Show-G203GUI
```
Visual interface with color picker, preset buttons, effects, and live preview!

### Option 2: CLI Commands
```powershell
# Navigate to the module directory
cd path\to\g203led

# Import the module
Import-Module .\G20LED.psd1

# Connect and control
Connect-G203Mouse
Set-G203Color "Red"                                    # Solid red
Set-G203Effect Breathe -Color "Blue" -Speed 3000       # Breathing blue
Set-G203Effect Cycle -Speed 5000                       # Rainbow cycle
Set-G203Brightness 75                                  # 75% brightness
Disconnect-G203Mouse
```

**See all options:** `Show-G203Help`

## 🎮 Features

✅ **Fully Working** - All commands tested and confirmed functional

- **WPF GUI**: Color picker with RGB/HSV sliders, 21 preset buttons, live preview
- **CLI Commands**: 8 PowerShell cmdlets for scripting and automation
- **Solid Colors**: Hex codes (#FF0000), RGB values, or 21 named colors
- **Brightness Control**: 0-100% hardware dimming
- **Effects**: Fixed, Breathe (pulsing), Cycle (rainbow)
- **Built-in Help**: `Show-G203Help` for quick reference
- **No Dependencies**: Pure PowerShell using Windows HID API
- **No Logitech Software**: Direct USB control via DeviceIOControl

## 📦 Installation & First Time Setup

### Choose Your Approach:

**🌟 Recommended: One-Time Setup for Non-Admin Use**
- Run setup once as admin, then use without admin forever!
- Safer than always running as admin
- See "Non-Admin Access" section below

**⚡ Simple: Always Use Admin**
- Right-click PowerShell → "Run as Administrator"
- No setup needed, works immediately

### Import the Module

**Option A: Import Directly (Easiest)**
```powershell
# Navigate to where you cloned/downloaded the repo
cd path\to\g203led

# Import the module
Import-Module .\G20LED.psd1

# Now all commands are available!
Connect-G203Mouse
```

**Option B: Install Permanently**
```powershell
# Copy module to your PowerShell modules folder
$source = Get-Location  # Current directory (where you cloned the repo)
$dest = "$env:USERPROFILE\Documents\PowerShell\Modules\G20LED"
New-Item -ItemType Directory -Path $dest -Force
Copy-Item -Recurse "$source\*" -Destination $dest -Exclude .git

# Import (will be available in future sessions)
Import-Module G20LED

# To auto-load on every PowerShell session:
Add-Content $PROFILE "`nImport-Module G20LED"
```

### Step 3: Verify It Works
```powershell
# Check commands are available
Get-Command -Module G20LED

# Test connection
Connect-G203Mouse
Set-G203Color "Red"
Disconnect-G203Mouse
```

## 🚀 Usage Examples

### Basic Color Control
```powershell
Connect-G203Mouse

# Hex colors
Set-G203Color "#FF0000"          # Red
Set-G203Color "#00FF00"          # Green
Set-G203Color "#0000FF"          # Blue

# Named colors
Set-G203Color "Purple"
Set-G203Color "Cyan"
Set-G203Color "Orange"

# RGB values
Set-G203Color -Red 255 -Green 0 -Blue 255    # Magenta

Disconnect-G203Mouse
```

### Effects
```powershell
Connect-G203Mouse

# Breathing effect
Set-G203Effect Breathe -Color "Blue" -Speed 3000 -Brightness 80

# Rainbow cycle
Set-G203Effect Cycle -Speed 10000

# Adjust brightness
Set-G203Brightness 50

Disconnect-G203Mouse
```

## 📖 Commands Reference

| Command | Description | Example |
|---------|-------------|---------|
| `Show-G203GUI` | Launch WPF GUI | `Show-G203GUI` |
| `Connect-G203Mouse` | Connect to G203 | `Connect-G203Mouse` |
| `Disconnect-G203Mouse` | Disconnect | `Disconnect-G203Mouse` |
| `Set-G203Color` | Set solid color | `Set-G203Color "Red"` |
| `Set-G203Brightness` | Set brightness (0-100%) | `Set-G203Brightness 75` |
| `Set-G203Effect` | Apply effect | `Set-G203Effect Breathe -Color "#FF0000"` |
| `Get-G203Info` | Device information | `Get-G203Info` |
| `Show-G203Help` | Built-in help | `Show-G203Help` |

### Get Detailed Help
```powershell
Get-Help Connect-G203Mouse -Full
Get-Help Set-G203Color -Examples
```

## ⚙️ Device Information

- **Mouse**: Logitech G203 LIGHTSYNC
- **Vendor ID**: 0x046D (Logitech)
- **Product ID**: 0xC092
- **Protocol**: USB HID via DeviceIOControl

---

## 🔓 Non-Admin Access (Recommended)

By default, Windows requires admin for USB device access. But you can do a **one-time setup** to use the module without admin!

### Quick Setup (5 Minutes)

**1. Run This ONCE as Administrator:**
```powershell
# Open PowerShell AS ADMIN (just this once)
# Navigate to where you cloned the repo
cd path\to\g203led

Import-Module .\G20LED.psd1

# Grant yourself permanent access
Grant-HIDDeviceAccess

# Output: [SUCCESS] Device access granted to YourUsername
```

**2. Unplug and Replug Your Mouse**

**3. Test and Use Without Admin:**
```powershell
# Close admin PowerShell, open normal PowerShell
cd path\to\g203led
Import-Module .\G20LED.psd1

# Test if it works
Test-NonAdminAccess

# Use normally without admin!
Connect-G203Mouse
Set-G203Color "Purple"
# Works! No UAC prompt!
```

### What This Does

- Modifies Windows Registry permissions for your G203 device only
- Adds your user account to device ACL
- **Safer** than always running PowerShell as admin
- Permanent (survives reboots)

### Limitations

- May need to re-run if you change USB ports
- May reset after major Windows updates
- G HUB must be closed when using module

### Remove Access Anytime

```powershell
Revoke-HIDDeviceAccess
```

---

## Usage Examples

### Basic Color Control

```powershell
# Import module and connect
Import-Module G20LED
Connect-G203Mouse

# Set solid colors
Set-G203Color -Color "#FF0000"      # Red
Set-G203Color -Color "Blue"         # Named color
Set-G203Color -Red 255 -Green 0 -Blue 255  # Purple via RGB

# Adjust brightness
Set-G203Brightness -Percent 50

# Disconnect when done
Disconnect-G203Mouse
```

### Lighting Effects

```powershell
# Breathing effect (pulsing)
Set-G203Effect -Effect Breathe -Color "#00FF00" -Speed 5000 -Brightness 100

# Color cycle (rainbow)
Set-G203Effect -Effect Cycle -Speed 10000 -Brightness 80

# Fixed color
Set-G203Effect -Effect Fixed -Color "Red" -Brightness 100
```

### Quick Reference

```powershell
# Show all available colors, effects, and examples
Show-G203Help
```

### Device Information

```powershell
# Get device details
Get-G203Info
```

## G203 LIGHTSYNC Protocol Documentation

### USB HID Command Structure

The G203 LIGHTSYNC uses USB HID Feature Reports for LED control. Commands are sent as 20-byte packets.

### Command Format

```
Byte:  0    1    2    3    4    5    6    7    8    9    10   11   12   13   14   15   16   17   18   19
Data: [11] [FF] [0E] [3B] [00] [MM] [RR] [GG] [BB] [SS] [SS] [00] [00] [00] [00] [00] [00] [00] [00] [00]
```

Where:
- `11 FF 0E 3B` - Command header (constant)
- `00` - Zone (always 0x00 for all zones on G203)
- `MM` - Mode:
  - `0x01` = Fixed (solid color)
  - `0x02` = Cycle (rainbow)
  - `0x03` = Breathe (pulsing)
- `RR GG BB` - RGB color values (0x00-0xFF)
- `SS SS` - Speed in milliseconds (big-endian, e.g., 0x1388 = 5000ms)
- Remaining bytes - Padding (0x00)

### Example Commands

**Solid Red:**
```
11 FF 0E 3B 00 01 FF 00 00 00 00 00 00 00 00 00 00 00 00 00
```

**Breathing Blue (5000ms):**
```
11 FF 0E 3B 00 03 00 00 FF 13 88 00 00 00 00 00 00 00 00 00
```

**Color Cycle (10000ms):**
```
11 FF 0E 3B 00 02 00 00 00 27 10 00 00 00 00 00 00 00 00 00
```

### Brightness Control

Brightness is controlled separately via a different command:

```
Byte:  0    1    2    3    4    5    6    7    8    9-19
Data: [11] [FF] [0E] [11] [00] [BB] [00] [00] [00] [00...] (padding)
```

Where `BB` is brightness: 0x00-0x64 (0-100 in decimal)

## Requirements

- Windows 10 or Windows 11
- PowerShell 5.1 or later (built into Windows)
- Logitech G203 LIGHTSYNC mouse

## Project Structure

```
g203led/
├── G20LED.psm1                # Main module file
├── G20LED.psd1                # Module manifest
├── Private/
│   ├── HIDDevice.ps1          # USB HID device class
│   ├── Protocol.ps1           # G203 protocol commands
│   └── ColorHelpers.ps1       # Color parsing utilities
├── Public/
│   ├── Show-G203GUI.ps1       # WPF GUI launcher
│   ├── Connect-G203Mouse.ps1  # Device connection
│   ├── Disconnect-G203Mouse.ps1 # Disconnect
│   ├── Set-G203Color.ps1      # Color control
│   ├── Set-G203Brightness.ps1 # Brightness control
│   ├── Set-G203Effect.ps1     # Lighting effects
│   ├── Get-G203Info.ps1       # Device information
│   └── Show-G203Help.ps1      # Built-in help
├── Tools/
│   └── Find-LogitechDevices.ps1  # Device enumeration
└── README.md
```

## References & Sources

### G203 Protocol Documentation
- [g203-led by smasty](https://github.com/smasty/g203-led) - Original Python implementation
- [g203led by debuti](https://github.com/debuti/g203led) - CLI tool for G203
- [gled by karlovskiy](https://github.com/karlovskiy/gled) - Go implementation
- [g810-led Issue #122](https://github.com/MatMoul/g810-led/issues/122) - Protocol discussion

### HID/USB Tools & Libraries
- [HidLibrary - .NET HID wrapper](https://github.com/mikeobrien/HidLibrary)
- [Windows HID API Documentation](https://learn.microsoft.com/en-us/windows-hardware/drivers/hid/)
- [PowerShell HID Device Access](https://gist.github.com/jchristn/c2e4e0dce46f1586aae4f7c8e9c4d7c1)

## 💡 PowerShell Profile Integration

Add to your PowerShell profile for quick access:

```powershell
# Edit profile
notepad $PROFILE

# Add these lines:
Import-Module G20LED

# Create convenient functions
function led-red { Connect-G203Mouse; Set-G203Color "Red"; Disconnect-G203Mouse }
function led-blue { Connect-G203Mouse; Set-G203Color "Blue"; Disconnect-G203Mouse }
function led-rainbow { Connect-G203Mouse; Set-G203Effect Cycle; Disconnect-G203Mouse }
```

Then just type `led-red` or `led-rainbow` in any PowerShell session!

## 🔧 Troubleshooting

### "Mouse Not Found" Error
1. Verify mouse is plugged in
2. **Close Logitech G HUB** (it blocks direct USB access)
3. Run: `.\Tools\Find-LogitechDevices.ps1` to check detection
4. Try different USB port

### "Permission Denied" / "Access Denied"
**Quick Solution**: Run PowerShell as Administrator
- Right-click PowerShell → "Run as Administrator"
- USB HID access typically requires admin privileges

**Better Solution**: Enable non-admin access (one-time setup)
```powershell
# 1. Run PowerShell AS ADMINISTRATOR (one time)
Import-Module path\to\g203led\G20LED.psd1
Grant-HIDDeviceAccess

# 2. Unplug and replug your G203 mouse

# 3. Close admin PowerShell and open NEW PowerShell (without admin)
# 4. Now you can use G203LED without admin!
Connect-G203Mouse
Set-G203Color "Blue"
```

See [Non-Admin Access Guide](#non-admin-access-experimental) below for details.

### Commands Send But LED Doesn't Change
1. Verify correct Product ID: Should be 0xC092
2. Check if G HUB is running in background
3. Try reconnecting: `Disconnect-G203Mouse; Connect-G203Mouse`
4. Restart computer to clear USB locks

### Get Detailed Diagnostics
```powershell
# Enable verbose output
$VerbosePreference = 'Continue'
Connect-G203Mouse
Set-G203Color "Red"
```

## 🔓 Non-Admin Access (Experimental)

By default, Windows requires administrator privileges for USB HID device access. This means you need to run PowerShell as admin to control your G203 LEDs, which is inconvenient.

**We've researched and implemented solutions to enable non-admin access!**

### Option 1: Device Permission Modification (Recommended)

One-time administrator setup that grants your user account permanent access to the G203 device.

**Setup Steps:**
```powershell
# 1. Ensure G203 mouse is plugged in
# 2. Open PowerShell AS ADMINISTRATOR (one time only)
Import-Module path\to\g203led\G20LED.psd1

# 3. Grant your user access to the device
Grant-HIDDeviceAccess

# 4. Unplug and replug G203 mouse (to refresh device)

# 5. Close admin PowerShell, open NEW PowerShell (WITHOUT admin)

# 6. Test it works!
Test-NonAdminAccess
Connect-G203Mouse
Set-G203Color "Purple"
Disconnect-G203Mouse
```

**Pros:**
- No UAC prompts after setup
- Works across all PowerShell sessions
- Simple and fast

**Cons:**
- May need to re-run if device changes USB ports
- Requires admin for initial setup

### Option 2: Task Scheduler (For Automation)

Create scheduled tasks that run with elevated privileges without UAC prompts.

```powershell
# 1. Create a script file (e.g., C:\Scripts\SetG203Red.ps1)
# 2. Run PowerShell AS ADMINISTRATOR
New-ElevatedScheduledTask -TaskName "G203-Red" -ScriptPath "C:\Scripts\SetG203Red.ps1"

# 3. Run task (no admin needed, no UAC prompt)
Start-ScheduledTask -TaskName "G203-Red"
```

### Option 3: Just Use Admin PowerShell (Easiest)

Simply always run PowerShell as administrator. This is the most reliable method.

**Note:** Windows fundamentally requires admin privileges for HID device write access. The Grant-HIDDeviceAccess function modifies registry permissions to grant your user account persistent access without requiring admin each time.

---

## ✅ Module Status

**Version**: 1.1.0 - Fully Functional + Non-Admin Solutions

- ✅ Device enumeration
- ✅ USB HID communication (DeviceIOControl)
- ✅ WPF GUI with RGB/HSV color pickers
- ✅ CLI command display and clipboard copy
- ✅ Protocol command builders
- ✅ Color control cmdlets (21 named colors + hex + RGB)
- ✅ Effect control cmdlets (Fixed, Breathe, Cycle)
- ✅ Brightness control (hardware dimming)
- ✅ Module packaging
- ✅ Complete documentation
- ✅ Non-admin access solutions

## License

MIT License - See LICENSE file for details

## Contributing

Contributions welcome! Please feel free to submit issues or pull requests.

## Disclaimer

This project is not affiliated with or endorsed by Logitech. Use at your own risk.
The USB protocol was reverse-engineered from publicly available information and existing open-source projects.

---

**Built with PowerShell for Windows** | **No Logitech software required** | **Open Source**
