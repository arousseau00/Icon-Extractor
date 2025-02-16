<#
    .SYNOPSIS
        Events for the settings page.
#>

# Define the loaded event.
$Settings.Add_Loaded({
    $Settings_Language.SelectedItem = $Settings_Language.Items | Where-Object {
        $_.Tag -eq $CurrentSettings.Locale
    }

    $Settings_IconSize.SelectedItem = $Settings_IconSize.Items | Where-Object {
        $_.Tag -eq $CurrentSettings.IconSize
    }
})

# Define the language selection event.
$Settings_Language.Add_SelectionChanged({
    $CurrentSettings.Locale = $Settings_Language.SelectedItem.Tag
    Export-Setting -Path "$env:APPDATA\IconExtractor\settings.json" -VariableName 'CurrentSettings'
    Update-AppUILocale
})

# Define the icon size selection event.
$Settings_IconSize.Add_SelectionChanged({
    $CurrentSettings.IconSize = $Settings_IconSize.SelectedItem.Tag
    Export-Setting -Path "$env:APPDATA\IconExtractor\settings.json" -VariableName 'CurrentSettings'
})

# Define the reset settings event.
$Settings_ResetButton.Add_Click({
    Set-DefaultSetting -Path "$env:APPDATA\IconExtractor\settings.json" -SettingTable $DefaultSettings -Force
    Import-Setting -Path "$env:APPDATA\IconExtractor\settings.json" -VariableName 'CurrentSettings'

    $Settings_Language.SelectedItem = $Settings_Language.Items | Where-Object {
        $_.Tag -eq $CurrentSettings.Locale
    }
    $Settings_IconSize.SelectedItem = $Settings_IconSize.Items | Where-Object {
        $_.Tag -eq $CurrentSettings.IconSize
    }
})