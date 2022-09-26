<#
    Configuration file --
#>

Try {
    @{
        Uri = 'https://tunein.com/download/windows/'
        Method  = 'HEAD'
        MaximumRedirection = 0
        SkipHttpErrorCheck = $True
        ErrorAction = 'SilentlyContinue'
        Verbose = $False
    } | ForEach-Object { (Invoke-WebRequest @_).Headers.Location } |
    Select-Object @{
        Name = 'Version'
        Expression = {
            [void] ($_ -match '(?<Version>(\d+\.)+\d+)\.exe$')
            [version] $Matches.Version
        }
    },@{
        Name = 'Link'
        Expression = { $_ }
    }
}
Catch { }