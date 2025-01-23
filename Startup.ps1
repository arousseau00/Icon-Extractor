# Load required assembly.
@('PresentationFramework', 'PresentationCore', 'System.Xml', 'System.Xaml') | ForEach-Object {
    [System.Reflection.Assembly]::LoadWithPartialName($_) | Out-Null
}

# Load the Functions.ps1 file.
. '.\resources\Functions.ps1'

# Create the application.
$Global:Application = [System.Windows.Application]::new()

# Set the UI locale and styles.
Set-AppUILocale
Add-WPFResource -Target $Application -Path '.\resources\Styles.xaml'

# Load interfaces and events.
Get-ChildItem -Path '.\pages\*.xaml' | New-WPFControl
Get-ChildItem -Path '.\events\*.ps1' | ForEach-Object { . $_.FullName }

# Start the application.
$MainWindow.ShowDialog()