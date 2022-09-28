<#
    Configuration file --
#>

Try {
    @{
        Uri = 'https://cdn.localwp.com/stable/latest/windows'
        Method  = 'HEAD'
        MaximumRedirection = 0
        SkipHttpErrorCheck = $True
        ErrorAction = 'SilentlyContinue'
        Verbose = $False
    } | ForEach-Object { (Invoke-WebRequest @_).Headers.Location } |
    Select-Object @{
        Name = 'Version'
        Expression = { [version] (([uri] $_).Segments?[-2] -split '\+')?[0] }
    },@{
        Name = 'Link'
        Expression = { $_ }
    }
}
Catch { }