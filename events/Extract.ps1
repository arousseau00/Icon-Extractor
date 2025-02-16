$Extract.Add_Loaded({
    # Set the default icon size.
    if (!$Extract_IconSizeSlider.IsEnabled) {
        $Extract_IconSizeSlider.IsEnabled = $true
        $Extract_IconSizeSlider.Value = $CurrentSettings.IconSize
    }
})

$Extract_IconPathTextBox.Add_TextChanged({
    if (Test-Path $Extract_IconPathTextBox.Text) {
        Update-ImageControl -ImageControl $Extract_IconPreviewImage -ImagePath $Extract_IconPathTextBox.Text
    } 
})

$Extract_IconSizeSlider.Add_ValueChanged({
    $size = [System.Math]::Pow(2, $Extract_IconSizeSlider.Value)
    $Extract_IconSizeText.Text = '{0}x{0}' -f $size
    $Extract_IconPreviewImage.Width = $size
    $Extract_IconPathTextBox.Text = "$TempDirectory\$($Extract_IconPreviewImage.Width).png"
})

$Extract_BrowseButton.Add_Click({
    # Open the file dialog.
    $SelectFileDialog = [Microsoft.Win32.OpenFileDialog]::new()
    $SelectFileDialog.Filter = 'Executables (*.exe)|*.exe'

    if ($SelectFileDialog.ShowDialog()) {
        New-IconSet -FilePath $SelectFileDialog.FileName
        $Extract_IconPathTextBox.Clear()
        $Extract_IconPathTextBox.Text = "$TempDirectory\$($Extract_IconPreviewImage.Width).png"
        $Extract_SaveAsButton.IsEnabled = $true
    }
})

$Extract_SaveAsButton.Add_Click({
    # Open the file dialog.
    $dialog = [Microsoft.Win32.SaveFileDialog]::new()
    $dialog.Filter = 'PNG Files (*.png)|*.png'

    if ($dialog.ShowDialog()) {
        Save-Image -ImageSource $Extract_IconPreviewImage.Source -FilePath $dialog.FileName
        [System.Windows.MessageBox]::Show($Application.Resources.MergedDictionaries[0].IconSaved, 'Icon Extractor', 'OK', 'Information')
    }
})
