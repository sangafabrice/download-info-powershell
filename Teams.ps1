<#
    Configuration file --
    OSArch = 'x86'|'x64'
#>

Try {
    [uri] "$(Invoke-WebRequest "https://teams.microsoft.com/downloads/desktopurl?env=production&plat=windows&arch=$OSArch&download=false" -Verbose:$False)" |
    Select-Object @{
        Name = 'Version'
        Expression = { $_.Segments?[-2] -replace '/$' }
    },@{
        Name = 'Link'
        Expression = { "$_" }
    }
}
Catch { }