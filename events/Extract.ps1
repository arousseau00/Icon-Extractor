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
    $Extract_IconSizeValue.Text = '{0}x{0}' -f $size

    # Update the icon preview.
    $Extract_IconPreviewImage.Width = $size
    $Extract_IconPreviewImage.Height = $size
    if ($Extract_IconPreviewImage.Tag) {
        $paramSetIconPreview = @{
            Control  = $Extract_IconPreviewImage
            FilePath = $Extract_IconPreviewImage.Tag
            Size     = $size
        }
        Set-IconPreview @paramSetIconPreview
    }
})

$Extract_BrowseButton.Add_Click({
    # Open the file dialog.
    $dialog = [Microsoft.Win32.OpenFileDialog]::new()
    $dialog.Filter = 'Executables (*.exe)|*.exe'
    if ($dialog.ShowDialog()) {
        $Extract_IconPreviewImage.Tag = $dialog.FileName
        $paramSetIconPreview = @{
            Control  = $Extract_IconPreviewImage
            FilePath = $dialog.FileName
            Size     = $Extract_IconPreviewImage.Width
        }
        Set-IconPreview @paramSetIconPreview
    }
})

$Extract_SaveAsButton.Add_Click({
    # Open the file dialog.
    $dialog = [Microsoft.Win32.SaveFileDialog]::new()
    $dialog.Filter = 'PNG Files (*.png)|*.png|JPEG Files (*.jpg)|*.jpg|GIF Files (*.gif)|*.gif|BMP Files (*.bmp)|*.bmp'
    if ($dialog.ShowDialog()) {
        Save-Image -ImageSource $Extract_IconPreviewImage.Source -FilePath $dialog.FileName
    }
})

$Extract_IconPreviewImage.Add_DpiChanged({
    # When an image is loaded, enable the save as button.
    $Extract_SaveAsButton.IsEnabled = $true
})
