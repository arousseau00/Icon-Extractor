<#
    .SYNOPSIS
        Events for the applications page.
#>

$Extract.Add_Loaded({
        # Set the default icon size.
        $Extract_IconSizeSlider.Value = 9
})

$Extract_IconSizeSlider.Add_ValueChanged({
        # Update the icon label.
        $size = [System.Math]::Pow(2, $Extract_IconSizeSlider.Value)
        $Extract_IconSizeValue.Content = '{0}x{0}' -f $size

        # Update the icon preview.
        $Extract_IconPreviewImage.Width = $size
        $Extract_IconPreviewImage.Height = $size
})

$Extract_BrowseButton.Add_Click({
        # Open the file dialog.
        $dialog = [Microsoft.Win32.OpenFileDialog]::new()
        $dialog.Filter = 'All Files (*.*)|*.*'
        $dialog.ShowDialog() | Out-Null
        $Extract_IconPreviewImage.Source = $dialog.FileName
})

$Extract_SaveAsButton.Add_Click({
        # Open the file dialog.
        $dialog = [Microsoft.Win32.SaveFileDialog]::new()
        $dialog.Filter = 'All Files (*.*)|*.*'
        $dialog.ShowDialog() | Out-Null
        $dialog.FileName
})