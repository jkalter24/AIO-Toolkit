# PSScriptAnalyzer: disable=PSUseApprovedVerbs
# Cipher System Check v7 - WPF GUI Dashboard
# Modern visual interface for diagnostics and repair management.

param(
    [switch]$TestMode
)

$ErrorActionPreference = 'SilentlyContinue'
$WarningPreference = 'SilentlyContinue'

# Load configuration before any UI setup.
$configPath = Join-Path $PSScriptRoot 'Cipher-System-Check-Config.psd1'
$script:Config = @{
    Logging = @{ UseLocalAppData = $true; FallbackFolder = 'Desktop\CipherCheck\Logs' }
    Performance = @{ GUIPollingIntervalMs = 250 }
}
if (Test-Path $configPath) {
    try {
        $script:Config = Import-PowerShellDataFile $configPath
    } catch {
        # Keep the GUI usable if a local config is malformed.
    }
}

Add-Type -AssemblyName PresentationCore, PresentationFramework, WindowsBase

#region XAML Definition
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Cipher System Check v7"
        Width="1320"
        Height="860"
        MinWidth="1100"
        MinHeight="720"
        WindowStartupLocation="CenterScreen"
        Background="#0B0F14"
        FontFamily="Segoe UI"
        FontSize="12"
        Foreground="#EAF0F7">
    <Window.Resources>
        <LinearGradientBrush x:Key="AppBackgroundBrush" StartPoint="0,0" EndPoint="1,1">
            <GradientStop Color="#080B10" Offset="0"/>
            <GradientStop Color="#0D1320" Offset="0.55"/>
            <GradientStop Color="#091118" Offset="1"/>
        </LinearGradientBrush>
        <SolidColorBrush x:Key="PanelBrush" Color="#101722"/>
        <SolidColorBrush x:Key="PanelAltBrush" Color="#131D2B"/>
        <SolidColorBrush x:Key="PanelRaisedBrush" Color="#172233"/>
        <SolidColorBrush x:Key="BorderBrushSoft" Color="#263549"/>
        <SolidColorBrush x:Key="TextPrimaryBrush" Color="#F4F8FC"/>
        <SolidColorBrush x:Key="TextSecondaryBrush" Color="#A8B4C4"/>
        <SolidColorBrush x:Key="TextMutedBrush" Color="#718096"/>
        <SolidColorBrush x:Key="AccentBrush" Color="#2A8FBD"/>
        <SolidColorBrush x:Key="AccentGreenBrush" Color="#1E8F4D"/>
        <SolidColorBrush x:Key="AccentAmberBrush" Color="#D97706"/>
        <SolidColorBrush x:Key="DangerBrush" Color="#EF4444"/>

        <Style x:Key="SectionLabelStyle" TargetType="TextBlock">
            <Setter Property="Foreground" Value="{StaticResource TextMutedBrush}"/>
            <Setter Property="FontSize" Value="11"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Margin" Value="0,16,0,8"/>
        </Style>

        <Style x:Key="PrimaryButtonStyle" TargetType="Button">
            <Setter Property="Foreground" Value="#F4F8FC"/>
            <Setter Property="Background" Value="{StaticResource AccentBrush}"/>
            <Setter Property="BorderBrush" Value="#1E5E7A"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="16,10"/>
            <Setter Property="Height" Value="42"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Bd" Background="{TemplateBinding Background}" CornerRadius="10" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}" VerticalAlignment="{TemplateBinding VerticalContentAlignment}"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Opacity" Value="0.92"/></Trigger>
                            <Trigger Property="IsPressed" Value="True"><Setter TargetName="Bd" Property="Opacity" Value="0.78"/></Trigger>
                            <Trigger Property="IsEnabled" Value="False"><Setter TargetName="Bd" Property="Opacity" Value="0.45"/></Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="AccentButtonStyle" TargetType="Button" BasedOn="{StaticResource PrimaryButtonStyle}">
            <Setter Property="Background" Value="{StaticResource AccentGreenBrush}"/>
            <Setter Property="Foreground" Value="{StaticResource TextPrimaryBrush}"/>
        </Style>

        <Style x:Key="NavButtonStyle" TargetType="Button" BasedOn="{StaticResource PrimaryButtonStyle}">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="{StaticResource TextSecondaryBrush}"/>
            <Setter Property="BorderBrush" Value="Transparent"/>
            <Setter Property="HorizontalContentAlignment" Value="Left"/>
            <Setter Property="Height" Value="36"/>
            <Setter Property="Padding" Value="12,7"/>
            <Setter Property="Margin" Value="0,0,0,6"/>
            <Setter Property="FontWeight" Value="Normal"/>
        </Style>

        <Style x:Key="StatCardStyle" TargetType="Border">
            <Setter Property="Background" Value="{StaticResource PanelBrush}"/>
            <Setter Property="BorderBrush" Value="{StaticResource BorderBrushSoft}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="CornerRadius" Value="16"/>
            <Setter Property="Padding" Value="16"/>
            <Setter Property="Margin" Value="0,0,12,12"/>
        </Style>

        <Style TargetType="TabControl">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="BorderThickness" Value="0"/>
        </Style>
        <Style TargetType="TabItem">
            <Setter Property="Foreground" Value="{StaticResource TextSecondaryBrush}"/>
            <Setter Property="Background" Value="#101722"/>
            <Setter Property="Padding" Value="14,9"/>
            <Setter Property="Margin" Value="0,0,8,0"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TabItem">
                        <Border x:Name="Bd" Background="{TemplateBinding Background}" CornerRadius="10" BorderBrush="{StaticResource BorderBrushSoft}" BorderThickness="1" Padding="{TemplateBinding Padding}">
                            <ContentPresenter ContentSource="Header" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="#123049"/>
                                <Setter Property="Foreground" Value="{StaticResource TextPrimaryBrush}"/>
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Background" Value="#182538"/></Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="DataGrid">
            <Setter Property="Background" Value="#0F1722"/>
            <Setter Property="Foreground" Value="{StaticResource TextPrimaryBrush}"/>
            <Setter Property="RowBackground" Value="#111B29"/>
            <Setter Property="AlternatingRowBackground" Value="#0D1520"/>
            <Setter Property="BorderBrush" Value="{StaticResource BorderBrushSoft}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="GridLinesVisibility" Value="None"/>
            <Setter Property="HeadersVisibility" Value="Column"/>
            <Setter Property="HorizontalGridLinesBrush" Value="#223044"/>
            <Setter Property="VerticalGridLinesBrush" Value="#223044"/>
            <Setter Property="RowHeaderWidth" Value="0"/>
            <Setter Property="CanUserAddRows" Value="False"/>
            <Setter Property="IsReadOnly" Value="True"/>
            <Setter Property="AutoGenerateColumns" Value="True"/>
        </Style>
        <Style TargetType="DataGridColumnHeader">
            <Setter Property="Background" Value="#172235"/>
            <Setter Property="Foreground" Value="{StaticResource TextPrimaryBrush}"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Padding" Value="10,8"/>
            <Setter Property="BorderBrush" Value="{StaticResource BorderBrushSoft}"/>
        </Style>
        <Style TargetType="DataGridCell">
            <Setter Property="Foreground" Value="{StaticResource TextPrimaryBrush}"/>
            <Setter Property="Padding" Value="8,6"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Style.Triggers>
                <Trigger Property="IsSelected" Value="True">
                    <Setter Property="Background" Value="#123049"/>
                    <Setter Property="Foreground" Value="{StaticResource TextPrimaryBrush}"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        <Style TargetType="ScrollBar">
            <Setter Property="Background" Value="#0B111A"/>
            <Setter Property="Foreground" Value="#334155"/>
            <Setter Property="Width" Value="10"/>
            <Setter Property="MinWidth" Value="10"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ScrollBar">
                        <Grid x:Name="Root" Background="Transparent" Width="{TemplateBinding Width}" Height="{TemplateBinding Height}">
                            <Border Background="#0B111A" CornerRadius="6"/>
                            <Track x:Name="PART_Track" IsDirectionReversed="True" Orientation="{TemplateBinding Orientation}">
                                <Track.DecreaseRepeatButton><RepeatButton Opacity="0" IsTabStop="False" Focusable="False"/></Track.DecreaseRepeatButton>
                                <Track.Thumb><Thumb Background="#334155" Margin="2"/></Track.Thumb>
                                <Track.IncreaseRepeatButton><RepeatButton Opacity="0" IsTabStop="False" Focusable="False"/></Track.IncreaseRepeatButton>
                            </Track>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="TextBox">
            <Setter Property="Background" Value="#0F1722"/>
            <Setter Property="Foreground" Value="{StaticResource TextPrimaryBrush}"/>
            <Setter Property="BorderBrush" Value="{StaticResource BorderBrushSoft}"/>
            <Setter Property="CaretBrush" Value="{StaticResource AccentBrush}"/>
            <Setter Property="SelectionBrush" Value="#245B78"/>
            <Setter Property="SelectionTextBrush" Value="{StaticResource TextPrimaryBrush}"/>
        </Style>
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="{StaticResource TextPrimaryBrush}"/>
            <Setter Property="Margin" Value="0,5,0,4"/>
        </Style>
        <Style TargetType="ComboBoxItem">
            <Setter Property="Background" Value="#111827"/>
            <Setter Property="Foreground" Value="{StaticResource TextPrimaryBrush}"/>
            <Setter Property="Padding" Value="10,7"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ComboBoxItem">
                        <Border x:Name="ItemBorder" Background="{TemplateBinding Background}" Padding="{TemplateBinding Padding}">
                            <ContentPresenter/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsHighlighted" Value="True">
                                <Setter TargetName="ItemBorder" Property="Background" Value="#123049"/>
                            </Trigger>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter TargetName="ItemBorder" Property="Background" Value="#16405F"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="ComboBox">
            <Setter Property="Background" Value="#111827"/>
            <Setter Property="Foreground" Value="{StaticResource TextPrimaryBrush}"/>
            <Setter Property="BorderBrush" Value="{StaticResource BorderBrushSoft}"/>
            <Setter Property="Height" Value="36"/>
            <Setter Property="Padding" Value="10,0"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ComboBox">
                        <Grid>
                            <ToggleButton x:Name="ToggleButton"
                                          Foreground="{StaticResource TextPrimaryBrush}"
                                          Focusable="False"
                                          ClickMode="Press"
                                          IsChecked="{Binding IsDropDownOpen, Mode=TwoWay, RelativeSource={RelativeSource TemplatedParent}}">
                                <ToggleButton.Template>
                                    <ControlTemplate TargetType="ToggleButton">
                                        <Border x:Name="ComboBorder" Background="#111827" BorderBrush="{StaticResource BorderBrushSoft}" BorderThickness="1" CornerRadius="8">
                                            <Grid>
                                                <Grid.ColumnDefinitions>
                                                    <ColumnDefinition Width="*"/>
                                                    <ColumnDefinition Width="34"/>
                                                </Grid.ColumnDefinitions>
                                                <TextBlock Margin="10,0,4,0" VerticalAlignment="Center" HorizontalAlignment="Left" Foreground="{StaticResource TextPrimaryBrush}" Text="{Binding SelectionBoxItem, RelativeSource={RelativeSource AncestorType=ComboBox}}"/>
                                                <TextBlock Grid.Column="1" Text="v" Foreground="{StaticResource TextSecondaryBrush}" HorizontalAlignment="Center" VerticalAlignment="Center" FontWeight="Bold"/>
                                            </Grid>
                                        </Border>
                                        <ControlTemplate.Triggers>
                                            <Trigger Property="IsMouseOver" Value="True">
                                                <Setter TargetName="ComboBorder" Property="BorderBrush" Value="{StaticResource AccentBrush}"/>
                                                <Setter TargetName="ComboBorder" Property="Background" Value="#132033"/>
                                            </Trigger>
                                            <Trigger Property="IsChecked" Value="True">
                                                <Setter TargetName="ComboBorder" Property="BorderBrush" Value="{StaticResource AccentBrush}"/>
                                            </Trigger>
                                        </ControlTemplate.Triggers>
                                    </ControlTemplate>
                                </ToggleButton.Template>
                            </ToggleButton>
                            <Popup x:Name="PART_Popup" Placement="Bottom" IsOpen="{TemplateBinding IsDropDownOpen}" AllowsTransparency="True" Focusable="False" PopupAnimation="Fade">
                                <Border Background="#0F1722" BorderBrush="{StaticResource BorderBrushSoft}" BorderThickness="1" CornerRadius="8" MinWidth="{TemplateBinding ActualWidth}" MaxHeight="240">
                                    <ScrollViewer Margin="0,4" SnapsToDevicePixels="True">
                                        <ItemsPresenter/>
                                    </ScrollViewer>
                                </Border>
                            </Popup>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid Background="{StaticResource AppBackgroundBrush}">
        <Grid.ColumnDefinitions>
            <ColumnDefinition x:Name="LeftCol" Width="298"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>

        <Border Grid.Column="0" Background="#0B111A" BorderBrush="#1D2A3D" BorderThickness="0,0,1,0" Padding="20">
            <DockPanel LastChildFill="True">
                <StackPanel DockPanel.Dock="Top">
                    <Grid Margin="0,0,0,18">
                        <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="44"/></Grid.ColumnDefinitions>
                        <StackPanel>
                            <TextBlock Text="Cipher" Foreground="{StaticResource TextPrimaryBrush}" FontSize="26" FontWeight="Bold"/>
                            <TextBlock Text="System Check v7" Foreground="{StaticResource AccentBrush}" FontSize="13" FontWeight="SemiBold"/>
                        </StackPanel>
                        <Button x:Name="BtnToggleSidebar" Grid.Column="1" Content="&lt;" Style="{StaticResource NavButtonStyle}" Width="36" HorizontalContentAlignment="Center"/>
                    </Grid>

                    <TextBlock Text="WORKFLOWS" Style="{StaticResource SectionLabelStyle}"/>
                    <Button x:Name="DiagnosticsBtn" Content="Run Diagnostics" Style="{StaticResource PrimaryButtonStyle}" Margin="0,0,0,10"/>
                    <Button x:Name="AutoFixBtn" Content="Scan + Recommended Fixes" Style="{StaticResource AccentButtonStyle}" Margin="0,0,0,10"/>
                    <Button x:Name="FullAutoBtn" Content="Full Automation" Style="{StaticResource AccentButtonStyle}" Background="#5B4AB3" Foreground="#F8F5FF" Margin="0,0,0,14"/>

                    <TextBlock Text="AUTOMATION MODE" Style="{StaticResource SectionLabelStyle}"/>
                    <ComboBox x:Name="ModeSelector" Margin="0,0,0,6"/>
                    <TextBlock Text="Safe is conservative. Balanced is recommended. Deep includes memory diagnostics when hardware errors are present." TextWrapping="Wrap" Foreground="{StaticResource TextMutedBrush}" FontSize="11"/>

                    <TextBlock Text="NAVIGATION" Style="{StaticResource SectionLabelStyle}"/>
                    <Button x:Name="NavOverviewBtn" Content="Overview" Style="{StaticResource NavButtonStyle}"/>
                    <Button x:Name="NavSSDBtn" Content="SSD Health" Style="{StaticResource NavButtonStyle}"/>
                    <Button x:Name="NavWHEABtn" Content="Hardware Errors" Style="{StaticResource NavButtonStyle}"/>
                    <Button x:Name="NavTdrBtn" Content="Graphics Timeouts" Style="{StaticResource NavButtonStyle}"/>
                    <Button x:Name="NavRebootBtn" Content="Reboots" Style="{StaticResource NavButtonStyle}"/>
                    <Button x:Name="NavStorageBtn" Content="Storage Timeouts" Style="{StaticResource NavButtonStyle}"/>
                    <Button x:Name="NavRawBtn" Content="Raw Log" Style="{StaticResource NavButtonStyle}"/>
                </StackPanel>

                <ScrollViewer DockPanel.Dock="Bottom" VerticalScrollBarVisibility="Auto" Margin="0,12,0,0">
                    <StackPanel>
                        <TextBlock Text="QUICK SUMMARY" Style="{StaticResource SectionLabelStyle}"/>
                        <Border Background="{StaticResource PanelBrush}" BorderBrush="{StaticResource BorderBrushSoft}" BorderThickness="1" CornerRadius="14" Padding="14" Margin="0,0,0,10">
                            <TextBlock x:Name="QuickSummaryBlock" Text="Start a scan to generate a summary." Foreground="{StaticResource TextSecondaryBrush}" TextWrapping="Wrap"/>
                        </Border>
                        <Button x:Name="CopySummaryBtn" Content="Copy Summary" Style="{StaticResource NavButtonStyle}"/>
                        <Button x:Name="OpenLogsBtn" Content="Open Logs" Style="{StaticResource NavButtonStyle}"/>
                        <Button x:Name="HelpBtn" Content="Help / Glossary" Style="{StaticResource NavButtonStyle}"/>

                        <TextBlock Text="MANUAL REPAIRS" Style="{StaticResource SectionLabelStyle}"/>
                        <Border Background="{StaticResource PanelBrush}" BorderBrush="{StaticResource BorderBrushSoft}" BorderThickness="1" CornerRadius="14" Padding="14">
                            <StackPanel>
                                <CheckBox x:Name="ChkWindowsRepair" Content="Windows Repair"/>
                                <TextBlock Text="Reset update services and repair component store." Foreground="{StaticResource TextMutedBrush}" FontSize="10" Margin="20,0,0,8"/>
                                <CheckBox x:Name="ChkTdrTweak" Content="GPU TDR Tweak"/>
                                <TextBlock Text="Increase GPU timeout tolerance." Foreground="{StaticResource TextMutedBrush}" FontSize="10" Margin="20,0,0,8"/>
                                <CheckBox x:Name="ChkNetReset" Content="Network Reset"/>
                                <TextBlock Text="Reset TCP/IP and Winsock." Foreground="{StaticResource TextMutedBrush}" FontSize="10" Margin="20,0,0,8"/>
                                <CheckBox x:Name="ChkMemDiag" Content="Memory Diagnostics"/>
                                <TextBlock Text="Launch Windows Memory Diagnostic." Foreground="{StaticResource TextMutedBrush}" FontSize="10" Margin="20,0,0,8"/>
                                <CheckBox x:Name="ChkDefenderScan" Content="Full Defender Scan"/>
                                <TextBlock Text="Run a full malware scan." Foreground="{StaticResource TextMutedBrush}" FontSize="10" Margin="20,0,0,0"/>
                            </StackPanel>
                        </Border>
                        <Button x:Name="RepairsBtn" Content="Run Selected Repairs" Style="{StaticResource PrimaryButtonStyle}" Background="#B85C1B" Foreground="#FFF7ED" Margin="0,12,0,0" IsEnabled="False"/>
                    </StackPanel>
                </ScrollViewer>
            </DockPanel>
        </Border>

        <Grid x:Name="MainGrid" Grid.Column="1" Margin="22">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>

            <Border Grid.Row="0" Background="{StaticResource PanelBrush}" BorderBrush="{StaticResource BorderBrushSoft}" BorderThickness="1" CornerRadius="20" Padding="22" Margin="0,0,0,16">
                <Grid>
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="320"/></Grid.ColumnDefinitions>
                    <StackPanel>
                        <TextBlock Text="Diagnostics Dashboard" Foreground="{StaticResource TextPrimaryBrush}" FontSize="28" FontWeight="Bold"/>
                        <TextBlock Text="Hardware, storage, Windows health, and repair recommendations in one place." Foreground="{StaticResource TextSecondaryBrush}" FontSize="13" Margin="0,5,0,0"/>
                        <StackPanel Orientation="Horizontal" Margin="0,16,0,0">
                            <Border Background="#123049" CornerRadius="14" Padding="12,8" Margin="0,0,8,0">
                                <TextBlock x:Name="StatusBlock" Text="Ready" Foreground="{StaticResource TextPrimaryBrush}" FontWeight="SemiBold" TextTrimming="CharacterEllipsis" MaxWidth="1180"/>
                            </Border>
                            <Border Background="#13251B" CornerRadius="14" Padding="12,8">
                                <TextBlock x:Name="PhaseBlock" Text="Phase: idle" Foreground="#86EFAC" FontWeight="SemiBold"/>
                            </Border>
                        </StackPanel>
                    </StackPanel>
                    <TextBlock x:Name="SysInfoBlock" Grid.Column="1" Text="Loading system info..." Foreground="{StaticResource TextSecondaryBrush}" FontFamily="Consolas" FontSize="11" TextWrapping="Wrap" HorizontalAlignment="Right"/>
                </Grid>
            </Border>

            <Grid Grid.Row="1">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>

                <WrapPanel Grid.Row="0" Margin="0,0,0,8">
                    <Border Style="{StaticResource StatCardStyle}" Width="215" Height="104">
                        <StackPanel>
                            <TextBlock Text="Top Issue" Foreground="{StaticResource TextMutedBrush}" FontSize="11" FontWeight="SemiBold"/>
                            <TextBlock x:Name="TopIssueCardText" Text="Awaiting scan" Foreground="{StaticResource TextPrimaryBrush}" FontSize="18" FontWeight="Bold" Margin="0,8,0,0" TextWrapping="Wrap"/>
                        </StackPanel>
                    </Border>
                    <Border Style="{StaticResource StatCardStyle}" Width="170" Height="104">
                        <StackPanel>
                            <TextBlock Text="Findings" Foreground="{StaticResource TextMutedBrush}" FontSize="11" FontWeight="SemiBold"/>
                            <TextBlock x:Name="FindingsCardText" Text="0 total" Foreground="{StaticResource TextPrimaryBrush}" FontSize="26" FontWeight="Bold" Margin="0,8,0,0"/>
                        </StackPanel>
                    </Border>
                    <Border Style="{StaticResource StatCardStyle}" Width="170" Height="104">
                        <StackPanel>
                            <TextBlock Text="Health" Foreground="{StaticResource TextMutedBrush}" FontSize="11" FontWeight="SemiBold"/>
                            <TextBlock x:Name="HealthCardText" Text="Idle" Foreground="{StaticResource AccentBrush}" FontSize="24" FontWeight="Bold" Margin="0,8,0,0"/>
                        </StackPanel>
                    </Border>
                    <Border Style="{StaticResource StatCardStyle}" Width="215" Height="104">
                        <StackPanel>
                            <TextBlock Text="Last Scan" Foreground="{StaticResource TextMutedBrush}" FontSize="11" FontWeight="SemiBold"/>
                            <TextBlock x:Name="LastRunCardText" Text="Not scanned yet" Foreground="{StaticResource TextPrimaryBrush}" FontSize="15" FontWeight="SemiBold" Margin="0,8,0,0" TextWrapping="Wrap"/>
                        </StackPanel>
                    </Border>
                </WrapPanel>

                <TabControl x:Name="ResultsTabs" Grid.Row="1">
                    <TabItem Header="Overview">
                        <Grid Margin="0,14,0,0">
                            <Grid.ColumnDefinitions><ColumnDefinition Width="1.25*"/><ColumnDefinition Width="0.85*"/></Grid.ColumnDefinitions>
                            <Border Background="{StaticResource PanelBrush}" BorderBrush="{StaticResource BorderBrushSoft}" BorderThickness="1" CornerRadius="18" Padding="18" Margin="0,0,12,0">
                                <ScrollViewer VerticalScrollBarVisibility="Auto">
                                    <TextBox x:Name="ResultsOverviewBlock" Text="Start a scan to see results..." IsReadOnly="True" BorderThickness="0" TextWrapping="Wrap" AcceptsReturn="True" FontFamily="Consolas" FontSize="12" Background="Transparent" Foreground="{StaticResource TextPrimaryBrush}"/>
                                </ScrollViewer>
                            </Border>
                            <Border Grid.Column="1" Background="{StaticResource PanelBrush}" BorderBrush="{StaticResource BorderBrushSoft}" BorderThickness="1" CornerRadius="18" Padding="18">
                                <StackPanel>
                                    <TextBlock Text="Live Scan Feed" Foreground="{StaticResource TextPrimaryBrush}" FontSize="18" FontWeight="Bold"/>
                                    <TextBlock Text="Enable advanced view to watch phases, discovered devices, and ETA as the core writes snapshots." Foreground="{StaticResource TextSecondaryBrush}" TextWrapping="Wrap" Margin="0,6,0,12"/>
                                    <CheckBox x:Name="AdvancedLiveCheck" Content="Show live diagnostic feed"/>
                                    <Border x:Name="LiveViewBorder" Visibility="Collapsed" Background="#0C121C" BorderBrush="{StaticResource BorderBrushSoft}" BorderThickness="1" CornerRadius="12" Padding="10" Margin="0,10,0,0">
                                        <TextBox x:Name="LiveViewBox" Text="Waiting for scan progress..." IsReadOnly="True" BorderThickness="0" Background="Transparent" Foreground="{StaticResource TextPrimaryBrush}" FontFamily="Consolas" FontSize="11" TextWrapping="Wrap" AcceptsReturn="True" MinHeight="230" VerticalScrollBarVisibility="Auto"/>
                                    </Border>
                                </StackPanel>
                            </Border>
                        </Grid>
                    </TabItem>

                    <TabItem Header="SSD Health">
                        <Grid Margin="0,14,0,0">
                            <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
                            <Border Background="{StaticResource PanelBrush}" BorderBrush="{StaticResource BorderBrushSoft}" BorderThickness="1" CornerRadius="18" Padding="18" Margin="0,0,0,12">
                                <StackPanel>
                                    <TextBlock Text="SSD Health Overview" Foreground="{StaticResource TextPrimaryBrush}" FontSize="18" FontWeight="Bold"/>
                                    <TextBlock x:Name="SsdEmptyBlock" Text="Run diagnostics to populate drive health cards, temperature bars, wear bars, and reliability counters." Foreground="{StaticResource TextSecondaryBrush}" TextWrapping="Wrap" Margin="0,5,0,12"/>
                                    <WrapPanel x:Name="SsdHealthCards"/>
                                </StackPanel>
                            </Border>
                            <DataGrid x:Name="SSDHealthGrid" Grid.Row="1" AutoGenerateColumns="False">
                                <DataGrid.Columns>
                                    <DataGridTextColumn Header="Drive" Binding="{Binding FriendlyName}" Width="2*"/>
                                    <DataGridTextColumn Header="Media" Binding="{Binding MediaType}" Width="*"/>
                                    <DataGridTextColumn Header="Health" Binding="{Binding HealthStatus}" Width="*"/>
                                    <DataGridTextColumn Header="Temp" Binding="{Binding Temperature}" Width="*"/>
                                    <DataGridTextColumn Header="Wear" Binding="{Binding Wear}" Width="*"/>
                                    <DataGridTextColumn Header="Read Errors" Binding="{Binding ReadErrors}" Width="*"/>
                                    <DataGridTextColumn Header="Write Errors" Binding="{Binding WriteErrors}" Width="*"/>
                                    <DataGridTextColumn Header="Power On" Binding="{Binding PowerOnHours}" Width="*"/>
                                </DataGrid.Columns>
                            </DataGrid>
                        </Grid>
                    </TabItem>

                    <TabItem Header="Hardware Errors">
                        <Grid Margin="0,14,0,0">
                            <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
                            <Border Background="{StaticResource PanelBrush}" BorderBrush="{StaticResource BorderBrushSoft}" BorderThickness="1" CornerRadius="18" Padding="16" Margin="0,0,0,12">
                                <StackPanel>
                                    <TextBlock Text="Hardware Error Events" Foreground="{StaticResource TextPrimaryBrush}" FontSize="18" FontWeight="Bold"/>
                                    <TextBlock x:Name="WheaEmptyBlock" Text="Run diagnostics to populate WHEA hardware error events. No rows means no matching WHEA events were found." Foreground="{StaticResource TextSecondaryBrush}" TextWrapping="Wrap" Margin="0,5,0,0"/>
                                </StackPanel>
                            </Border>
                            <DataGrid x:Name="WHEAGrid" Grid.Row="1" AutoGenerateColumns="True"/>
                        </Grid>
                    </TabItem>
                    <TabItem Header="GPU Timeouts">
                        <Grid Margin="0,14,0,0">
                            <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
                            <Border Background="{StaticResource PanelBrush}" BorderBrush="{StaticResource BorderBrushSoft}" BorderThickness="1" CornerRadius="18" Padding="16" Margin="0,0,0,12">
                                <StackPanel>
                                    <TextBlock Text="Graphics Timeout Events" Foreground="{StaticResource TextPrimaryBrush}" FontSize="18" FontWeight="Bold"/>
                                    <TextBlock x:Name="TdrEmptyBlock" Text="Run diagnostics to populate GPU/TDR timeout events. No rows means no matching graphics timeout events were found." Foreground="{StaticResource TextSecondaryBrush}" TextWrapping="Wrap" Margin="0,5,0,0"/>
                                </StackPanel>
                            </Border>
                            <DataGrid x:Name="TDRGrid" Grid.Row="1" AutoGenerateColumns="True"/>
                        </Grid>
                    </TabItem>
                    <TabItem Header="Reboots">
                        <Grid Margin="0,14,0,0">
                            <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
                            <Border Background="{StaticResource PanelBrush}" BorderBrush="{StaticResource BorderBrushSoft}" BorderThickness="1" CornerRadius="18" Padding="16" Margin="0,0,0,12">
                                <StackPanel>
                                    <TextBlock Text="Unexpected Reboot Events" Foreground="{StaticResource TextPrimaryBrush}" FontSize="18" FontWeight="Bold"/>
                                    <TextBlock x:Name="RebootEmptyBlock" Text="Run diagnostics to populate unexpected shutdown and reboot events. No rows means none were found in the checked window." Foreground="{StaticResource TextSecondaryBrush}" TextWrapping="Wrap" Margin="0,5,0,0"/>
                                </StackPanel>
                            </Border>
                            <DataGrid x:Name="RebootGrid" Grid.Row="1" AutoGenerateColumns="True"/>
                        </Grid>
                    </TabItem>
                    <TabItem Header="Storage Timeouts">
                        <Grid Margin="0,14,0,0">
                            <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
                            <Border Background="{StaticResource PanelBrush}" BorderBrush="{StaticResource BorderBrushSoft}" BorderThickness="1" CornerRadius="18" Padding="16" Margin="0,0,0,12">
                                <StackPanel>
                                    <TextBlock Text="Storage Timeout Events" Foreground="{StaticResource TextPrimaryBrush}" FontSize="18" FontWeight="Bold"/>
                                    <TextBlock x:Name="StorageEmptyBlock" Text="Run diagnostics to populate disk/controller timeout events. No rows means no matching storage timeout events were found." Foreground="{StaticResource TextSecondaryBrush}" TextWrapping="Wrap" Margin="0,5,0,0"/>
                                </StackPanel>
                            </Border>
                            <DataGrid x:Name="StorageGrid" Grid.Row="1" AutoGenerateColumns="True"/>
                        </Grid>
                    </TabItem>
                    <TabItem Header="Raw Log">
                        <TextBox x:Name="RawOutputBox" Margin="0,14,0,0" TextWrapping="Wrap" AcceptsReturn="True" IsReadOnly="True" Padding="14" FontFamily="Consolas" FontSize="11" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto" Text="Run diagnostics to load raw analysis output."/>
                    </TabItem>
                </TabControl>
            </Grid>

            <Border Grid.Row="2" Background="{StaticResource PanelBrush}" BorderBrush="{StaticResource BorderBrushSoft}" BorderThickness="1" CornerRadius="18" Padding="14" Margin="0,16,0,0">
                <StackPanel>
                    <Grid Margin="0,0,0,6">
                        <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="90"/></Grid.ColumnDefinitions>
                        <ProgressBar x:Name="ProgressBar" Height="12" Minimum="0" Maximum="100" Value="0" Foreground="{StaticResource AccentBrush}" Background="#1A2434"/>
                        <TextBlock x:Name="ProgressPercent" Grid.Column="1" Text="0%" Foreground="{StaticResource TextPrimaryBrush}" FontSize="12" FontWeight="SemiBold" HorizontalAlignment="Right" VerticalAlignment="Center"/>
                    </Grid>
                    <Grid>
                        <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                        <TextBlock x:Name="EtaBlock" Text="ETA: Not started" Foreground="{StaticResource TextSecondaryBrush}" FontSize="11"/>
                        <Button x:Name="CancelCoreBtn" Grid.Column="2" Content="Cancel Scan" Visibility="Collapsed" Style="{StaticResource NavButtonStyle}" Width="130" Margin="10,0,0,0"/>
                    </Grid>
                </StackPanel>
            </Border>
        </Grid>
    </Grid>
</Window>
"@
#endregion

$reader = [System.Xml.XmlNodeReader]::new(([xml]$xaml).DocumentElement)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Named controls.
$sysInfoBlock = $window.FindName('SysInfoBlock')
$diagnosticsBtn = $window.FindName('DiagnosticsBtn')
$autoFixBtn = $window.FindName('AutoFixBtn')
$fullAutoBtn = $window.FindName('FullAutoBtn')
$modeSelector = $window.FindName('ModeSelector')
$openLogsBtn = $window.FindName('OpenLogsBtn')
$repairsBtn = $window.FindName('RepairsBtn')
$copySummaryBtn = $window.FindName('CopySummaryBtn')
$navOverviewBtn = $window.FindName('NavOverviewBtn')
$navSSDBtn = $window.FindName('NavSSDBtn')
$navWHEABtn = $window.FindName('NavWHEABtn')
$navTdrBtn = $window.FindName('NavTdrBtn')
$navRebootBtn = $window.FindName('NavRebootBtn')
$navStorageBtn = $window.FindName('NavStorageBtn')
$navRawBtn = $window.FindName('NavRawBtn')
$statusBlock = $window.FindName('StatusBlock')
$phaseBlock = $window.FindName('PhaseBlock')
$etaBlock = $window.FindName('EtaBlock')
$progressBar = $window.FindName('ProgressBar')
$progressPercent = $window.FindName('ProgressPercent')
$quickSummaryBlock = $window.FindName('QuickSummaryBlock')
$topIssueCardText = $window.FindName('TopIssueCardText')
$findingsCardText = $window.FindName('FindingsCardText')
$healthCardText = $window.FindName('HealthCardText')
$lastRunCardText = $window.FindName('LastRunCardText')
$resultsOverviewBlock = $window.FindName('ResultsOverviewBlock')
$resultsTabs = $window.FindName('ResultsTabs')
$advancedLiveCheck = $window.FindName('AdvancedLiveCheck')
$liveViewBorder = $window.FindName('LiveViewBorder')
$liveViewBox = $window.FindName('LiveViewBox')
$ssdHealthGrid = $window.FindName('SSDHealthGrid')
$wheaGrid = $window.FindName('WHEAGrid')
$tdrGrid = $window.FindName('TDRGrid')
$rebootGrid = $window.FindName('RebootGrid')
$storageGrid = $window.FindName('StorageGrid')
$wheaEmptyBlock = $window.FindName('WheaEmptyBlock')
$tdrEmptyBlock = $window.FindName('TdrEmptyBlock')
$rebootEmptyBlock = $window.FindName('RebootEmptyBlock')
$storageEmptyBlock = $window.FindName('StorageEmptyBlock')
$rawOutputBox = $window.FindName('RawOutputBox')
$mainGrid = $window.FindName('MainGrid')
$btnToggleSidebar = $window.FindName('BtnToggleSidebar')
$cancelCoreBtn = $window.FindName('CancelCoreBtn')
$leftCol = $window.FindName('LeftCol')
$helpBtn = $window.FindName('HelpBtn')
$chkWindowsRepair = $window.FindName('ChkWindowsRepair')
$chkTdrTweak = $window.FindName('ChkTdrTweak')
$chkNetReset = $window.FindName('ChkNetReset')
$chkMemDiag = $window.FindName('ChkMemDiag')
$chkDefenderScan = $window.FindName('ChkDefenderScan')
$ssdHealthCards = $window.FindName('SsdHealthCards')
$ssdEmptyBlock = $window.FindName('SsdEmptyBlock')

# Universal log folder (shared with core): prefer a custom folder, then LocalAppData, then the configured fallback.
$LogRoot = $null
if ($script:Config.UserSpecific -and $script:Config.UserSpecific.CustomLogFolder) {
    $LogRoot = $script:Config.UserSpecific.CustomLogFolder
} elseif ($script:Config.Logging.UseLocalAppData -and $env:LOCALAPPDATA) {
    $LogRoot = Join-Path $env:LOCALAPPDATA 'CipherCheck\Logs'
} else {
    $fallbackFolder = if ($script:Config.Logging.FallbackFolder) { $script:Config.Logging.FallbackFolder } else { 'Desktop\CipherCheck\Logs' }
    $LogRoot = Join-Path $env:USERPROFILE $fallbackFolder
}
New-Item -ItemType Directory -Force -Path $LogRoot | Out-Null

$ProgressSnapshotPath = Join-Path $LogRoot 'progress_snapshot.json'
$ProgressTextPath = Join-Path $LogRoot 'progress_snapshot.txt'
$script:CoreProcess = $null
$script:LiveTimer = $null
$script:IsCoreRunActive = $false

function Read-FileWithRetry {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [int]$Attempts = 6,
        [int]$InitialDelayMs = 50
    )

    for ($i = 0; $i -lt $Attempts; $i++) {
        try {
            $fileMode = [System.IO.FileMode]::Open
            $fileAccess = [System.IO.FileAccess]::Read
            $fileShare = [System.IO.FileShare]::ReadWrite -bor [System.IO.FileShare]::Delete
            $fs = [System.IO.File]::Open($Path, $fileMode, $fileAccess, $fileShare)
            try {
                $sr = New-Object System.IO.StreamReader($fs, [System.Text.Encoding]::UTF8)
                $content = $sr.ReadToEnd()
                $sr.Close()
                $fs.Close()
                return $content
            } catch {
                try { if ($sr) { $sr.Close() } } catch { }
                try { if ($fs) { $fs.Close() } } catch { }
                throw
            }
        } catch [System.IO.FileNotFoundException], [System.IO.DirectoryNotFoundException] {
            return $null
        } catch {
            Start-Sleep -Milliseconds ([math]::Max(20, [int]($InitialDelayMs * [math]::Pow(1.8, $i))))
        }
    }

    return $null
}

function Get-ProgressSnapshot {
    try {
        $raw = Read-FileWithRetry -Path $ProgressSnapshotPath -Attempts 8 -InitialDelayMs 40
        if (-not $raw) { return $null }
        return $raw | ConvertFrom-Json
    } catch {
        return $null
    }
}

function Get-IncrementalResults {
    $incrementalPath = Join-Path $LogRoot 'results_incremental.json'
    try {
        $raw = Read-FileWithRetry -Path $incrementalPath -Attempts 6 -InitialDelayMs 40
        if (-not $raw) { return $null }
        return $raw | ConvertFrom-Json
    } catch {
        return $null
    }
}

function Format-LiveSnapshot {
    param($Snapshot)

    if (-not $Snapshot) { return 'Waiting for scan progress...' }

    $lines = @(
        "Phase: $($Snapshot.Phase)"
        "Progress: $([string]::Format('{0:0.0}', [double]$Snapshot.Percent))%"
        "ETA: $($Snapshot.EtaText)"
        "Status: $($Snapshot.Message)"
    )
    if ($Snapshot.Detail) { $lines += "Detail: $($Snapshot.Detail)" }

    $incrementalResults = Get-IncrementalResults
    if ($incrementalResults) {
        if ($incrementalResults.SSDs -and $incrementalResults.SSDs.Count -gt 0) { $lines += "`n--- Found Diagnostics ---"; $lines += "SSDs: $($incrementalResults.SSDs.Count) devices" }
        if ($incrementalResults.WHEAEvents -and $incrementalResults.WHEAEvents.Count -gt 0) { $lines += "Hardware Errors: $($incrementalResults.WHEAEvents.Count) events" }
        if ($incrementalResults.TDREvents -and $incrementalResults.TDREvents.Count -gt 0) { $lines += "Graphics Timeouts: $($incrementalResults.TDREvents.Count) events" }
        if ($incrementalResults.StorageTimeouts -and $incrementalResults.StorageTimeouts.Count -gt 0) { $lines += "Storage Timeouts: $($incrementalResults.StorageTimeouts.Count) events" }
        if ($incrementalResults.RebootEvents -and $incrementalResults.RebootEvents.Count -gt 0) { $lines += "Reboot Events: $($incrementalResults.RebootEvents.Count) events" }
    }

    if ($Snapshot.UpdatedAt) {
        try {
            $updated = [datetime]::Parse($Snapshot.UpdatedAt)
            $age = (Get-Date) - $updated
            $lines += "`nLast updated: {0:N0}s ago" -f $age.TotalSeconds
        } catch { }
    }

    return $lines -join "`r`n"
}

function Set-LiveViewVisibility {
    if (-not $liveViewBorder) { return }
    $liveViewBorder.Visibility = if ($advancedLiveCheck -and $advancedLiveCheck.IsChecked) { 'Visible' } else { 'Collapsed' }
}

function Get-GuiPollingIntervalMs {
    $pollingMs = $null
    try {
        if ($script:Config.Performance -and $null -ne $script:Config.Performance.GUIPollingIntervalMs) {
            $pollingMs = [int]$script:Config.Performance.GUIPollingIntervalMs
        }
    } catch { }

    if ($null -eq $pollingMs -or $pollingMs -lt 100 -or $pollingMs -gt 5000) {
        return 250
    }

    return $pollingMs
}

function Set-RunUiState {
    param(
        [bool]$IsRunning,
        [string]$BusyStatus = 'Working...'
    )

    $script:IsCoreRunActive = $IsRunning

    foreach ($button in @($diagnosticsBtn, $autoFixBtn, $fullAutoBtn, $repairsBtn)) {
        if ($button) { $button.IsEnabled = -not $IsRunning }
    }

    if ($modeSelector) { $modeSelector.IsEnabled = -not $IsRunning }

    foreach ($check in @($chkWindowsRepair, $chkTdrTweak, $chkNetReset, $chkMemDiag, $chkDefenderScan)) {
        if ($check) { $check.IsEnabled = -not $IsRunning }
    }

    if ($cancelCoreBtn) { $cancelCoreBtn.Visibility = if ($IsRunning) { 'Visible' } else { 'Collapsed' } }
    if ($IsRunning -and $BusyStatus) { Set-Status $BusyStatus }
}

function Test-CanStartRun {
    if ($script:IsCoreRunActive) {
        Set-Status 'A run is already in progress. Cancel it or wait for completion.'
        return $false
    }

    return $true
}

function Start-LiveTracking {
    if ($script:LiveTimer) { $script:LiveTimer.Stop() }
    $script:LiveTimer = New-Object Windows.Threading.DispatcherTimer
    $script:LiveTimer.Interval = [TimeSpan]::FromMilliseconds((Get-GuiPollingIntervalMs))
    $script:LiveTimer.Add_Tick({
        try {
            $snapshot = Get-ProgressSnapshot
            if ($snapshot) {
                if ($progressBar) { $progressBar.IsIndeterminate = $false; $progressBar.Value = [double]$snapshot.Percent }
                Set-Status -Message ([string]$snapshot.Message) -Progress ([double]$snapshot.Percent)
                if ($phaseBlock) { $phaseBlock.Text = "Phase: $($snapshot.Phase)" }
                if ($etaBlock) { $etaBlock.Text = "ETA: $($snapshot.EtaText)" }
                if ($liveViewBox) { $liveViewBox.Text = Format-LiveSnapshot -Snapshot $snapshot; $liveViewBox.ScrollToEnd() }
                $incrementalResults = Get-IncrementalResults
                if ($incrementalResults) { Update-IncrementalResultsView -Results $incrementalResults }
            }
        } catch {
            if ($liveViewBox) { $liveViewBox.Text = "Live update warning: $_" }
        }
    })
    $script:LiveTimer.Start()
}

function Stop-LiveTracking {
    if ($script:LiveTimer) { $script:LiveTimer.Stop() }
    if ($progressBar) { $progressBar.IsIndeterminate = $false }
}

function Clear-LiveRunFiles {
    foreach ($path in @($ProgressSnapshotPath, $ProgressTextPath, (Join-Path $LogRoot 'results_incremental.json'))) {
        if ($path) { Remove-Item -Path $path -Force -ErrorAction SilentlyContinue }
    }
}

function Resolve-PowerShellHost {
    $candidates = @()
    if ($PSHOME) {
        $candidates += (Join-Path $PSHOME 'powershell.exe')
        $candidates += (Join-Path $PSHOME 'pwsh.exe')
        $candidates += (Join-Path $PSHOME 'pwsh')
    }
    $commandName = if ($PSVersionTable.PSEdition -eq 'Core') { 'pwsh' } else { 'powershell.exe' }
    $resolved = Get-Command $commandName -ErrorAction SilentlyContinue
    if ($resolved) { $candidates += $resolved.Source }
    $fallback = Get-Command powershell.exe -ErrorAction SilentlyContinue
    if ($fallback) { $candidates += $fallback.Source }

    foreach ($candidate in ($candidates | Where-Object { $_ } | Select-Object -Unique)) {
        if (Test-Path $candidate) { return $candidate }
    }

    throw 'Unable to find powershell.exe or pwsh to launch the core diagnostics script.'
}

function Wait-ForCoreProcess {
    param([System.Diagnostics.Process]$Process)

    $frame = New-Object Windows.Threading.DispatcherFrame
    $exitTimer = New-Object Windows.Threading.DispatcherTimer
    $exitTimer.Interval = [TimeSpan]::FromMilliseconds($script:Config.Performance.GUIPollingIntervalMs)
    $exitTimer.Add_Tick({
        if ($Process.HasExited) {
            $exitTimer.Stop()
            $frame.Continue = $false
        }
    }.GetNewClosure())
    $exitTimer.Start()
    [Windows.Threading.Dispatcher]::PushFrame($frame)
}

function Start-CoreRun {
    param([string[]]$Arguments)

    if ($script:IsCoreRunActive) {
        throw 'A diagnostics or repair run is already in progress.'
    }

    $scriptPath = Join-Path $PSScriptRoot 'Cipher-System-Check-v7-Core.ps1'
    if (-not (Test-Path $scriptPath)) { throw "Core script not found at $scriptPath" }

    Clear-LiveRunFiles
    $powershellExe = Resolve-PowerShellHost
    $argumentList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$scriptPath`"") + $Arguments

    try {
        Set-RunUiState -IsRunning $true -BusyStatus 'Starting diagnostics engine...'
        $script:CoreProcess = Start-Process -FilePath $powershellExe -ArgumentList $argumentList -WindowStyle Hidden -PassThru -ErrorAction Stop
        Start-LiveTracking
        Wait-ForCoreProcess -Process $script:CoreProcess
        return $script:CoreProcess.ExitCode
    } finally {
        Stop-LiveTracking
        $script:CoreProcess = $null
        Set-RunUiState -IsRunning $false
    }
}

function Update-SystemInfo {
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $cs = Get-CimInstance Win32_ComputerSystem
        $cpu = Get-CimInstance Win32_Processor
        $bios = Get-CimInstance Win32_BIOS
        $sysInfoBlock.Text = @"
BIOS: $($bios.SMBIOSBIOSVersion)
OS: Windows $($os.BuildNumber)
CPU: $($cpu.Name)
Cores: $($cpu.NumberOfCores)
RAM: $([math]::Round($cs.TotalPhysicalMemory / 1GB))GB
Uptime: $([math]::Round(((Get-Date) - $os.LastBootUpTime).TotalDays, 1))d
"@
    } catch {
        $sysInfoBlock.Text = 'Error loading system info'
    }
}

function Set-Status {
    param([string]$Message, [double]$Progress = -1)

    $statusText = if ($null -ne $Message) { [string]$Message } else { '' }
    if ($statusBlock) {
        $statusBlock.ToolTip = $statusText
        $statusBlock.Text = if ($statusText.Length -gt 220) { $statusText.Substring(0, 217) + '...' } else { $statusText }
    }
    if ($Progress -ge 0 -and $Progress -le 100) {
        if ($progressBar) { $progressBar.Value = $Progress }
        if ($progressPercent) { $progressPercent.Text = ("{0:0.0}%" -f $Progress) }
    }
}

function Cancel-Core {
    try {
        if ($script:CoreProcess -and -not $script:CoreProcess.HasExited) {
            $coreProcessId = $script:CoreProcess.Id
            Stop-Process -Id $coreProcessId -Force -ErrorAction SilentlyContinue
            Set-Status 'Cancellation requested. Waiting for core process to exit...'
        }
    } catch {
        Set-Status "Failed to cancel core: $_"
    }
}

function Toggle-Sidebar {
    try {
        $col = if ($leftCol) { $leftCol } elseif ($mainGrid) { $mainGrid.ColumnDefinitions[0] } else { $null }
        if ($null -eq $col) { return }
        if ($col.Width.Value -gt 60) {
            $col.Width = New-Object System.Windows.GridLength(48)
            if ($btnToggleSidebar) { $btnToggleSidebar.Content = '>' }
        } else {
            $col.Width = New-Object System.Windows.GridLength(286)
            if ($btnToggleSidebar) { $btnToggleSidebar.Content = '<' }
        }
    } catch { }
}

function Get-SelectedAutomationMode {
    if (-not $modeSelector) { return 'Balanced' }

    $selectedItem = $modeSelector.SelectedItem
    if ($selectedItem -is [string] -and -not [string]::IsNullOrWhiteSpace($selectedItem)) { return $selectedItem }
    if ($selectedItem -and $selectedItem.Content) { return [string]$selectedItem.Content }
    return 'Balanced'
}

function Select-ResultsTab {
    param([int]$Index)
    if ($resultsTabs) { $resultsTabs.SelectedIndex = $Index }
}

function Get-ScoreValue {
    param($Scores, [string[]]$Names)

    foreach ($name in $Names) {
        if ($Scores -is [System.Collections.IDictionary] -and $Scores.Contains($name) -and $null -ne $Scores[$name]) {
            return $Scores[$name]
        }
        if ($Scores -and $Scores.PSObject.Properties[$name] -and $null -ne $Scores.$name) {
            return $Scores.$name
        }
    }
    return 0
}

function Get-ResultItems {
    param($Items)

    if ($null -eq $Items) { return ,@() }

    $list = New-Object 'System.Collections.Generic.List[object]'
    $isEnumerable = $Items -is [System.Collections.IEnumerable]
    $isScalar = ($Items -is [string]) -or ($Items -is [System.Collections.IDictionary]) -or ($Items -is [pscustomobject])

    if ($isEnumerable -and -not $isScalar) {
        foreach ($item in $Items) {
            if ($null -ne $item) { [void]$list.Add($item) }
        }
    } else {
        [void]$list.Add($Items)
    }

    return ,$list.ToArray()
}

function New-ObjectCollection {
    param($Items)

    $collection = New-Object 'System.Collections.ObjectModel.ObservableCollection[object]'
    $resultItems = Get-ResultItems $Items
    foreach ($item in $resultItems) {
        [void]$collection.Add($item)
    }
    return ,$collection
}

function Set-ResultGridItems {
    param(
        $Grid,
        $StatusBlock,
        $Items,
        [string]$FilledLabel,
        [string]$EmptyLabel
    )

    $normalizedItems = Get-ResultItems $Items
    if ($Grid) {
        $boundItems = New-ObjectCollection $normalizedItems
        $Grid.ItemsSource = $boundItems
    }
    if ($StatusBlock) {
        $StatusBlock.Text = if ($normalizedItems.Count -gt 0) { "Detected $($normalizedItems.Count) $FilledLabel." } else { $EmptyLabel }
    }
    return ,$normalizedItems
}

function Update-IncrementalResultsView {
    param($Results)

    if (-not $Results) { return }
    if ($Results.PSObject.Properties['SSDs']) { Update-SsdHealthView -Items $Results.SSDs }
    if ($Results.PSObject.Properties['WHEAEvents']) {
        Set-ResultGridItems -Grid $wheaGrid -StatusBlock $wheaEmptyBlock -Items $Results.WHEAEvents -FilledLabel 'hardware error event(s)' -EmptyLabel 'No WHEA hardware error events found so far.' | Out-Null
    }
    if ($Results.PSObject.Properties['TDREvents']) {
        Set-ResultGridItems -Grid $tdrGrid -StatusBlock $tdrEmptyBlock -Items $Results.TDREvents -FilledLabel 'graphics timeout event(s)' -EmptyLabel 'No GPU/TDR timeout events found so far.' | Out-Null
    }
    if ($Results.PSObject.Properties['RebootEvents']) {
        Set-ResultGridItems -Grid $rebootGrid -StatusBlock $rebootEmptyBlock -Items $Results.RebootEvents -FilledLabel 'unexpected reboot event(s)' -EmptyLabel 'No unexpected reboot events found so far.' | Out-Null
    }
    if ($Results.PSObject.Properties['StorageTimeouts']) {
        Set-ResultGridItems -Grid $storageGrid -StatusBlock $storageEmptyBlock -Items $Results.StorageTimeouts -FilledLabel 'storage timeout event(s)' -EmptyLabel 'No storage timeout events found so far.' | Out-Null
    }
}

function Get-NumericMetric {
    param($Value)

    if ($null -eq $Value) { return $null }
    if ($Value -is [int] -or $Value -is [double] -or $Value -is [decimal]) { return [double]$Value }
    $text = [string]$Value
    $match = [regex]::Match($text, '-?\d+(\.\d+)?')
    if ($match.Success) { return [double]$match.Value }
    return $null
}

function Get-UiBrush {
    param([string]$Color)
    return ([System.Windows.Media.BrushConverter]::new()).ConvertFromString($Color)
}

function New-CardText {
    param(
        [string]$Text,
        [int]$Size = 12,
        [string]$Color = '#EAF0F7',
        [string]$Weight = 'Normal',
        [string]$Margin = '0,0,0,0'
    )

    $block = New-Object System.Windows.Controls.TextBlock
    $block.Text = $Text
    $block.FontSize = $Size
    $block.Foreground = Get-UiBrush $Color
    $block.FontWeight = $Weight
    $block.Margin = $Margin
    $block.TextWrapping = 'Wrap'
    return $block
}

function Add-MetricRow {
    param(
        [System.Windows.Controls.Panel]$Panel,
        [string]$Label,
        $RawValue,
        [double]$Maximum,
        [string]$Color
    )

    $numeric = Get-NumericMetric $RawValue
    $display = if ($null -ne $RawValue -and -not [string]::IsNullOrWhiteSpace([string]$RawValue)) { [string]$RawValue } else { 'N/A' }
    $value = if ($null -ne $numeric) { [math]::Max(0, [math]::Min($Maximum, $numeric)) } else { 0 }

    $header = New-Object System.Windows.Controls.Grid
    $header.Margin = '0,10,0,4'
    [void]$header.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition))
    $rightCol = New-Object System.Windows.Controls.ColumnDefinition
    $rightCol.Width = [System.Windows.GridLength]::Auto
    [void]$header.ColumnDefinitions.Add($rightCol)

    $labelBlock = New-CardText -Text $Label -Size 11 -Color '#A8B4C4' -Weight 'SemiBold'
    $valueBlock = New-CardText -Text $display -Size 11 -Color '#F4F8FC' -Weight 'SemiBold'
    [System.Windows.Controls.Grid]::SetColumn($valueBlock, 1)
    [void]$header.Children.Add($labelBlock)
    [void]$header.Children.Add($valueBlock)
    [void]$Panel.Children.Add($header)

    $bar = New-Object System.Windows.Controls.ProgressBar
    $bar.Minimum = 0
    $bar.Maximum = $Maximum
    $bar.Value = $value
    $bar.Height = 8
    $bar.Background = Get-UiBrush '#223044'
    $bar.Foreground = Get-UiBrush $Color
    [void]$Panel.Children.Add($bar)
}

function Update-SsdHealthView {
    param($Items)

    $ssdItems = Get-ResultItems $Items
    if ($ssdHealthGrid) {
        $ssdBoundItems = New-ObjectCollection $ssdItems
        $ssdHealthGrid.ItemsSource = $ssdBoundItems
    }
    if (-not $ssdHealthCards) { return }

    $ssdHealthCards.Children.Clear()
    if ($ssdEmptyBlock) {
        $ssdEmptyBlock.Text = if ($ssdItems.Count -gt 0) { "Detected $($ssdItems.Count) drive(s). Review the cards for at-a-glance temperature, wear, and media error status." } else { 'No SSD data found yet. Run diagnostics as Administrator so the core can query storage reliability counters.' }
    }

    if ($ssdItems.Count -eq 0) { return }

    foreach ($disk in $ssdItems) {
        $name = if ($disk.FriendlyName) { [string]$disk.FriendlyName } else { 'Unknown drive' }
        $health = if ($disk.HealthStatus) { [string]$disk.HealthStatus } else { 'Unknown' }
        $media = if ($disk.MediaType) { [string]$disk.MediaType } else { 'Storage device' }
        $temp = if ($disk.Temperature) { $disk.Temperature } else { 'N/A' }
        $wear = if ($disk.Wear) { $disk.Wear } else { 'N/A' }
        $readErrors = if ($null -ne $disk.ReadErrors) { [int64]$disk.ReadErrors } else { 0 }
        $writeErrors = if ($null -ne $disk.WriteErrors) { [int64]$disk.WriteErrors } else { 0 }
        $errorTotal = $readErrors + $writeErrors
        $tempValue = Get-NumericMetric $temp
        $wearValue = Get-NumericMetric $wear

        $statusColor = '#22C55E'
        if ($health -notmatch 'Healthy|OK|Unknown') { $statusColor = '#EF4444' }
        elseif (($null -ne $tempValue -and $tempValue -ge 55) -or ($null -ne $wearValue -and $wearValue -ge 80) -or $errorTotal -gt 0) { $statusColor = '#F59E0B' }

        $card = New-Object System.Windows.Controls.Border
        $card.Width = 300
        $card.MinHeight = 210
        $card.Margin = '0,0,12,12'
        $card.Padding = '16'
        $card.CornerRadius = '16'
        $card.Background = Get-UiBrush '#121B29'
        $card.BorderBrush = Get-UiBrush '#263549'
        $card.BorderThickness = '1'

        $stack = New-Object System.Windows.Controls.StackPanel
        [void]$stack.Children.Add((New-CardText -Text $name -Size 15 -Color '#F4F8FC' -Weight 'Bold' -Margin '0,0,0,4'))
        [void]$stack.Children.Add((New-CardText -Text $media -Size 11 -Color '#A8B4C4' -Margin '0,0,0,10'))

        $pill = New-Object System.Windows.Controls.Border
        $pill.Background = Get-UiBrush $statusColor
        $pill.CornerRadius = '10'
        $pill.Padding = '10,5'
        $pill.HorizontalAlignment = 'Left'
        $pill.Child = New-CardText -Text $health -Size 11 -Color '#06121C' -Weight 'Bold'
        [void]$stack.Children.Add($pill)

        Add-MetricRow -Panel $stack -Label 'Temperature' -RawValue $temp -Maximum 80 -Color '#38BDF8'
        Add-MetricRow -Panel $stack -Label 'Wear Used' -RawValue $wear -Maximum 100 -Color '#22C55E'
        Add-MetricRow -Panel $stack -Label 'Media Errors' -RawValue $errorTotal -Maximum 10 -Color $(if ($errorTotal -gt 0) { '#EF4444' } else { '#22C55E' })

        if ($disk.PowerOnHours) {
            [void]$stack.Children.Add((New-CardText -Text "Power on: $($disk.PowerOnHours)" -Size 11 -Color '#A8B4C4' -Margin '0,10,0,0'))
        }

        $card.Child = $stack
        [void]$ssdHealthCards.Children.Add($card)
    }
}

function Update-ResultSummary {
    param($Results)
    if (-not $Results) { return }

    $ssdItems = Get-ResultItems $Results.SSDs
    $wheaItems = Get-ResultItems $Results.WHEAEvents
    $tdrItems = Get-ResultItems $Results.TDREvents
    $rebootItems = Get-ResultItems $Results.RebootEvents
    $storageItems = Get-ResultItems $Results.StorageTimeouts

    $scoreStorage = Get-ScoreValue -Scores $Results.AllScores -Names @('Storage')
    $scoreHardware = Get-ScoreValue -Scores $Results.AllScores -Names @('Hardware', 'WHEA')
    $scoreGpu = Get-ScoreValue -Scores $Results.AllScores -Names @('GPU')
    $scoreMemory = Get-ScoreValue -Scores $Results.AllScores -Names @('Memory')
    $totalFindings = @($ssdItems.Count, $wheaItems.Count, $tdrItems.Count, $rebootItems.Count, $storageItems.Count) | Measure-Object -Sum | Select-Object -ExpandProperty Sum
    $healthText = if ($Results.TopIssueScore -ge 40) { 'CRITICAL' } elseif ($Results.TopIssueScore -ge 20) { 'WARNING' } elseif ($Results.TopIssueScore -ge 1) { 'MINOR' } else { 'HEALTHY' }

    if ($topIssueCardText) { $topIssueCardText.Text = if ($Results.TopIssue) { $Results.TopIssue } else { 'No issues detected' } }
    if ($findingsCardText) { $findingsCardText.Text = "{0} findings" -f $totalFindings }
    if ($healthCardText) { $healthCardText.Text = $healthText }
    if ($lastRunCardText) { $lastRunCardText.Text = if ($Results.Timestamp) { "{0:MMM d, yyyy h:mm tt}" -f [datetime]$Results.Timestamp } else { 'Not run yet' } }
    if ($quickSummaryBlock) { $quickSummaryBlock.Text = "Status: $healthText`nFindings: $totalFindings`nTop issue: $($topIssueCardText.Text)" }

    if ($resultsOverviewBlock) {
        $resultsOverviewBlock.Text = @"
DIAGNOSTIC SUMMARY
=================
Status: $healthText ($($Results.TopIssueScore) severity points)
Top Issue: $($Results.TopIssue)

SCORES BY CATEGORY:
Storage: $scoreStorage points
Hardware: $scoreHardware points
Graphics: $scoreGpu points
Memory: $scoreMemory points

FINDINGS:
Storage Devices: $($ssdItems.Count) detected
Hardware Errors: $($wheaItems.Count) events
GPU Timeouts: $($tdrItems.Count) events
Reboot Events: $($rebootItems.Count) events
Storage Timeouts: $($storageItems.Count) events

Diagnostics run: $($Results.Timestamp)

Open the SSD Health tab for per-drive cards and detailed reliability counters.
"@
    }

    Update-SsdHealthView -Items $ssdItems
    Set-ResultGridItems -Grid $wheaGrid -StatusBlock $wheaEmptyBlock -Items $wheaItems -FilledLabel 'hardware error event(s)' -EmptyLabel 'No WHEA hardware error events were found in the checked event window.' | Out-Null
    Set-ResultGridItems -Grid $tdrGrid -StatusBlock $tdrEmptyBlock -Items $tdrItems -FilledLabel 'graphics timeout event(s)' -EmptyLabel 'No GPU/TDR timeout events were found in the checked event window.' | Out-Null
    Set-ResultGridItems -Grid $rebootGrid -StatusBlock $rebootEmptyBlock -Items $rebootItems -FilledLabel 'unexpected reboot event(s)' -EmptyLabel 'No unexpected shutdown or reboot events were found in the checked event window.' | Out-Null
    Set-ResultGridItems -Grid $storageGrid -StatusBlock $storageEmptyBlock -Items $storageItems -FilledLabel 'storage timeout event(s)' -EmptyLabel 'No disk/controller timeout events were found in the checked event window.' | Out-Null
}

function Show-Results {
    $xmlPath = Join-Path $LogRoot 'diagnostic_results.xml'
    if (-not (Test-Path $xmlPath)) {
        Set-Status "No results found yet. Run diagnostics first."
        return
    }

    try {
        $results = Import-Clixml $xmlPath
        Update-ResultSummary -Results $results
        $analysisPath = Join-Path $LogRoot 'analysis_ranked.txt'
        $raw = Read-FileWithRetry -Path $analysisPath -Attempts 3 -InitialDelayMs 50
        if ($rawOutputBox -and $raw) { $rawOutputBox.Text = $raw }
        Set-Status 'Results loaded.' 100
    } catch {
        Set-Status "ERROR: Failed to load results: $_"
    }
}

function Copy-SummaryToClipboard {
    if ($quickSummaryBlock -and $quickSummaryBlock.Text -and $quickSummaryBlock.Text -notmatch 'Start a scan') {
        [System.Windows.Clipboard]::SetText($quickSummaryBlock.Text)
        Set-Status 'Summary copied to clipboard.'
    } else {
        Set-Status 'Start a scan first to generate a summary.'
    }
}

function Invoke-Diagnostics {
    if (-not (Test-CanStartRun)) { return }

    Set-Status 'Starting diagnostics...' 0
    if ($progressBar) { $progressBar.IsIndeterminate = $true }

    try {
        $arguments = @('-QuietMode')
        if ($TestMode) { $arguments += '-TestMode' }
        $exitCode = Start-CoreRun -Arguments $arguments
        if ($exitCode -ne 0) { throw "Core diagnostics exited with code $exitCode" }
        Show-Results
        return $true
    } catch {
        Stop-LiveTracking
        Set-Status "ERROR: Diagnostics failed: $_"
        return $false
    }
}

function Invoke-SelectedRepairs {
    if (-not (Test-CanStartRun)) { return }

    $repairs = @()
    if ($chkWindowsRepair -and $chkWindowsRepair.IsChecked) { $repairs += '-RunRepair' }
    if ($chkTdrTweak -and $chkTdrTweak.IsChecked) { $repairs += '-RunTdrTweak' }
    if ($chkNetReset -and $chkNetReset.IsChecked) { $repairs += '-RunNetworkReset' }
    if ($chkMemDiag -and $chkMemDiag.IsChecked) { $repairs += '-RunMemDiag' }
    if ($chkDefenderScan -and $chkDefenderScan.IsChecked) { $repairs += '-RunDefenderScan' }

    if ($repairs.Count -eq 0) {
        [Windows.MessageBox]::Show('No repair options selected.', 'Info', [Windows.MessageBoxButton]::OK, [Windows.MessageBoxImage]::Information) | Out-Null
        return
    }

    $confirm = [Windows.MessageBox]::Show("Confirm selected repairs?`n`nSelected: $($repairs -join ', ')`n`nThis requires Administrator and may restart your system.", 'Confirm Repairs', [Windows.MessageBoxButton]::YesNo, [Windows.MessageBoxImage]::Question)
    if ($confirm -eq [Windows.MessageBoxResult]::Yes) {
        try {
            Set-Status 'Applying repairs...' 0
            $exitCode = Start-CoreRun -Arguments $repairs
            if ($exitCode -ne 0) { throw "Core repairs exited with code $exitCode" }
            Set-Status 'Repairs applied. Review logs for details.' 100
        } catch {
            Set-Status "ERROR: Repair failed: $_"
        }
    }
}

function Get-RecommendedRepairs {
    param(
        $Results,
        [string]$Mode = 'Balanced'
    )

    $repairs = @()
    switch ($Mode) {
        'Safe' {
            if ($Results.WHEAEvents.Count -gt 0 -or $Results.StorageTimeouts.Count -gt 0 -or $Results.RebootEvents.Count -gt 0) { $repairs += '-RunRepair' }
        }
        'Balanced' {
            if ($Results.WHEAEvents.Count -gt 0 -or $Results.StorageTimeouts.Count -gt 0 -or $Results.RebootEvents.Count -gt 0) { $repairs += '-RunRepair' }
            if ($Results.TDREvents.Count -gt 0) { $repairs += '-RunTdrTweak' }
        }
        'Deep' {
            if ($Results.WHEAEvents.Count -gt 0 -or $Results.StorageTimeouts.Count -gt 0 -or $Results.RebootEvents.Count -gt 0) { $repairs += '-RunRepair' }
            if ($Results.TDREvents.Count -gt 0) { $repairs += '-RunTdrTweak' }
            if ($Results.WHEAEvents.Count -gt 0) { $repairs += '-RunMemDiag' }
        }
    }

    return $repairs | Select-Object -Unique
}

function Invoke-AutoScanAndFix {
    if (-not (Test-CanStartRun)) { return }

    $scanSucceeded = Invoke-Diagnostics
    if (-not $scanSucceeded) { return }

    $xmlPath = Join-Path $LogRoot 'diagnostic_results.xml'
    if (-not (Test-Path $xmlPath)) {
        Set-Status 'Auto-fix stopped: no results file was created.'
        return
    }

    $results = Import-Clixml $xmlPath
    $mode = Get-SelectedAutomationMode
    $repairs = Get-RecommendedRepairs -Results $results -Mode $mode
    if (-not $repairs -or $repairs.Count -eq 0) {
        Set-Status "Diagnostics finished in $mode mode. No safe automatic fixes were recommended."
        return
    }

    $confirm = [Windows.MessageBox]::Show("Mode: $mode`n`nRecommended fixes:`n`n$($repairs -join ', ')`n`nApply these now?", "$mode Automation", [Windows.MessageBoxButton]::YesNo, [Windows.MessageBoxImage]::Question)
    if ($confirm -ne [Windows.MessageBoxResult]::Yes) {
        Set-Status 'Auto-fix cancelled.'
        return
    }

    try {
        Set-Status "Applying $mode automation fixes..." 0
        $exitCode = Start-CoreRun -Arguments $repairs
        if ($exitCode -ne 0) { throw "Core repairs exited with code $exitCode" }
        Set-Status "$mode automation applied. Review logs for details." 100
    } catch {
        Set-Status "ERROR: Auto-fix failed: $_"
    }
}

function Invoke-FullAutomation {
    if (-not (Test-CanStartRun)) { return }

    $mode = Get-SelectedAutomationMode
    Set-Status "Running $mode automation..." 0

    try {
        $exitCode = Start-CoreRun -Arguments @('-QuietMode', '-RunWindowsUpdate', '-RunDefenderScan')
        if ($exitCode -ne 0) { throw "$mode automation scan failed with code $exitCode" }
        Show-Results

        $xmlPath = Join-Path $LogRoot 'diagnostic_results.xml'
        $results = Import-Clixml $xmlPath
        $repairs = Get-RecommendedRepairs -Results $results -Mode $mode
        if ($repairs -and $repairs.Count -gt 0) {
            $automationArgs = @('-QuietMode', '-RunWindowsUpdate', '-RunDefenderScan') + $repairs
            $automationExitCode = Start-CoreRun -Arguments $automationArgs
            if ($automationExitCode -ne 0) { throw "Core automation exited with code $automationExitCode" }
            Set-Status "$mode automation complete. Review logs for details." 100
        } else {
            Set-Status "Diagnostics and update checks complete in $mode mode. No safe fixes were recommended."
        }
    } catch {
        Set-Status "ERROR: $mode automation failed: $_"
    }
}

function Open-LogFolder {
    if (Test-Path $LogRoot) {
        try {
            explorer.exe $LogRoot
        } catch {
            [Windows.MessageBox]::Show("Failed to open log folder: $_", 'Error', [Windows.MessageBoxButton]::OK, [Windows.MessageBoxImage]::Error) | Out-Null
        }
    } else {
        [Windows.MessageBox]::Show("Log folder not found: $LogRoot`n`nRun diagnostics first to create logs.", 'Error', [Windows.MessageBoxButton]::OK, [Windows.MessageBoxImage]::Error) | Out-Null
    }
}

if ($modeSelector) {
    $modeSelector.ItemsSource = @('Safe', 'Balanced', 'Deep')
    $modeSelector.SelectedIndex = 1
}
if ($repairsBtn) { $repairsBtn.IsEnabled = $true }

# Event handlers.
$diagnosticsBtn.Add_Click({ Invoke-Diagnostics })
$autoFixBtn.Add_Click({ Invoke-AutoScanAndFix })
$fullAutoBtn.Add_Click({ Invoke-FullAutomation })
$repairsBtn.Add_Click({ Invoke-SelectedRepairs })
$openLogsBtn.Add_Click({ Open-LogFolder })
$copySummaryBtn.Add_Click({ Copy-SummaryToClipboard })
$navOverviewBtn.Add_Click({ Select-ResultsTab 0 })
$navSSDBtn.Add_Click({ Select-ResultsTab 1 })
$navWHEABtn.Add_Click({ Select-ResultsTab 2 })
$navTdrBtn.Add_Click({ Select-ResultsTab 3 })
$navRebootBtn.Add_Click({ Select-ResultsTab 4 })
$navStorageBtn.Add_Click({ Select-ResultsTab 5 })
$navRawBtn.Add_Click({ Select-ResultsTab 6 })

if ($btnToggleSidebar) { $btnToggleSidebar.Add_Click({ Toggle-Sidebar }) }
if ($cancelCoreBtn) { $cancelCoreBtn.Add_Click({ Cancel-Core }) }
if ($advancedLiveCheck) { $advancedLiveCheck.Add_Click({ Set-LiveViewVisibility }) }
if ($helpBtn) {
    $helpBtn.Add_Click({
        $gloss = @(
            'Glossary - quick terms and what they mean:',
            '- Hardware Errors: kernel-level hardware reports (sometimes called WHEA). These indicate firmware/hardware faults.',
            '- Graphics Timeouts: GPU driver timeouts and hangs (often TDR events).',
            '- SSD Health: SMART and wear details for storage devices.',
            '- Storage Timeouts: controller or disk IO timeouts that can cause slowdowns or errors.',
            '- Detailed Log: the full diagnostic text log generated by the tool (useful for experts).',
            '',
            'For safe distribution: consider code-signing scripts and packaging signed installers to reduce security warnings.'
        )
        [Windows.MessageBox]::Show(($gloss -join "`r`n"), 'Glossary & Quick Help', [Windows.MessageBoxButton]::OK, [Windows.MessageBoxImage]::Information) | Out-Null
    })
}

$window.Add_Loaded({
    try {
        Update-SystemInfo
        Set-RunUiState -IsRunning $false
        Set-Status 'Ready to start scan' 0
        Set-LiveViewVisibility
        if ($phaseBlock) { $phaseBlock.Text = 'Phase: idle' }
        if ($etaBlock) { $etaBlock.Text = 'ETA: Not started' }
        Update-SsdHealthView -Items @()
        Set-ResultGridItems -Grid $wheaGrid -StatusBlock $wheaEmptyBlock -Items @() -FilledLabel 'hardware error event(s)' -EmptyLabel 'Run diagnostics to populate WHEA hardware error events.' | Out-Null
        Set-ResultGridItems -Grid $tdrGrid -StatusBlock $tdrEmptyBlock -Items @() -FilledLabel 'graphics timeout event(s)' -EmptyLabel 'Run diagnostics to populate GPU/TDR timeout events.' | Out-Null
        Set-ResultGridItems -Grid $rebootGrid -StatusBlock $rebootEmptyBlock -Items @() -FilledLabel 'unexpected reboot event(s)' -EmptyLabel 'Run diagnostics to populate unexpected shutdown and reboot events.' | Out-Null
        Set-ResultGridItems -Grid $storageGrid -StatusBlock $storageEmptyBlock -Items @() -FilledLabel 'storage timeout event(s)' -EmptyLabel 'Run diagnostics to populate disk/controller timeout events.' | Out-Null
        Select-ResultsTab 0
    } catch {
        Set-Status "ERROR during initialization: $_"
    }
})

$window.ShowDialog() | Out-Null
