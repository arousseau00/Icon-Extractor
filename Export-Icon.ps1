function Export-Icon {
    <#
        .SYNOPSIS
        Extracts the icon from a given executable and saves it as a PNG file.

        .DESCRIPTION
        Extracts the icon from a given executable and saves it as a PNG file using the executable name as the base name.

        .PARAMETER FilePath
        Path to the executable to extract the icon from.

        .PARAMETER DestinationPath
        Path to save the icon as a PNG file.
        If not provided, the destination path will be the same as the executable path.

        .PARAMETER Size
        The size of the icon to extract.
        Defaults to 256.

        .PARAMETER Force
        If set, the icon will be extracted even if the destination file already exists.

        .EXAMPLE
        (Get-ChildItem -Path $env:ProgramFiles\software).FullName | Export-Icon -DestinationPath 'C:\Icons' -Size 128 -Force

    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateScript({ Test-Path -Path $_ -PathType 'Leaf' })]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [ValidateScript({ Test-Path -Path $_ -PathType 'Container' -IsValid})]
        [string]$DestinationPath,

        [Parameter(Mandatory = $false)]
        [ValidateRange(16, 512)]
        [int]$Size = 256,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    begin {
        # Set the image format to PNG
        $imageFormat = [System.Drawing.Imaging.ImageFormat]::Png
    }

    process {
        # Set the destination path if not provided
        if (!$DestinationPath) { $DestinationPath = Split-Path -Path $FilePath -Parent }
        # Ensure the destination directory exists
        if (!(Test-Path -Path $DestinationPath)) { New-Item -Path $DestinationPath -ItemType Directory -Force | Out-Null }

        # Construct the full path for the output PNG file
        $iconName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
        $iconFullName = "$DestinationPath\$iconName.png"

        # Extract and save the icon if the Force switch is set or the file does not exist
        if ($Force -or !(Test-Path -Path $iconFullName)) {
            [System.Drawing.Icon]::ExtractIcon($FilePath, 0, $Size).ToBitmap().Save($iconFullName, $imageFormat)
        }
    }

    end {}
}
