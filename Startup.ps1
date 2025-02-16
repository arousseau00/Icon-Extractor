$ErrorActionPreference = 'Stop'

# Load required assembly and files.
@('PresentationFramework', 'PresentationCore', 'System.Xml', 'System.Xaml') | ForEach-Object {
    [System.Reflection.Assembly]::LoadWithPartialName($_) | Out-Null
}
. '.\resources\Functions.ps1'

# Create the application.
$Global:Application = [System.Windows.Application]::new()

# Ensure settings are set and apply them.
$Global:DefaultSettings = @{
    Locale = 'en'
    IconSize = 8
}
Set-DefaultSetting -Path "$env:APPDATA\IconExtractor\settings.json" -SettingTable $DefaultSettings
Import-Setting -Path "$env:APPDATA\IconExtractor\settings.json" -VariableName 'CurrentSettings'
Update-AppUILocale
Initialize-TempDirectory -VariableName 'TempDirectory'

# Load interfaces and events.
Add-WPFResource -Target $Application -Path '.\resources\Styles.xaml'
Get-ChildItem -Path '.\pages\*.xaml' | New-WPFControl
Get-ChildItem -Path '.\events\*.ps1' | ForEach-Object { . $_.FullName }

# Start the application.
$Application.Run($MainWindow)
