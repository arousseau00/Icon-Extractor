[CmdletBinding()]
param (
    [Parameter()]
    [string]$Path
)

& .\7z.exe e -bso0 -bsp0 -y -o"D:\Github\Icon-Extractor\test" "$Path" -- *\ICON\*

$files = Get-ChildItem -Path "D:\Github\Icon-Extractor\test\" | Sort-Object { [int]($_.BaseName) }

Add-Type -AssemblyName System.Drawing

$iconSize = [System.Collections.Generic.HashSet[System.Drawing.Size]]::new()

$iconSize.Add([System.Drawing.Size]::new(16, 16))
$iconSize.Add([System.Drawing.Size]::new(32, 32))

while (condition) {
    
}

do {
    
} until ($iconSize.Contains($currentSize))

