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
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Title="Cipher System Check v7" Width="1200" Height="800" WindowStartupLocation="CenterScreen" Background="#0B0D10" FontFamily="Segoe UI" FontSize="11" Foreground="#EAECEF"> <Window.Resources> <LinearGradientBrush x:Key="AppBackgroundBrush" StartPoint="0,0" EndPoint="1,1"> <GradientStop Color="#0B0D10" Offset="0"/> <GradientStop Color="#10131A" Offset="0.45"/> <GradientStop Color="#0B0D10" Offset="1"/> </LinearGradientBrush> <SolidColorBrush x:Key="SurfaceBrush" Color="#141923"/> <SolidColorBrush x:Key="SurfaceAltBrush" Color="#171D27"/> <SolidColorBrush x:Key="SurfaceBorderBrush" Color="#283040"/> <SolidColorBrush x:Key="TextPrimaryBrush" Color="#F2F5F8"/> <SolidColorBrush x:Key="TextSecondaryBrush" Color="#9AA4B2"/> <SolidColorBrush x:Key="AccentBrush" Color="#4DA3FF"/> <SolidColorBrush x:Key="AccentSoftBrush" Color="#183A5A"/> <Style TargetType="ScrollBar"> <Setter Property="Background" Value="#0F131A"/> <Setter Property="Foreground" Value="{StaticResource AccentBrush}"/> <Setter Property="Width" Value="12"/> <Setter Property="MinWidth" Value="12"/> <Setter Property="Height" Value="12"/> <Setter Property="Template"> <Setter.Value> <ControlTemplate TargetType="ScrollBar"> <Grid x:Name="Root" Background="Transparent" Width="{TemplateBinding Width}" Height="{TemplateBinding Height}"> <Border Background="#0F131A" CornerRadius="6" BorderBrush="#1F2530" BorderThickness="1"/> <Track x:Name="PART_Track" IsDirectionReversed="True" Orientation="{TemplateBinding Orientation}"> <Track.DecreaseRepeatButton> <RepeatButton Command="ScrollBar.LineUpCommand" Opacity="0" IsTabStop="False" Focusable="False"/> </Track.DecreaseRepeatButton> <Track.Thumb> <Thumb Background="{TemplateBinding Foreground}" Margin="2"/> </Track.Thumb> <Track.IncreaseRepeatButton> <RepeatButton Command="ScrollBar.LineDownCommand" Opacity="0" IsTabStop="False" Focusable="False"/> </Track.IncreaseRepeatButton> </Track> </Grid> </ControlTemplate> </Setter.Value> </Setter> </Style> <Style x:Key="PrimaryButtonStyle" TargetType="Button"> <Setter Property="Foreground" Value="{StaticResource TextPrimaryBrush}"/> <Setter Property="Background" Value="{StaticResource AccentBrush}"/> <Setter Property="BorderBrush" Value="#184A87"/> <Setter Property="BorderThickness" Value="0"/> <Setter Property="Padding" Value="14,9"/> <Setter Property="Height" Value="40"/> <Setter Property="Cursor" Value="Hand"/> <Setter Property="FontWeight" Value="SemiBold"/> <Setter Property="Template"> <Setter.Value> <ControlTemplate TargetType="Button"> <Border x:Name="Bd" Background="{TemplateBinding Background}" CornerRadius="12" Padding="{TemplateBinding Padding}"> <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/> </Border> <ControlTemplate.Triggers> <Trigger Property="IsMouseOver" Value="True"> <Setter TargetName="Bd" Property="Opacity" Value="0.95"/> </Trigger> <Trigger Property="IsPressed" Value="True"> <Setter TargetName="Bd" Property="Opacity" Value="0.84"/> </Trigger> <Trigger Property="IsEnabled" Value="False"> <Setter TargetName="Bd" Property="Opacity" Value="0.55"/> </Trigger> </ControlTemplate.Triggers> </ControlTemplate> </Setter.Value> </Setter> </Style> <Style x:Key="AccentButtonStyle" TargetType="Button" BasedOn="{StaticResource PrimaryButtonStyle}"> <Setter Property="Background" Value="#2D8A57"/> <Setter Property="BorderBrush" Value="#1C5D37"/> </Style> <Style x:Key="NavButtonStyle" TargetType="Button" BasedOn="{StaticResource PrimaryButtonStyle}"> <Setter Property="Background" Value="{StaticResource SurfaceBrush}"/> <Setter Property="BorderBrush" Value="{StaticResource SurfaceBorderBrush}"/> <Setter Property="Foreground" Value="{StaticResource TextPrimaryBrush}"/> <Setter Property="Height" Value="34"/> <Setter Property="HorizontalContentAlignment" Value="Left"/> <Setter Property="Padding" Value="12,6"/> <Setter Property="Margin" Value="0,0,0,6"/> <Setter Property="FontWeight" Value="Normal"/> </Style> <Style x:Key="StatCardStyle" TargetType="Border"> <Setter Property="Background" Value="{StaticResource SurfaceBrush}"/> <Setter Property="BorderBrush" Value="{StaticResource SurfaceBorderBrush}"/> <Setter Property="BorderThickness" Value="1"/> <Setter Property="CornerRadius" Value="14"/> <Setter Property="Padding" Value="12"/> <Setter Property="Margin" Value="0,0,10,10"/> </Style> <Style TargetType="TabItem"> <Setter Property="Foreground" Value="{StaticResource TextSecondaryBrush}"/> <Setter Property="Background" Value="{StaticResource SurfaceBrush}"/> <Setter Property="Padding" Value="12,7"/> <Setter Property="Margin" Value="0,0,6,0"/> <Setter Property="Template"> <Setter.Value> <ControlTemplate TargetType="TabItem"> <Border x:Name="Bd" Background="{TemplateBinding Background}" CornerRadius="10,10,0,0" BorderBrush="{StaticResource SurfaceBorderBrush}" BorderThickness="1,1,1,0" Padding="{TemplateBinding Padding}"> <ContentPresenter ContentSource="Header" HorizontalAlignment="Center" VerticalAlignment="Center"/> </Border> <ControlTemplate.Triggers> <Trigger Property="IsSelected" Value="True"> <Setter TargetName="Bd" Property="Background" Value="#1B2230"/> <Setter Property="Foreground" Value="{StaticResource TextPrimaryBrush}"/> </Trigger> <Trigger Property="IsMouseOver" Value="True"> <Setter TargetName="Bd" Property="Background" Value="#1D2533"/> </Trigger> </ControlTemplate.Triggers> </ControlTemplate> </Setter.Value> </Setter> </Style> <Style TargetType="DataGrid"> <Setter Property="Background" Value="#10141A"/> <Setter Property="Foreground" Value="#EAECEF"/> <Setter Property="RowBackground" Value="#141A23"/> <Setter Property="AlternatingRowBackground" Value="#11161D"/> <Setter Property="BorderBrush" Value="{StaticResource SurfaceBorderBrush}"/> <Setter Property="GridLinesVisibility" Value="Horizontal"/> <Setter Property="HeadersVisibility" Value="Column"/> </Style> <Style TargetType="ComboBox"> <Setter Property="Background" Value="{StaticResource SurfaceBrush}"/> <Setter Property="Foreground" Value="#EAECEF"/> <Setter Property="BorderBrush" Value="{StaticResource SurfaceBorderBrush}"/> <Setter Property="Padding" Value="8,4"/> <Setter Property="Height" Value="30"/> <Setter Property="Template"> <Setter.Value> <ControlTemplate TargetType="ComboBox"> <Grid SnapsToDevicePixels="True"> <Border x:Name="OuterBorder" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="1" CornerRadius="10"> <Grid> <ToggleButton x:Name="ToggleButton" Focusable="False" IsChecked="{Binding IsDropDownOpen, RelativeSource={RelativeSource TemplatedParent}, Mode=TwoWay}" ClickMode="Press" Background="Transparent" BorderThickness="0"> <Grid> <Grid.ColumnDefinitions> <ColumnDefinition Width="*"/> <ColumnDefinition Width="28"/> </Grid.ColumnDefinitions> <ContentPresenter Grid.Column="0" Margin="8,0,0,0" VerticalAlignment="Center" HorizontalAlignment="Left" Content="{TemplateBinding SelectionBoxItem}" ContentTemplate="{TemplateBinding SelectionBoxItemTemplate}" ContentTemplateSelector="{TemplateBinding ItemTemplateSelector}" RecognizesAccessKey="True" TextElement.Foreground="{TemplateBinding Foreground}"/> <TextBlock Grid.Column="1" Text="v" FontSize="10" Foreground="{StaticResource TextSecondaryBrush}" HorizontalAlignment="Center" VerticalAlignment="Center"/> </Grid> </ToggleButton> <Popup x:Name="Popup" Placement="Bottom" AllowsTransparency="True" Focusable="False" IsOpen="{TemplateBinding IsDropDownOpen}" PopupAnimation="Fade" PlacementTarget="{Binding RelativeSource={RelativeSource TemplatedParent}}"> <Border Background="#131823" BorderBrush="{StaticResource SurfaceBorderBrush}" BorderThickness="1" CornerRadius="10" MinWidth="{Binding ActualWidth, RelativeSource={RelativeSource TemplatedParent}}"> <ScrollViewer Margin="0" SnapsToDevicePixels="True"> <StackPanel IsItemsHost="True" KeyboardNavigation.DirectionalNavigation="Contained"/> </ScrollViewer> </Border> </Popup> </Grid> </Border> </Grid> </ControlTemplate> </Setter.Value> </Setter> </Style> <Style TargetType="ComboBoxItem"> <Setter Property="Background" Value="{StaticResource SurfaceBrush}"/> <Setter Property="Foreground" Value="#EAECEF"/> <Setter Property="Padding" Value="8,6"/> <Setter Property="HorizontalContentAlignment" Value="Left"/> <Style.Triggers> <Trigger Property="IsMouseOver" Value="True"> <Setter Property="Background" Value="#202632"/> </Trigger> <Trigger Property="IsSelected" Value="True"> <Setter Property="Background" Value="#243348"/> <Setter Property="Foreground" Value="#FFFFFF"/> </Trigger> </Style.Triggers> </Style> </Window.Resources> <Grid x:Name="MainGrid"> <Grid.Background> <StaticResource ResourceKey="AppBackgroundBrush"/> </Grid.Background> <Grid.RowDefinitions> <RowDefinition Height="auto"/> <RowDefinition Height="*"/> <RowDefinition Height="auto"/> </Grid.RowDefinitions> <!-- HEADER --> <StackPanel Grid.Row="0" Margin="18,18,18,0"> <Border Background="{StaticResource SurfaceBrush}" CornerRadius="18" Padding="18" BorderBrush="{StaticResource SurfaceBorderBrush}" BorderThickness="1"> <Grid> <Grid.ColumnDefinitions> <ColumnDefinition Width="6"/> <ColumnDefinition Width="*"/> <ColumnDefinition Width="48"/> </Grid.ColumnDefinitions> <Border Grid.Column="0" Background="{StaticResource AccentBrush}" CornerRadius="3" Margin="0,2,14,2"/> <StackPanel Grid.Column="1"> <TextBlock Text="Cipher System Check v7" FontSize="22" FontWeight="Bold" Foreground="{StaticResource TextPrimaryBrush}"/> <TextBlock Text="Dark diagnostics with clear steps, live progress, and safe fixes" Foreground="{StaticResource TextSecondaryBrush}" FontSize="11" Margin="0,5,0,0"/> </StackPanel> <StackPanel Grid.Column="2" HorizontalAlignment="Right" Orientation="Horizontal" VerticalAlignment="Top" Margin="8,0,0,0"> <ToggleButton x:Name="BtnToggleSidebar" Width="36" Height="28" Margin="6,0,0,0" ToolTip="Toggle sidebar"> <TextBlock Text="◀" FontSize="12" HorizontalAlignment="Center" VerticalAlignment="Center"/> </ToggleButton> <Button x:Name="HelpBtn" Width="28" Height="28" Margin="6,0,0,0" ToolTip="Glossary and quick help">?</Button> </StackPanel> </Grid> </Border> </StackPanel> <!-- MAIN CONTENT --> <Grid Grid.Row="1" Margin="10"> <Grid.ColumnDefinitions> <ColumnDefinition Width="286" x:Name="LeftCol"/> <ColumnDefinition Width="*"/> </Grid.ColumnDefinitions> <!-- LEFT PANEL: CONTROLS --> <ScrollViewer Grid.Column="0" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto" Margin="0,0,10,0" CanContentScroll="False"> <StackPanel VerticalAlignment="Top"> <TextBlock Text="System Overview" FontWeight="SemiBold" FontSize="12" Margin="0,0,0,8" Foreground="{StaticResource TextPrimaryBrush}"/> <Border Style="{StaticResource StatCardStyle}" Margin="0,0,0,8"> <StackPanel> <TextBlock Text="Current system state" Foreground="{StaticResource TextSecondaryBrush}" FontSize="9" Margin="0,0,0,6"/> <TextBlock x:Name="SysInfoBlock" Text="Loading..." FontSize="10" LineHeight="18" Foreground="#D7DCE4"/> </StackPanel> </Border> <TextBlock Text="Quick Summary" FontWeight="SemiBold" FontSize="12" Margin="0,0,0,8" Foreground="{StaticResource TextPrimaryBrush}"/> <Border Style="{StaticResource StatCardStyle}" Margin="0,0,0,8"> <StackPanel> <TextBlock Text="Latest scan" Foreground="{StaticResource TextSecondaryBrush}" FontSize="9"/> <TextBlock x:Name="QuickSummaryBlock" Text="Click 'Start Scan' to run a safe system check and populate results." TextWrapping="Wrap" Foreground="{StaticResource TextPrimaryBrush}" Margin="0,6,0,0"/> </StackPanel> </Border> <TextBlock Text="Scan Options" FontWeight="SemiBold" FontSize="12" Margin="0,12,0,8" Foreground="{StaticResource TextPrimaryBrush}"/> <TextBlock Text="Automation Mode" Foreground="{StaticResource TextSecondaryBrush}" FontSize="9" Margin="0,0,0,4"/> <ComboBox x:Name="ModeSelector" SelectedIndex="1" Margin="0,0,0,8" Height="30" Background="{StaticResource SurfaceBrush}" Foreground="#EAECEF" BorderBrush="{StaticResource SurfaceBorderBrush}"> </ComboBox> <CheckBox x:Name="AdvancedLiveCheck" Content="Detailed live log (advanced)" Margin="0,0,0,8" Foreground="{StaticResource TextPrimaryBrush}" IsChecked="True"/> <Border x:Name="LiveViewBorder" Style="{StaticResource StatCardStyle}" Margin="0,0,0,8"> <StackPanel> <TextBlock Text="Live Activity" Foreground="{StaticResource TextSecondaryBrush}" FontSize="9"/> <TextBox x:Name="LiveViewBox" Text="Waiting for the first scan..." TextWrapping="Wrap" AcceptsReturn="True" IsReadOnly="True" Background="#0F131A" Foreground="#EAECEF" BorderThickness="0" FontFamily="Consolas" FontSize="9" Height="120" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto" Margin="0,6,0,0"/> </StackPanel> </Border> <Button x:Name="DiagnosticsBtn" Content="Start Scan" Style="{StaticResource PrimaryButtonStyle}" Margin="0,0,0,6" ToolTip="Performs a safe system check and collects logs"/> <Button x:Name="AutoFixBtn" Content="Auto Scan + Recommended Fixes" Style="{StaticResource AccentButtonStyle}" Margin="0,0,0,6" Height="36" Foreground="White" ToolTip="Apply recommended, low-risk fixes automatically"/> <Button x:Name="FullAutoBtn" Content="Full Automated Maintenance" Style="{StaticResource AccentButtonStyle}" Margin="0,0,0,6" Height="36" Foreground="White" ToolTip="Run extended maintenance including updates and full scans"/> <Button x:Name="OpenLogsBtn" Content="Open Log Folder" Style="{StaticResource AccentButtonStyle}" Margin="0,0,0,6" Height="36" Foreground="White"/> <Button x:Name="CopySummaryBtn" Content="Copy Summary" Style="{StaticResource NavButtonStyle}"/> <TextBlock Text="Jump to results" FontWeight="SemiBold" FontSize="12" Margin="0,12,0,8" Foreground="{StaticResource TextPrimaryBrush}"/> <Border Style="{StaticResource StatCardStyle}" Margin="0,0,0,8"> <StackPanel> <Button x:Name="NavOverviewBtn" Style="{StaticResource NavButtonStyle}" ToolTip="High-level summary of findings"> <StackPanel Orientation="Horizontal"><TextBlock Text="Overview"/></StackPanel> </Button> <Button x:Name="NavSSDBtn" Style="{StaticResource NavButtonStyle}" ToolTip="Health and wear of storage devices"> <StackPanel Orientation="Horizontal"><TextBlock Text="SSD Health"/></StackPanel> </Button> <Button x:Name="NavWHEABtn" Style="{StaticResource NavButtonStyle}" ToolTip="Hardware error events (kernel-level hardware reports)"> <StackPanel Orientation="Horizontal"><TextBlock Text="Hardware Errors"/></StackPanel> </Button> <Button x:Name="NavTdrBtn" Style="{StaticResource NavButtonStyle}" ToolTip="Graphics/timeouts and driver crash evidence"> <StackPanel Orientation="Horizontal"><TextBlock Text="Graphics Timeouts"/></StackPanel> </Button> <Button x:Name="NavRebootBtn" Style="{StaticResource NavButtonStyle}" ToolTip="Unexpected restarts and crash records"> <StackPanel Orientation="Horizontal"><TextBlock Text="Restarts &amp; Crashes"/></StackPanel> </Button> <Button x:Name="NavStorageBtn" Style="{StaticResource NavButtonStyle}" ToolTip="Timeouts and controller errors for storage"> <StackPanel Orientation="Horizontal"><TextBlock Text="Storage Timeouts"/></StackPanel> </Button> <Button x:Name="NavRawBtn" Style="{StaticResource NavButtonStyle}" Margin="0" ToolTip="Open the detailed text log"> <StackPanel Orientation="Horizontal"><TextBlock Text="Detailed Log"/></StackPanel> </Button> </StackPanel> </Border> <TextBlock Text="Repair Options" FontWeight="SemiBold" FontSize="12" Margin="0,12,0,8" Foreground="{StaticResource TextPrimaryBrush}"/> <Border Style="{StaticResource StatCardStyle}"> <StackPanel> <CheckBox x:Name="ChkWindowsRepair" Content="Windows Repair" Margin="0,5" Foreground="{StaticResource TextPrimaryBrush}"/> <TextBlock Text="Reset update cache, fix component store" FontSize="9" Foreground="{StaticResource TextSecondaryBrush}" Margin="20,0,0,8"/> <CheckBox x:Name="ChkTdrTweak" Content="GPU Driver Adjustment" Margin="0,5" Foreground="{StaticResource TextPrimaryBrush}"/> <TextBlock Text="Increase TDR delay for timeout issues" FontSize="9" Foreground="{StaticResource TextSecondaryBrush}" Margin="20,0,0,8"/> <CheckBox x:Name="ChkNetReset" Content="Network Reset" Margin="0,5" Foreground="{StaticResource TextPrimaryBrush}"/> <TextBlock Text="Reset TCP/IP stack and Winsock" FontSize="9" Foreground="{StaticResource TextSecondaryBrush}" Margin="20,0,0,8"/> <CheckBox x:Name="ChkMemDiag" Content="Memory Diagnostics" Margin="0,5" Foreground="{StaticResource TextPrimaryBrush}"/> <TextBlock Text="Launch Windows Memory Diagnostic" FontSize="9" Foreground="{StaticResource TextSecondaryBrush}" Margin="20,0,0,8"/> <CheckBox x:Name="ChkDefenderScan" Content="Full Defender Scan" Margin="0,5" Foreground="{StaticResource TextPrimaryBrush}"/> <TextBlock Text="Comprehensive malware scan" FontSize="9" Foreground="{StaticResource TextSecondaryBrush}" Margin="20,0,0,0"/> </StackPanel> </Border> <Button x:Name="RepairsBtn" Content="Selected Repairs" Style="{StaticResource PrimaryButtonStyle}" Margin="0,12,0,0" Background="#C94B20" BorderBrush="#8F3315" IsEnabled="False"/> </StackPanel> </ScrollViewer> <!-- RIGHT PANEL: RESULTS --> <Grid Grid.Column="1"> <Grid.RowDefinitions> <RowDefinition Height="auto"/> <RowDefinition Height="auto"/> <RowDefinition Height="*"/> </Grid.RowDefinitions> <WrapPanel Grid.Row="0" Margin="0,0,0,8"> <Border Style="{StaticResource StatCardStyle}" Width="188" Height="92"> <StackPanel> <TextBlock Text="Top Issue" Foreground="{StaticResource TextSecondaryBrush}" FontSize="9"/> <TextBlock x:Name="TopIssueCardText" Text="Awaiting scan" Foreground="{StaticResource TextPrimaryBrush}" FontSize="16" FontWeight="Bold" Margin="0,6,0,0" TextWrapping="Wrap"/> </StackPanel> </Border> <Border Style="{StaticResource StatCardStyle}" Width="188" Height="92"> <StackPanel> <TextBlock Text="Findings" Foreground="{StaticResource TextSecondaryBrush}" FontSize="9"/> <TextBlock x:Name="FindingsCardText" Text="0 total" Foreground="{StaticResource TextPrimaryBrush}" FontSize="16" FontWeight="Bold" Margin="0,6,0,0"/> </StackPanel> </Border> <Border Style="{StaticResource StatCardStyle}" Width="188" Height="92"> <StackPanel> <TextBlock Text="Health State" Foreground="{StaticResource TextSecondaryBrush}" FontSize="9"/> <TextBlock x:Name="HealthCardText" Text="Idle" Foreground="{StaticResource TextPrimaryBrush}" FontSize="16" FontWeight="Bold" Margin="0,6,0,0"/> </StackPanel> </Border> <Border Style="{StaticResource StatCardStyle}" Width="188" Height="92" Margin="0,0,0,8"> <StackPanel> <TextBlock Text="Last Scan" Foreground="{StaticResource TextSecondaryBrush}" FontSize="9"/> <TextBlock x:Name="LastRunCardText" Text="Not scanned yet" Foreground="{StaticResource TextPrimaryBrush}" FontSize="16" FontWeight="Bold" Margin="0,6,0,0" TextWrapping="Wrap"/> </StackPanel> </Border> </WrapPanel> <TextBlock Grid.Row="1" Text="Diagnostic Results" FontWeight="SemiBold" FontSize="12" Margin="0,0,0,8" Foreground="{StaticResource TextPrimaryBrush}"/> <TabControl x:Name="ResultsTabs" Grid.Row="2" Background="#10141A" BorderBrush="{StaticResource SurfaceBorderBrush}" BorderThickness="1"> <TabItem Header="Overview"> <TextBlock x:Name="ResultsOverviewBlock" Text="Start a scan to see results..." Padding="15" TextWrapping="Wrap" FontSize="10" Foreground="#D7DCE4" VerticalAlignment="Top"/> </TabItem> <TabItem Header="SSD Health"> <DataGrid x:Name="SSDHealthGrid" AutoGenerateColumns="True" CanUserAddRows="False" Padding="15" IsReadOnly="True" BorderThickness="0"/> </TabItem> <TabItem Header="WHEA Errors"> <DataGrid x:Name="WHEAGrid" AutoGenerateColumns="True" CanUserAddRows="False" Padding="15" IsReadOnly="True" BorderThickness="0"/> </TabItem> <TabItem Header="GPU TDR Events"> <DataGrid x:Name="TDRGrid" AutoGenerateColumns="True" CanUserAddRows="False" Padding="15" IsReadOnly="True" BorderThickness="0"/> </TabItem> <TabItem Header="Reboot Events"> <DataGrid x:Name="RebootGrid" AutoGenerateColumns="True" CanUserAddRows="False" Padding="15" IsReadOnly="True" BorderThickness="0"/> </TabItem> <TabItem Header="Storage Timeouts"> <DataGrid x:Name="StorageGrid" AutoGenerateColumns="True" CanUserAddRows="False" Padding="15" IsReadOnly="True" BorderThickness="0"/> </TabItem> <TabItem Header="Raw Output"> <TextBox x:Name="RawOutputBox" TextWrapping="Wrap" AcceptsReturn="True" IsReadOnly="True" Background="#11141A" Foreground="#EAECEF" Padding="15" FontFamily="Consolas" FontSize="9" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto"/> </TabItem> </TabControl> </Grid> </Grid> <!-- FOOTER / PROGRESS --> <Border Grid.Row="2" Background="#0F1318" BorderBrush="{StaticResource SurfaceBorderBrush}" BorderThickness="1,1,0,0" Padding="10"> <StackPanel> <Grid Margin="0,0,0,6"> <Grid.ColumnDefinitions> <ColumnDefinition Width="*"/> <ColumnDefinition Width="88"/> </Grid.ColumnDefinitions> <Border Grid.Column="0" CornerRadius="3" Background="#1A1F28" Margin="0,0,12,0" Height="14"> <ProgressBar x:Name="ProgressBar" Height="14" Foreground="{StaticResource AccentBrush}" Background="Transparent" Margin="0" VerticalAlignment="Stretch" Minimum="0" Maximum="100" Value="0"/> </Border> <TextBlock x:Name="ProgressPercent" Text="0%" Foreground="{StaticResource TextSecondaryBrush}" FontSize="11" VerticalAlignment="Center" HorizontalAlignment="Right" Grid.Column="1"/> </Grid> <TextBlock x:Name="StatusBlock" Text="Ready" Foreground="{StaticResource TextPrimaryBrush}" FontSize="10"/> <StackPanel Orientation="Horizontal" Margin="0,4,0,0"> <TextBlock x:Name="PhaseBlock" Text="Phase: idle" Foreground="{StaticResource TextSecondaryBrush}" FontSize="9" Margin="0,0,12,0"/> <TextBlock x:Name="EtaBlock" Text="ETA: Not started" Foreground="{StaticResource TextSecondaryBrush}" FontSize="9"/> </StackPanel> <StackPanel Orientation="Horizontal" Margin="0,6,0,0"> <Button x:Name="CancelCoreBtn" Content="Cancel Scan" Visibility="Collapsed" Style="{StaticResource NavButtonStyle}" Width="140"/> </StackPanel> </StackPanel> </Border> </Grid> </Window>
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

function Start-LiveTracking {
    if ($script:LiveTimer) { $script:LiveTimer.Stop() }
    if ($cancelCoreBtn) { $cancelCoreBtn.Visibility = 'Visible' }
    $script:LiveTimer = New-Object Windows.Threading.DispatcherTimer
    $script:LiveTimer.Interval = [TimeSpan]::FromMilliseconds($script:Config.Performance.GUIPollingIntervalMs)
    $script:LiveTimer.Add_Tick({
        $snapshot = Get-ProgressSnapshot
        if ($snapshot) {
            if ($progressBar) { $progressBar.IsIndeterminate = $false; $progressBar.Value = [double]$snapshot.Percent }
            if ($progressPercent) { $progressPercent.Text = ("{0:0.0}%" -f [double]$snapshot.Percent) }
            if ($statusBlock) { $statusBlock.Text = $snapshot.Message }
            if ($phaseBlock) { $phaseBlock.Text = "Phase: $($snapshot.Phase)" }
            if ($etaBlock) { $etaBlock.Text = "ETA: $($snapshot.EtaText)" }
            if ($liveViewBox) { $liveViewBox.Text = Format-LiveSnapshot -Snapshot $snapshot; $liveViewBox.ScrollToEnd() }
        }
    })
    $script:LiveTimer.Start()
}

function Stop-LiveTracking {
    if ($script:LiveTimer) { $script:LiveTimer.Stop() }
    if ($progressBar) { $progressBar.IsIndeterminate = $false }
    if ($cancelCoreBtn) { $cancelCoreBtn.Visibility = 'Collapsed' }
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

    $scriptPath = Join-Path $PSScriptRoot 'Cipher-System-Check-v7-Core.ps1'
    if (-not (Test-Path $scriptPath)) { throw "Core script not found at $scriptPath" }

    $powershellExe = Join-Path $PSHOME 'powershell.exe'
    $argumentList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$scriptPath`"") + $Arguments
    $script:CoreProcess = Start-Process -FilePath $powershellExe -ArgumentList $argumentList -WindowStyle Hidden -PassThru
    Start-LiveTracking
    Wait-ForCoreProcess -Process $script:CoreProcess
    Stop-LiveTracking
    return $script:CoreProcess.ExitCode
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

    if ($statusBlock) { $statusBlock.Text = $Message }
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
            Set-Status 'Core run cancelled by user.'
            if ($cancelCoreBtn) { $cancelCoreBtn.Visibility = 'Collapsed' }
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
            if ($btnToggleSidebar) { $btnToggleSidebar.Content = '▶' }
        } else {
            $col.Width = New-Object System.Windows.GridLength(286)
            if ($btnToggleSidebar) { $btnToggleSidebar.Content = '◀' }
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

function Update-ResultSummary {
    param($Results)
    if (-not $Results) { return }

    $scoreStorage = Get-ScoreValue -Scores $Results.AllScores -Names @('Storage')
    $scoreHardware = Get-ScoreValue -Scores $Results.AllScores -Names @('Hardware', 'WHEA')
    $scoreGpu = Get-ScoreValue -Scores $Results.AllScores -Names @('GPU')
    $scoreMemory = Get-ScoreValue -Scores $Results.AllScores -Names @('Memory')
    $totalFindings = @($Results.SSDs.Count, $Results.WHEAEvents.Count, $Results.TDREvents.Count, $Results.RebootEvents.Count, $Results.StorageTimeouts.Count) | Measure-Object -Sum | Select-Object -ExpandProperty Sum
    $healthText = if ($Results.TopIssueScore -ge 40) { 'CRITICAL' } elseif ($Results.TopIssueScore -ge 20) { 'WARNING' } elseif ($Results.TopIssueScore -ge 1) { 'MINOR' } else { 'HEALTHY' }

    $topIssueCardText.Text = if ($Results.TopIssue) { $Results.TopIssue } else { 'No issues detected' }
    $findingsCardText.Text = "{0} findings" -f $totalFindings
    $healthCardText.Text = $healthText
    $lastRunCardText.Text = if ($Results.Timestamp) { "{0:MMM d, yyyy h:mm tt}" -f [datetime]$Results.Timestamp } else { 'Not run yet' }
    $quickSummaryBlock.Text = "Status: $healthText`nFindings: $totalFindings`nTop issue: $($topIssueCardText.Text)"

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
Storage Devices: $($Results.SSDs.Count) detected
Hardware Errors: $($Results.WHEAEvents.Count) events
GPU Timeouts: $($Results.TDREvents.Count) events
Reboot Events: $($Results.RebootEvents.Count) events
Storage Timeouts: $($Results.StorageTimeouts.Count) events

Diagnostics run: $($Results.Timestamp)

See tabs above for detailed results
"@
    }

    if ($ssdHealthGrid) { $ssdHealthGrid.ItemsSource = $Results.SSDs }
    if ($wheaGrid) { $wheaGrid.ItemsSource = $Results.WHEAEvents }
    if ($tdrGrid) { $tdrGrid.ItemsSource = $Results.TDREvents }
    if ($rebootGrid) { $rebootGrid.ItemsSource = $Results.RebootEvents }
    if ($storageGrid) { $storageGrid.ItemsSource = $Results.StorageTimeouts }
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
    Set-Status 'Starting diagnostics...' 0
    if ($progressBar) { $progressBar.IsIndeterminate = $true }

    try {
        $arguments = @('-QuietMode')
        if ($TestMode) { $arguments += '-TestMode' }
        $exitCode = Start-CoreRun -Arguments $arguments
        if ($exitCode -ne 0) { throw "Core diagnostics exited with code $exitCode" }
        Show-Results
    } catch {
        Stop-LiveTracking
        Set-Status "ERROR: Diagnostics failed: $_"
    }
}

function Invoke-SelectedRepairs {
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
    Invoke-Diagnostics

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
        Set-Status 'Ready to start scan' 0
        Set-LiveViewVisibility
        if ($phaseBlock) { $phaseBlock.Text = 'Phase: idle' }
        if ($etaBlock) { $etaBlock.Text = 'ETA: Not started' }
        Select-ResultsTab 0
    } catch {
        Set-Status "ERROR during initialization: $_"
    }
})

$window.ShowDialog() | Out-Null
