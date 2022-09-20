<#
    Configuration file --
#>

Try {
    [pscustomobject] @{
        Version = ("$(Invoke-WebRequest 'https://desktop.figma.com/win/RELEASE.json')" | ConvertFrom-Json).version
        Link = 'https://desktop.figma.com/win/FigmaSetup.exe'
    }
} Catch { }