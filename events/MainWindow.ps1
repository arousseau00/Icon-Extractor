<#
    .SYNOPSIS
        Events for the main page.
#>

# Navigate to the extract page when the main window is loaded.
$MainWindow.Add_Loaded({
    $MainWindow_PageFrame.Navigate($Extract)
})

# Define the navigation buttons event.
$MainWindow_NavigationGrid.Children | ForEach-Object {
    $_.Add_Click({ $MainWindow_PageFrame.Navigate((Get-Variable -Name $this.Name -ValueOnly)) })
}
