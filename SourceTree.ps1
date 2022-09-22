<#
    Configuration file --
#>

Try {
    (Invoke-WebRequest "https://www.sourcetreeapp.com/download-archives" -Verbose:$False).Links.href |
    Where-Object { $_ -like '*.exe' } |
    Select-Object @{
        Name = 'Version'
        Expression = {
            [void] ($_ -match '(?<Version>(\d+\.)+\d+)\.exe$')
            [version] $Matches.Version
        }
    },@{
        Name = 'Link'
        Expression = { $_ }
    } -First 1
}
Catch { }