function Add-WPFResource {
    <#
        .SYNOPSIS
            Adds resources from XAML files to a WPF target object.

        .DESCRIPTION
            This function reads XAML files and adds their resources to a specified WPF target object.

        .PARAMETER Path
            The path to one or more XAML files to read resources from. This parameter is mandatory.

        .PARAMETER Target
            The WPF target object to add resources to. This parameter is mandatory and can be piped in.

        .EXAMPLE
            Add-WPFResourceFromXAML -Path "C:\Path\To\Resources.xaml" -Target $myWindow

        .EXAMPLE
            $myWindow | Add-WPFResourceFromXAML -Path "C:\Path\To\Resources.xaml"

        .INPUTS
            System.Windows.DependencyObject

        .OUTPUTS
            None

        .NOTES
            This function assumes that the XAML files contain valid resource dictionaries.

    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'Path')]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string[]]$Path,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'ResourceDictionary')]
        [System.Windows.ResourceDictionary]$ResourceDictionary,

        [Parameter(Mandatory = $true)]
        $Target
    )
    
    begin {
        # Save the ErrorActionPreference then change it to Stop.
        $backupErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
        }
    
    process {
        try {
            switch ($PSCmdlet.ParameterSetName) {
                'ResourceDictionary' {
                    $Target.Resources.MergedDictionaries.Add($ResourceDictionary)
                }
                'Path' {
                    $Path | ForEach-Object {
                        $content = [System.IO.File]::ReadAllText($_)
                        $resource = [System.Windows.Markup.XamlReader]::Parse($content)
                        $Target.Resources.MergedDictionaries.Add($resource)
                    }
                }
            }
        } catch {
            throw $_
        }
    }
    
    end {
        # Restore the ErrorActionPreference
        $ErrorActionPreference = $backupErrorActionPreference
    }
}

function New-WPFControl {
    <#
        .SYNOPSIS
            Creates a new WPF control from a XAML file or string.

        .DESCRIPTION
            This function reads a XAML file or string and creates a new WPF control based on its contents.

        .PARAMETER Path
            The path to a XAML file to read.

        .INPUTS
            None

        .OUTPUTS
            System.Windows.Controls.Control

        .NOTES
            This function assumes that the XAML file or string contains valid markup for a WPF control.

    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string]$Path
    )
    
    begin {
        # Save the ErrorActionPreference then change it to Stop.
        $backupErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
    }
    
    process {
        try {
            # Get the base name of the XAML file to use as the child prefix and find the locale resource file.
            $baseName = (Get-Item -Path $Path).BaseName

            # Create an XmlDocument to parse the XAML.
            $content = [System.IO.File]::ReadAllText($Path)
            $xmlDoc = [System.Xml.XmlDocument]$content
            $xaml = [System.Windows.Markup.XamlReader]::Parse($content)

            # Set the variables for the named elements.
            $xmlDoc.SelectNodes("//*[@Name]") | ForEach-Object {
                $paramSetVariable = @{
                    Name  = '{0}_{1}' -f $baseName, $_.Attributes['Name'].Value
                    Value = $xaml.FindName($_.Attributes['Name'].Value)
                    Scope = 'Global'
                    Force = $true
                }
                Set-Variable @paramSetVariable
            }

            # Provide the WPF window or page as a global variable named after the base name.
            Set-Variable -Name $baseName -Value $xaml -Scope 'Global'

        } catch {
            throw $_
        }
    }
    
    end {
        # Restore the ErrorActionPreference
        $ErrorActionPreference = $backupErrorActionPreference
    }
}

function New-WPFLocalizedString {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Locale
    )
    
    begin {
    }
    
    process {
        try {
            # Read the JSON file and create the resource dictionary.
            $strings = [System.IO.File]::ReadAllText($Path) | ConvertFrom-Json           
            $resourceDictionary = [System.Windows.ResourceDictionary]::new()

            # Add the localized strings to the resource dictionary.
            $strings | Get-Member -MemberType 'NoteProperty' | Select-Object -ExpandProperty 'Name' | ForEach-Object {
                $resourceDictionary.Add($_, $strings.$_.$Locale)
            }

            # Return the resource dictionary.
            return $resourceDictionary
        } catch {
            throw $_
        }
    }
    
    end {
    }
}

function Set-AppSetting {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Value
    )
    
    begin {
        $paramPath = @{ Path = "$env:APPDATA\IconExtractor\settings.json" }
        if (!(Test-Path @paramPath)) { New-Item @paramPath -ItemType 'File' -Value '{}' -Force | Out-Null }
    }
    
    process {
        $settings = Get-Content @paramPath | ConvertFrom-Json

        if ($settings | Get-Member -Name $Name) {
            $settings.$Name = $Value
        } else {
            $settings | Add-Member -MemberType 'NoteProperty' -Name $Name -Value $Value
        }
        
        $settings | ConvertTo-Json | Set-Content @paramPath
    }
    
    end {
        
    }
}

function Get-AppSetting {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    
    begin {
        
    }
    
    process {
        $settings = Get-Content -Path "$env:APPDATA\IconExtractor\settings.json" | ConvertFrom-Json
        return $settings.$Name
    }
    
    end {
        
    }
}

function Set-AppUILocale {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Locale
    )
    
    begin {
        # Save the provided locale when provided, otherwise get it from the settings.
        if ($Locale) {
            Set-AppSetting -Name 'Locale' -Value $Locale
        } else {
            $Locale = Get-AppSetting -Name 'Locale' -ErrorAction 'SilentlyContinue'
        }
    }
    
    process {
        
        if (!$Locale) { $Locale = 'en' }
        # Create the localized strings resource dictionary.
        $localizedStrings = New-WPFLocalizedString -Path '.\resources\Strings.json' -Locale $Locale

        # Load the localized strings in the application.
        Add-WPFResource -Target $Application -ResourceDictionary $localizedStrings
    }
    
    end {
        
    }
}

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
        [ValidateScript({ Test-Path -Path $_ -PathType 'Container' -IsValid })]
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

function Set-IconPreview {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Windows.Controls.Image]$Control,

        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path -Path $_ -PathType 'Leaf' })]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [ValidateRange(16, 512)]
        [int]$Size = 256
    )
    
    begin {
        
    }

    process {
        # Extract the icon and set it as the source for the Image control
        $icon = [System.Drawing.Icon]::ExtractIcon($FilePath, 0, $Size).ToBitmap()
        $iconStream = [System.IO.MemoryStream]::new()
        $icon.Save($iconStream, [System.Drawing.Imaging.ImageFormat]::Png)
        $iconStream.Position = 0
        $iconBitmap = [System.Windows.Media.Imaging.BitmapImage]::new()
        $iconBitmap.BeginInit()
        $iconBitmap.StreamSource = $iconStream
        $iconBitmap.EndInit()
        $Control.Source = $iconBitmap
    }

    end {}
}

function Save-Image {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Windows.Media.Imaging.BitmapSource]$ImageSource,

        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    begin {
        $fileStream = [System.IO.File]::Create($FilePath)
    }
    
    process {
        $fileType = [System.IO.Path]::GetExtension($FilePath).TrimStart('.').ToLower()

        $bitmapEncoder = switch ($fileType) {
            'png' { [System.Windows.Media.Imaging.PngBitmapEncoder]::new() }
            'jpg' { [System.Windows.Media.Imaging.JpegBitmapEncoder]::new() }
            'gif' { [System.Windows.Media.Imaging.GifBitmapEncoder]::new() }
            'bmp' { [System.Windows.Media.Imaging.BmpBitmapEncoder]::new() }
            default { throw 'Unsupported file type.' }
        }
        $bitmapEncoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($ImageSource))
        $bitmapEncoder.Save($fileStream)
    }
    
    end {
        $fileStream.Close()
    }
}

function Set-DefaultSettings {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path -Path $_ -PathType 'Leaf' -IsValid})]
        [string]$Path,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [hashtable]$DefaultSettings,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    begin {
        if ($Force) {
            Write-Verbose -Message 'Force switch is set. Overwriting the settings file.'
            New-Item -Path $Path -ItemType 'File' -Value '{}' -Force | Out-Null
        }
        if (!(Test-Path -Path $Path)) {
            Write-Verbose -Message 'Settings file does not exist. Creating a new one.'
            New-Item -Path $Path -ItemType 'File' -Value '{}' | Out-Null
        }
        if ([string]::IsNullOrWhiteSpace((Get-Content -Path $Path))) {
            Write-Verbose -Message 'Settings file is empty. Setting it to an empty object.'
            Set-Content -Path $Path -Value '{}' | Out-Null
        }
        if ((Get-Content -Path $Path) -eq 'null') {
            Write-Verbose -Message 'Settings file is null. Setting it to an empty object.'
            Set-Content -Path $Path -Value '{}' | Out-Null
        }

        $currentSetting = if (Test-Json -Path $Path -ErrorAction 'SilentlyContinue') {
            Write-Verbose -Message 'Settings file is a valid JSON object. Loading it.'
            Get-Content -Path $Path | ConvertFrom-Json
        } else {
            Write-Verbose -Message 'Settings file is not a valid JSON object. Creating a new one.'
            [PSCustomObject]::new()
        }
    }
    
    process {
        foreach ($setting in $DefaultSettings.GetEnumerator()) {
            if (!($currentSetting.($setting.Name))) {
                Write-Verbose -Message "Setting the default value for $($setting.Name)."
                $currentSetting | Add-Member -MemberType 'NoteProperty' -Name $setting.Name -Value $setting.Value -Force
            } else {
                Write-Verbose -Message "The value for $($setting.Name) is already set. Skipping."
            }
        }
    }
    
    end {
        Write-Verbose -Message 'Saving the settings file.'
        $currentSetting | ConvertTo-Json | Set-Content -Path $Path
    }
}
