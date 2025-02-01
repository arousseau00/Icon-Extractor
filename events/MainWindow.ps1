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

# Set the AllowDrop property to true when the extract page is active.
$MainWindow_PageFrame.Add_Navigated({
    if ($this.Content -eq $Extract) {
        $MainWindow.AllowDrop = $true
    } else {
        $MainWindow.AllowDrop = $false
    }
})

# Handle the drag and drop event.
$MainWindow.Add_Drop({
    # Make sure only one file is dropped.
    if ($_.Data.GetFileDropList().Count -gt 1) {
        [System.Windows.MessageBox]::Show('Only one file can be dropped.', 'Error', 'OK', 'Error')
        return
    }
    if (!$_.Data.GetFileDropList()[0].EndsWith('.exe')) {
        [System.Windows.MessageBox]::Show('Only .exe files can be dropped.', 'Error', 'OK', 'Error')
        return
    }

    $Extract_IconPreviewImage.Tag = $_.Data.GetFileDropList()[0]
    $paramSetIconPreview = @{
        Control  = $Extract_IconPreviewImage
        FilePath = $Extract_IconPreviewImage.Tag
        Size     = $Extract_IconPreviewImage.Width
    }
    Set-IconPreview @paramSetIconPreview
})