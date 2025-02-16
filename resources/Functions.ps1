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

function Update-AppUILocale {
    [CmdletBinding()]
    param ()
    
    begin {}
    
    process {
        # Create the localized strings resource dictionary.
        $localizedStrings = New-WPFLocalizedString -Path '.\resources\Strings.json' -Locale $CurrentSettings.Locale

        # Load the localized strings in the application.
        Add-WPFResource -Target $Application -ResourceDictionary $localizedStrings
    }
    
    end {}
}

function New-IconSet {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path -Path $_ -PathType 'Leaf' })]
        [string]$FilePath
    )
    
    begin {}

    process {
        @(16, 32, 64, 128, 256, 512) | ForEach-Object {
            $icon = [System.Drawing.Icon]::ExtractIcon($FilePath, 0, $_)
            $bitmap = $icon.ToBitmap()
            try {
                $bitmap.Save("$TempDirectory\$_.png")
            } catch {
                return
            } finally {
                $bitmap.Dispose()
            }
        }
    }

    end {}
}

function Save-Image {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Windows.Media.ImageSource]$ImageSource,

        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    begin {}
    
    process {
        $ImageSource.ToString() -as [uri] | Select-Object -ExpandProperty 'LocalPath' | Copy-Item -Destination $FilePath -Force
    }
    
    end {}
}

function Set-DefaultSetting {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path -Path $_ -PathType 'Leaf' -IsValid})]
        [string]$Path,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [hashtable]$SettingTable,

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

        $settingsFromFile = if (Test-Json -Path $Path -ErrorAction 'SilentlyContinue') {
            Write-Verbose -Message 'Settings file is a valid JSON object. Loading it.'
            Get-Content -Path $Path | ConvertFrom-Json
        } else {
            Write-Verbose -Message 'Settings file is not a valid JSON object. Creating a new one.'
            [PSCustomObject]::new()
        }
    }
    
    process {
        foreach ($setting in $SettingTable.GetEnumerator()) {
            if (!($settingsFromFile.($setting.Name))) {
                Write-Verbose -Message "Setting the default value for $($setting.Name)."
                $settingsFromFile | Add-Member -MemberType 'NoteProperty' -Name $setting.Name -Value $setting.Value -Force
            } else {
                Write-Verbose -Message "The value for $($setting.Name) is already set. Skipping."
            }
        }
    }
    
    end {
        Write-Verbose -Message 'Saving the settings file.'
        $settingsFromFile | ConvertTo-Json | Set-Content -Path $Path
    }
}

function Import-Setting {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path -Path $_ -PathType 'Leaf' })]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$VariableName
    )

    begin {}

    process {
        try {
            Test-Json -Path $Path | Out-Null
            Write-Verbose -Message 'Settings file is a valid JSON object. Loading it.'
            $settingsFromFile = Get-Content -Path $Path | ConvertFrom-Json
            Set-Variable -Name $VariableName -Value $settingsFromFile -Scope 'Global'
        } catch {
            Write-Error -Message 'The settings file is not a valid JSON object.'
        }
    }

    end {}
}

function Export-Setting {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path -Path $_ -PathType 'Leaf' })]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$VariableName
    )
    
    begin {
        
    }
    
    process {
        try {
            Get-Variable -Name $VariableName -ValueOnly | ConvertTo-Json | Set-Content -Path $Path
            Write-Verbose -Message 'Settings exported successfully.'
        } catch {
            Write-Error -Message 'Failed to export settings.'
        }
    }
    
    end {
        
    }
}

function Initialize-TempDirectory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$VariableName
    )
    
    begin {}
    
    process {
        $newTempName = [System.IO.Path]::GetRandomFileName()
        $newFolder = New-Item -Path $env:TEMP -ItemType 'Directory' -Name $newTempName -Force
        $newFolder.GetFiles() | Remove-Item -Force

        Set-Variable -Name $VariableName -Value $newFolder.FullName -Scope 'Global'
    }
    
    end {}
}

function Update-ImageControl {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Windows.Controls.Image]$ImageControl,

        [Parameter(Mandatory = $true)]
        [string]$ImagePath
    )
    
    begin {
        
    }
    
    process {
        if ($ImagePath) {
            $stream = [System.IO.File]::OpenRead($ImagePath)
            try {
                $bitmapImage = [System.Windows.Media.Imaging.BitmapImage]::new()
                $bitmapImage.BeginInit()
                $bitmapImage.StreamSource = $stream
                $bitmapImage.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                $bitmapImage.EndInit()
                $ImageControl.Source = $bitmapImage
            } finally {
                $stream.Close()
                $stream.Dispose()
            }
        }
    }
    
    end {
        
    }
}