@{
    # Script module or binary module file associated with this manifest
    RootModule = 'G20LED.psm1'

    # Version number of this module
    ModuleVersion = '1.0.0'

    # Supported PSEditions
    CompatiblePSEditions = @('Desktop')

    # ID used to uniquely identify this module
    GUID = 'a8f7e3d1-9c2b-4a6f-8d7e-1f3a5c9b2d4e'

    # Author of this module
    Author = 'Christopher Bonnstetter'

    # Company or vendor of this module
    CompanyName = ''

    # Copyright statement for this module
    Copyright = '(c) 2024 Christopher Bonnstetter. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'Control LED lighting on Logitech G203 LIGHTSYNC mouse without Logitech G HUB software. Provides PowerShell cmdlets for direct USB HID control of colors, effects, brightness, and presets.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @()

    # Assemblies that must be loaded prior to importing this module
    RequiredAssemblies = @()

    # Script files (.ps1) that are run in the caller's environment prior to importing this module
    ScriptsToProcess = @()

    # Type files (.ps1xml) to be loaded when importing this module
    TypesToProcess = @()

    # Format files (.ps1xml) to be loaded when importing this module
    FormatsToProcess = @()

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    NestedModules = @()

    # Functions to export from this module
    FunctionsToExport = @(
        'Connect-G203Mouse',
        'Disconnect-G203Mouse',
        'Get-G203Info',
        'Set-G203Color',
        'Set-G203Brightness',
        'Set-G203Effect',
        'Show-G203Help',
        'Show-G203GUI'
    )

    # Cmdlets to export from this module
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport = @()

    # DSC resources to export from this module
    DscResourcesToExport = @()

    # List of all modules packaged with this module
    ModuleList = @()

    # List of all files packaged with this module
    FileList = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module to aid in online gallery searches
            Tags = @(
                'Logitech',
                'G203',
                'LIGHTSYNC',
                'LED',
                'RGB',
                'Gaming',
                'Mouse',
                'USB',
                'HID',
                'Lighting'
            )

            # A URL to the license for this module
            LicenseUri = ''

            # A URL to the main website for this project
            ProjectUri = ''

            # A URL to an icon representing this module
            IconUri = ''

            # ReleaseNotes of this module
            ReleaseNotes = @'
Version 1.0.0
- Initial release
- Full LED control for Logitech G203 LIGHTSYNC
- Solid color control with hex and named colors
- Effects: Breathe (pulsing) and Cycle (rainbow)
- Brightness control (0-100%)
- Graphical user interface (Show-G203GUI) with color picker, preset buttons, and live preview
- Direct USB HID communication (no Logitech software required)
- Administrator privilege checking and elevation support
- PowerShell 5.1+ compatible
- Windows 10/11 support
'@

            # Prerelease string of this module
            Prerelease = ''

            # Flag to indicate whether the module requires explicit user acceptance for install/update/save
            RequireLicenseAcceptance = $false

            # External dependent modules of this module
            ExternalModuleDependencies = @()

        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    HelpInfoURI = ''

    # Default prefix for commands exported from this module
    DefaultCommandPrefix = ''
}
