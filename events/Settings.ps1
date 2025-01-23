<#
    .SYNOPSIS
        Events for the Settings page.
#>

# Define the loaded event.
$Settings.Add_Loaded({
    $Settings_Language.SelectedItem = $Settings_Language.Items | Where-Object {
        $_.Tag -eq (Get-AppSetting -Name 'Locale')
    }
})

# Define the language selection event.
$Settings_Language.Add_SelectionChanged({
    Set-AppUILocale -Locale $this.SelectedItem.Tag
})
