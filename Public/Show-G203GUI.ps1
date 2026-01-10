<#
.SYNOPSIS
    Show graphical user interface for G203 LED control

.DESCRIPTION
    Launches a WPF-based GUI for controlling Logitech G203 LIGHTSYNC mouse LED lighting.
    Provides color picker, preset buttons, effect controls, and brightness slider with
    live preview functionality.

.EXAMPLE
    Show-G203GUI
    Opens the G203 LED Control GUI window

.NOTES
    Requires Windows PowerShell 5.1+ with WPF support.
    Auto-connects to G203 mouse on startup.
#>
function Show-G203GUI {
    [CmdletBinding()]
    param()

    # Define local wrapper functions for module functions (for use in event handlers)
    function Local-GetClampedRGBValue { param($Value) Get-ClampedRGBValue -Value $Value }
    function Local-ConvertToWPFColor { param($Red, $Green, $Blue) ConvertTo-WPFColor -Red $Red -Green $Green -Blue $Blue }
    function Local-ConvertFromHexString { param($HexString) ConvertFrom-HexString -HexString $HexString }
    function Local-ConvertToHexString { param($Red, $Green, $Blue) ConvertTo-HexString -Red $Red -Green $Green -Blue $Blue }
    function Local-ConvertToRGBBytes { param($Color) ConvertTo-RGBBytes -Color $Color }
    function Local-GetAvailableColors { Get-AvailableColors }
    function Local-ConvertFromRGBBytes { param($Red, $Green, $Blue) ConvertFrom-RGBBytes -Red $Red -Green $Green -Blue $Blue }
    function Local-ConvertToHSV { param($Red, $Green, $Blue) ConvertTo-HSV -Red $Red -Green $Green -Blue $Blue }
    function Local-ConvertFromHSV { param($Hue, $Saturation, $Value) ConvertFrom-HSV -Hue $Hue -Saturation $Saturation -Value $Value }

    # Load required assemblies
    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName PresentationCore
    Add-Type -AssemblyName WindowsBase

    # XAML layout definition
    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="G203 LED Control"
        Height="650" Width="500"
        MinHeight="600" MinWidth="450"
        ResizeMode="CanResize"
        WindowStartupLocation="CenterScreen">
    <Window.Resources>
        <Style TargetType="GroupBox">
            <Setter Property="Margin" Value="10,5,10,5"/>
            <Setter Property="Padding" Value="10"/>
        </Style>
        <Style TargetType="TextBox">
            <Setter Property="Margin" Value="5,2,5,2"/>
            <Setter Property="Padding" Value="5,3,5,3"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
        </Style>
        <Style TargetType="Button">
            <Setter Property="Margin" Value="5,5,5,5"/>
            <Setter Property="Padding" Value="15,5,15,5"/>
            <Setter Property="MinWidth" Value="80"/>
        </Style>
        <Style TargetType="Label">
            <Setter Property="Margin" Value="5,2,5,2"/>
        </Style>
    </Window.Resources>

    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Status Bar (Top) -->
        <Border Grid.Row="0" Background="#F0F0F0" BorderBrush="#CCCCCC" BorderThickness="0,0,0,1" Padding="10,5">
            <StackPanel Orientation="Horizontal">
                <Label Content="Status:" FontWeight="Bold"/>
                <Label Name="StatusLabel" Content="Disconnected" Foreground="Red"/>
            </StackPanel>
        </Border>

        <!-- Main Content -->
        <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
            <StackPanel>
                <!-- Color Selection -->
                <GroupBox Header="Color Selection" FontWeight="Bold">
                    <StackPanel>
                        <!-- RGB Inputs -->
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="80"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="100"/>
                            </Grid.ColumnDefinitions>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="Auto"/>
                            </Grid.RowDefinitions>

                            <!-- Red -->
                            <Label Grid.Row="0" Grid.Column="0" Content="Red:" VerticalAlignment="Center"/>
                            <TextBox Grid.Row="0" Grid.Column="1" Name="RedTextBox" Text="255" MaxLength="3" ToolTip="Red component (0-255)"/>

                            <!-- Green -->
                            <Label Grid.Row="1" Grid.Column="0" Content="Green:" VerticalAlignment="Center"/>
                            <TextBox Grid.Row="1" Grid.Column="1" Name="GreenTextBox" Text="0" MaxLength="3" ToolTip="Green component (0-255)"/>

                            <!-- Blue -->
                            <Label Grid.Row="2" Grid.Column="0" Content="Blue:" VerticalAlignment="Center"/>
                            <TextBox Grid.Row="2" Grid.Column="1" Name="BlueTextBox" Text="0" MaxLength="3" ToolTip="Blue component (0-255)"/>

                            <!-- Color Preview -->
                            <Label Grid.Row="0" Grid.Column="3" Content="Preview:" VerticalAlignment="Center"/>
                            <Border Grid.Row="0" Grid.Column="4" Grid.RowSpan="3" BorderBrush="Gray" BorderThickness="1" Margin="5">
                                <Rectangle Name="ColorPreviewRectangle" Fill="Red" Height="60" ToolTip="Color preview"/>
                            </Border>

                            <!-- Hex -->
                            <Label Grid.Row="3" Grid.Column="0" Content="Hex:" VerticalAlignment="Center"/>
                            <TextBox Grid.Row="3" Grid.Column="1" Grid.ColumnSpan="2" Name="HexTextBox" Text="#FF0000" MaxLength="7" ToolTip="Hex color code (#RRGGBB)"/>
                        </Grid>

                        <!-- HSV Sliders -->
                        <Label Content="HSV Color Picker:" FontWeight="Bold" Margin="5,15,5,5"/>
                        <Grid Margin="5">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="Auto"/>
                            </Grid.RowDefinitions>

                            <!-- Hue -->
                            <Label Grid.Row="0" Grid.Column="0" Content="H:" VerticalAlignment="Center"/>
                            <Slider Grid.Row="0" Grid.Column="1" Name="HueSlider" Minimum="0" Maximum="360" Value="0" TickFrequency="10" IsSnapToTickEnabled="False" ToolTip="Hue (0-360 degrees)"/>
                            <Label Grid.Row="0" Grid.Column="2" Name="HueLabel" Content="0" MinWidth="40" HorizontalContentAlignment="Right"/>

                            <!-- Saturation -->
                            <Label Grid.Row="1" Grid.Column="0" Content="S:" VerticalAlignment="Center"/>
                            <Slider Grid.Row="1" Grid.Column="1" Name="SaturationSlider" Minimum="0" Maximum="100" Value="100" TickFrequency="5" IsSnapToTickEnabled="False" ToolTip="Saturation (0-100%)"/>
                            <Label Grid.Row="1" Grid.Column="2" Name="SaturationLabel" Content="100%" MinWidth="40" HorizontalContentAlignment="Right"/>

                            <!-- Value -->
                            <Label Grid.Row="2" Grid.Column="0" Content="V:" VerticalAlignment="Center"/>
                            <Slider Grid.Row="2" Grid.Column="1" Name="ValueSlider" Minimum="0" Maximum="100" Value="100" TickFrequency="5" IsSnapToTickEnabled="False" ToolTip="Value: color lightness (0-100%). Note: LED Brightness slider below dims hardware."/>
                            <Label Grid.Row="2" Grid.Column="2" Name="ValueLabel" Content="100%" MinWidth="40" HorizontalContentAlignment="Right"/>
                        </Grid>

                        <!-- Quick Presets -->
                        <Label Content="Quick Presets:" FontWeight="Bold" Margin="5,15,5,5"/>
                        <WrapPanel Name="PresetButtonsPanel" Margin="5"/>
                    </StackPanel>
                </GroupBox>

                <!-- Effect -->
                <GroupBox Header="Effect" FontWeight="Bold">
                    <StackPanel>
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="Auto"/>
                            </Grid.RowDefinitions>

                            <!-- Effect Type -->
                            <Label Grid.Row="0" Grid.Column="0" Content="Type:" VerticalAlignment="Center"/>
                            <ComboBox Grid.Row="0" Grid.Column="1" Name="EffectComboBox" SelectedIndex="0" Margin="5" ToolTip="Select LED effect type">
                                <ComboBoxItem Content="Fixed"/>
                                <ComboBoxItem Content="Breathe"/>
                                <ComboBoxItem Content="Cycle"/>
                            </ComboBox>

                            <!-- Speed -->
                            <Label Grid.Row="1" Grid.Column="0" Content="Speed:" VerticalAlignment="Center"/>
                            <StackPanel Grid.Row="1" Grid.Column="1" Orientation="Vertical">
                                <Slider Name="SpeedSlider" Minimum="1000" Maximum="65535" Value="5000"
                                        TickFrequency="1000" IsSnapToTickEnabled="False" IsEnabled="False" ToolTip="Effect speed in milliseconds (1000-65535)"/>
                                <Label Name="SpeedLabel" Content="5000ms" HorizontalAlignment="Center"/>
                            </StackPanel>
                        </Grid>
                    </StackPanel>
                </GroupBox>

                <!-- Brightness -->
                <GroupBox Header="LED Brightness (Hardware Dimming)" FontWeight="Bold">
                    <StackPanel>
                        <Slider Name="BrightnessSlider" Minimum="0" Maximum="100" Value="100"
                                TickFrequency="10" IsSnapToTickEnabled="False" ToolTip="LED hardware brightness: dims the entire display (0-100%)"/>
                        <Label Name="BrightnessLabel" Content="100%" HorizontalAlignment="Center"/>
                    </StackPanel>
                </GroupBox>

                <!-- CLI Command Equivalent -->
                <GroupBox Header="PowerShell Command" FontWeight="Bold">
                    <Grid>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="Auto"/>
                        </Grid.ColumnDefinitions>
                        <TextBox Grid.Column="0" Name="CLICommandTextBox" IsReadOnly="True"
                                 TextWrapping="Wrap" Background="#F9F9F9" BorderBrush="#CCCCCC"
                                 Padding="5" FontFamily="Consolas" FontSize="10"
                                 ToolTip="Equivalent PowerShell command for current settings"/>
                        <Button Grid.Column="1" Name="CopyCommandButton" Content="Copy"
                                Padding="10,5" Margin="5,0,0,0"
                                ToolTip="Copy command to clipboard"/>
                    </Grid>
                </GroupBox>

                <!-- Live Preview -->
                <StackPanel Orientation="Horizontal" Margin="15,10,15,10">
                    <CheckBox Name="LivePreviewCheckBox" Content="Live Preview" IsChecked="True" VerticalAlignment="Center" ToolTip="Automatically apply changes after 300ms"/>
                    <Label Content="(Updates apply automatically after 300ms)" Foreground="Gray" FontSize="10"/>
                </StackPanel>
            </StackPanel>
        </ScrollViewer>

        <!-- Bottom Bar (Action Buttons and Error Status) -->
        <Border Grid.Row="2" Background="#F0F0F0" BorderBrush="#CCCCCC" BorderThickness="0,1,0,0" Padding="10">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <!-- Error Status -->
                <Label Grid.Row="0" Name="ErrorStatusLabel" Content="" Foreground="Red" FontSize="11" Height="20"/>

                <!-- Action Buttons -->
                <StackPanel Grid.Row="1" Orientation="Horizontal" HorizontalAlignment="Right">
                    <Button Name="ApplyButton" Content="_Apply" ToolTip="Apply current settings to mouse (Alt+A)"/>
                    <Button Name="ResetButton" Content="_Reset" ToolTip="Reset to defaults: Red, Fixed, 100% (Alt+R)"/>
                    <Button Name="CloseButton" Content="_Close" ToolTip="Disconnect and close window (Alt+C or Esc)"/>
                </StackPanel>
            </Grid>
        </Border>
    </Grid>
</Window>
"@

    # Load XAML
    $reader = New-Object System.Xml.XmlNodeReader $xaml
    $window = [System.Windows.Markup.XamlReader]::Load($reader)

    # Get control references
    $statusLabel = $window.FindName("StatusLabel")
    $errorStatusLabel = $window.FindName("ErrorStatusLabel")
    $redTextBox = $window.FindName("RedTextBox")
    $greenTextBox = $window.FindName("GreenTextBox")
    $blueTextBox = $window.FindName("BlueTextBox")
    $hexTextBox = $window.FindName("HexTextBox")
    $colorPreviewRectangle = $window.FindName("ColorPreviewRectangle")
    $presetButtonsPanel = $window.FindName("PresetButtonsPanel")
    $effectComboBox = $window.FindName("EffectComboBox")
    $speedSlider = $window.FindName("SpeedSlider")
    $speedLabel = $window.FindName("SpeedLabel")
    $brightnessSlider = $window.FindName("BrightnessSlider")
    $brightnessLabel = $window.FindName("BrightnessLabel")
    $hueSlider = $window.FindName("HueSlider")
    $hueLabel = $window.FindName("HueLabel")
    $saturationSlider = $window.FindName("SaturationSlider")
    $saturationLabel = $window.FindName("SaturationLabel")
    $valueSlider = $window.FindName("ValueSlider")
    $valueLabel = $window.FindName("ValueLabel")
    $livePreviewCheckBox = $window.FindName("LivePreviewCheckBox")
    $cliCommandTextBox = $window.FindName("CLICommandTextBox")
    $copyCommandButton = $window.FindName("CopyCommandButton")
    $applyButton = $window.FindName("ApplyButton")
    $resetButton = $window.FindName("ResetButton")
    $closeButton = $window.FindName("CloseButton")

    # Script-level variables for debouncing
    $script:updateTimer = $null
    $script:isUpdatingFromCode = $false

    # Create debouncing timer
    $script:updateTimer = New-Object System.Windows.Threading.DispatcherTimer
    $script:updateTimer.Interval = [TimeSpan]::FromMilliseconds(300)

    # Function to apply current settings to mouse
    $applyCurrentSettings = {
        try {
            # Clear previous errors
            $errorStatusLabel.Content = ""

            # Get current values
            $red = Local-GetClampedRGBValue -Value $redTextBox.Text
            $green = Local-GetClampedRGBValue -Value $greenTextBox.Text
            $blue = Local-GetClampedRGBValue -Value $blueTextBox.Text
            $effect = $effectComboBox.SelectedItem.Content
            $speed = [int]$speedSlider.Value
            $brightness = [int]$brightnessSlider.Value

            Write-Verbose "Applying: RGB($red,$green,$blue) Effect=$effect Speed=$speed Brightness=$brightness"

            # Apply effect based on type (with brightness)
            $result = $false
            switch ($effect) {
                'Fixed' {
                    $result = Set-G203Effect -Effect Fixed -Red $red -Green $green -Blue $blue -Brightness $brightness
                }
                'Breathe' {
                    $result = Set-G203Effect -Effect Breathe -Red $red -Green $green -Blue $blue -Speed $speed -Brightness $brightness
                }
                'Cycle' {
                    $result = Set-G203Effect -Effect Cycle -Speed $speed -Brightness $brightness
                }
            }

            if (-not $result) {
                $errorStatusLabel.Content = "Failed to apply effect. Check connection."
                return
            }
        }
        catch {
            $errorStatusLabel.Content = "Error: $($_.Exception.Message)"
            Write-Error $_
        }
    }

    # Timer tick event
    $script:updateTimer.Add_Tick({
        $script:updateTimer.Stop()
        & $applyCurrentSettings
    })

    # Function to schedule an update
    $scheduleUpdate = {
        if ($livePreviewCheckBox.IsChecked -and -not $script:isUpdatingFromCode) {
            $script:updateTimer.Stop()
            $script:updateTimer.Start()
        }
    }

    # Function to update color preview
    $updateColorPreview = {
        $red = Local-GetClampedRGBValue -Value $redTextBox.Text
        $green = Local-GetClampedRGBValue -Value $greenTextBox.Text
        $blue = Local-GetClampedRGBValue -Value $blueTextBox.Text

        $wpfColor = Local-ConvertToWPFColor -Red $red -Green $green -Blue $blue
        $colorPreviewRectangle.Fill = New-Object System.Windows.Media.SolidColorBrush $wpfColor
    }

    # Function to update CLI command display
    $updateCLICommand = {
        $red = Local-GetClampedRGBValue -Value $redTextBox.Text
        $green = Local-GetClampedRGBValue -Value $greenTextBox.Text
        $blue = Local-GetClampedRGBValue -Value $blueTextBox.Text
        $effect = $effectComboBox.SelectedItem.Content
        $speed = [int]$speedSlider.Value
        $brightness = [int]$brightnessSlider.Value

        $cmd = "Connect-G203Mouse`n"

        if ($effect -eq 'Fixed') {
            $cmd += "Set-G203Effect -Effect Fixed -Red $red -Green $green -Blue $blue"
        }
        elseif ($effect -eq 'Breathe') {
            $cmd += "Set-G203Effect -Effect Breathe -Red $red -Green $green -Blue $blue -Speed $speed"
        }
        elseif ($effect -eq 'Cycle') {
            $cmd += "Set-G203Effect -Effect Cycle -Speed $speed"
        }

        if ($brightness -ne 100) {
            $cmd += "`nSet-G203Brightness -Percent $brightness"
        }

        $cliCommandTextBox.Text = $cmd
    }

    # RGB TextBox validation and events
    $rgbTextBoxChanged = {
        param($sender, $e)

        if ($script:isUpdatingFromCode) { return }

        # Validate numeric input
        $text = $sender.Text
        if ($text -match '[^0-9]') {
            $sender.Text = $text -replace '[^0-9]', ''
            $sender.SelectionStart = $sender.Text.Length
        }

        # Update hex, HSV, and preview
        $script:isUpdatingFromCode = $true
        try {
            $red = Local-GetClampedRGBValue -Value $redTextBox.Text
            $green = Local-GetClampedRGBValue -Value $greenTextBox.Text
            $blue = Local-GetClampedRGBValue -Value $blueTextBox.Text

            $hexTextBox.Text = Local-ConvertToHexString -Red $red -Green $green -Blue $blue

            # Update HSV sliders
            $hsv = Local-ConvertToHSV -Red $red -Green $green -Blue $blue
            $hueSlider.Value = $hsv.H
            $saturationSlider.Value = $hsv.S
            $valueSlider.Value = $hsv.V

            & $updateColorPreview
            & $updateCLICommand
        }
        finally {
            $script:isUpdatingFromCode = $false
        }

        & $scheduleUpdate
    }

    $redTextBox.Add_TextChanged($rgbTextBoxChanged)
    $greenTextBox.Add_TextChanged($rgbTextBoxChanged)
    $blueTextBox.Add_TextChanged($rgbTextBoxChanged)

    # Hex TextBox event
    $hexTextBox.Add_TextChanged({
        if ($script:isUpdatingFromCode) { return }

        $hexValue = $hexTextBox.Text
        $rgb = Local-ConvertFromHexString -HexString $hexValue

        if ($rgb) {
            $script:isUpdatingFromCode = $true
            try {
                $redTextBox.Text = $rgb.Red.ToString()
                $greenTextBox.Text = $rgb.Green.ToString()
                $blueTextBox.Text = $rgb.Blue.ToString()
                & $updateColorPreview
                & $updateCLICommand
            }
            finally {
                $script:isUpdatingFromCode = $false
            }

            & $scheduleUpdate
        }
    })

    # Create preset buttons
    $colors = Local-GetAvailableColors
    foreach ($colorName in $colors) {
        $button = New-Object System.Windows.Controls.Button
        $button.Content = $colorName
        $button.MinWidth = 70
        $button.Margin = New-Object System.Windows.Thickness(3)
        $button.Padding = New-Object System.Windows.Thickness(8, 4, 8, 4)

        # Set button background color
        $rgb = Local-ConvertToRGBBytes -Color $colorName
        $wpfColor = Local-ConvertToWPFColor -Red $rgb.Red -Green $rgb.Green -Blue $rgb.Blue
        $button.Background = New-Object System.Windows.Media.SolidColorBrush $wpfColor

        # Set text color based on brightness
        $brightness = ($rgb.Red * 0.299 + $rgb.Green * 0.587 + $rgb.Blue * 0.114)
        if ($brightness -lt 128) {
            $button.Foreground = [System.Windows.Media.Brushes]::White
        }
        else {
            $button.Foreground = [System.Windows.Media.Brushes]::Black
        }

        # Click event - store RGB values in button Tag to avoid function call issues
        $button.Tag = @{ R = $rgb.Red; G = $rgb.Green; B = $rgb.Blue }
        $button.Add_Click({
            param($sender, $e)
            $rgbValues = $sender.Tag

            $script:isUpdatingFromCode = $true
            try {
                $redTextBox.Text = $rgbValues.R.ToString()
                $greenTextBox.Text = $rgbValues.G.ToString()
                $blueTextBox.Text = $rgbValues.B.ToString()
            }
            finally {
                $script:isUpdatingFromCode = $false
            }

            & $scheduleUpdate
        }.GetNewClosure())

        $presetButtonsPanel.Children.Add($button) | Out-Null
    }

    # Effect ComboBox event
    $effectComboBox.Add_SelectionChanged({
        $effect = $effectComboBox.SelectedItem.Content

        # Enable/disable speed slider based on effect
        if ($effect -eq 'Fixed') {
            $speedSlider.IsEnabled = $false
        }
        else {
            $speedSlider.IsEnabled = $true

            # Set default speed
            if ($effect -eq 'Breathe') {
                $speedSlider.Value = 5000
            }
            elseif ($effect -eq 'Cycle') {
                $speedSlider.Value = 10000
            }
        }

        & $updateCLICommand
        & $scheduleUpdate
    })

    # Speed slider event
    $speedSlider.Add_ValueChanged({
        $speedLabel.Content = "$([int]$speedSlider.Value)ms"
        & $updateCLICommand
        & $scheduleUpdate
    })

    # Brightness slider event
    $brightnessSlider.Add_ValueChanged({
        $brightnessLabel.Content = "$([int]$brightnessSlider.Value)%"
        & $updateCLICommand
        & $scheduleUpdate
    })

    # HSV slider events
    $hueSlider.Add_ValueChanged({
        if ($script:isUpdatingFromCode) { return }
        $hueLabel.Content = "$([int]$hueSlider.Value)"

        # Convert HSV to RGB and update RGB controls
        $script:isUpdatingFromCode = $true
        try {
            $rgb = Local-ConvertFromHSV -Hue ([int]$hueSlider.Value) -Saturation ([int]$saturationSlider.Value) -Value ([int]$valueSlider.Value)
            $redTextBox.Text = $rgb.Red.ToString()
            $greenTextBox.Text = $rgb.Green.ToString()
            $blueTextBox.Text = $rgb.Blue.ToString()
        }
        finally {
            $script:isUpdatingFromCode = $false
        }

        & $scheduleUpdate
    })

    $saturationSlider.Add_ValueChanged({
        if ($script:isUpdatingFromCode) { return }
        $saturationLabel.Content = "$([int]$saturationSlider.Value)%"

        # Convert HSV to RGB and update RGB controls
        $script:isUpdatingFromCode = $true
        try {
            $rgb = Local-ConvertFromHSV -Hue ([int]$hueSlider.Value) -Saturation ([int]$saturationSlider.Value) -Value ([int]$valueSlider.Value)
            $redTextBox.Text = $rgb.Red.ToString()
            $greenTextBox.Text = $rgb.Green.ToString()
            $blueTextBox.Text = $rgb.Blue.ToString()
        }
        finally {
            $script:isUpdatingFromCode = $false
        }

        & $scheduleUpdate
    })

    $valueSlider.Add_ValueChanged({
        if ($script:isUpdatingFromCode) { return }
        $valueLabel.Content = "$([int]$valueSlider.Value)%"

        # Convert HSV to RGB and update RGB controls
        $script:isUpdatingFromCode = $true
        try {
            $rgb = Local-ConvertFromHSV -Hue ([int]$hueSlider.Value) -Saturation ([int]$saturationSlider.Value) -Value ([int]$valueSlider.Value)
            $redTextBox.Text = $rgb.Red.ToString()
            $greenTextBox.Text = $rgb.Green.ToString()
            $blueTextBox.Text = $rgb.Blue.ToString()
        }
        finally {
            $script:isUpdatingFromCode = $false
        }

        & $scheduleUpdate
    })

    # Copy command button
    $copyCommandButton.Add_Click({
        [System.Windows.Clipboard]::SetText($cliCommandTextBox.Text)
        $copyCommandButton.Content = "Copied!"
        Start-Sleep -Milliseconds 1000
        $copyCommandButton.Content = "Copy"
    })

    # Apply button
    $applyButton.Add_Click({
        & $applyCurrentSettings
    })

    # Reset button
    $resetButton.Add_Click({
        $script:isUpdatingFromCode = $true
        try {
            $redTextBox.Text = "255"
            $greenTextBox.Text = "0"
            $blueTextBox.Text = "0"
            $effectComboBox.SelectedIndex = 0
            $brightnessSlider.Value = 100
        }
        finally {
            $script:isUpdatingFromCode = $false
        }

        & $applyCurrentSettings
    })

    # Close button
    $closeButton.Add_Click({
        try {
            # Stop timer
            if ($script:updateTimer) {
                $script:updateTimer.Stop()
            }

            # Disconnect from device
            Disconnect-G203Mouse
            Write-Host "Disconnected from G203 mouse" -ForegroundColor Yellow
        }
        catch {
            Write-Warning "Error disconnecting: $_"
        }
        finally {
            $window.Close()
        }
    })

    # Window closing event
    $window.Add_Closing({
        try {
            # Stop and dispose timer
            if ($script:updateTimer) {
                $script:updateTimer.Stop()
                $script:updateTimer = $null
            }

            # Disconnect from device
            Disconnect-G203Mouse

            Write-Verbose "GUI cleanup completed"
        }
        catch {
            Write-Warning "Error during cleanup: $_"
        }
    })

    # Keyboard shortcuts
    $window.Add_KeyDown({
        param($sender, $e)
        if ($e.Key -eq [System.Windows.Input.Key]::Escape) {
            $closeButton.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Button]::ClickEvent)))
        }
    })

    # Auto-connect on startup
    try {
        Write-Host "Connecting to G203 mouse..." -ForegroundColor Cyan
        $connected = Connect-G203Mouse

        if ($connected) {
            $statusLabel.Content = "Connected"
            $statusLabel.Foreground = "Green"
            Write-Host "Connected successfully!" -ForegroundColor Green

            # Apply initial settings
            & $applyCurrentSettings
            & $updateCLICommand
        }
        else {
            $statusLabel.Content = "Disconnected"
            $statusLabel.Foreground = "Red"

            $result = Show-WarningDialog -Message "Failed to connect to G203 mouse.`n`nMake sure:`n- G203 mouse is plugged in`n- Logitech G HUB is closed`n- Running as Administrator`n`nContinue anyway?" -Title "Connection Failed" -Buttons ([System.Windows.MessageBoxButton]::YesNo)

            if ($result -eq [System.Windows.MessageBoxResult]::No) {
                return
            }
        }
    }
    catch {
        $statusLabel.Content = "Connection Error"
        $statusLabel.Foreground = "Red"
        $errorStatusLabel.Content = "Error: $($_.Exception.Message)"
        Write-Error $_
    }

    # Show window
    $window.ShowDialog() | Out-Null
}
