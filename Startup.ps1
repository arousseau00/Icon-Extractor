# MARK: Assembly
# Load required assembly and files.
@('PresentationFramework', 'PresentationCore', 'System.Xml', 'System.Xaml') | ForEach-Object {
    [System.Reflection.Assembly]::LoadWithPartialName($_) | Out-Null
}
. '.\resources\Functions.ps1'

# Create the application.
$Global:Application = [System.Windows.Application]::new()

# MARK: Settings
# Ensure settings are set and apply them.
$Global:DefaultSettings = @{
    Locale = 'en'
    IconSize = 256
}
Set-DefaultSettings -Path "$env:APPDATA\IconExtractor\settings.json" -DefaultSettings $DefaultSettings
Add-WPFResource -Target $Application -Path '.\resources\Styles.xaml'

# MARK: Interfaces
# Load interfaces and events.
Get-ChildItem -Path '.\pages\*.xaml' | New-WPFControl
Get-ChildItem -Path '.\events\*.ps1' | ForEach-Object { . $_.FullName }

# Start the application.
$MainWindow.ShowDialog()