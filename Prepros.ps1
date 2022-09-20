<#
    Configuration file --
#>

Try {
    @{
        Uri = 'https://prepros.io/downloads/stable/windows'
        Method  = 'HEAD'
        MaximumRedirection = 0
        SkipHttpErrorCheck = $True
        ErrorAction = 'SilentlyContinue'
        Verbose = $False
    } | ForEach-Object { (Invoke-WebRequest @_).Headers.Location } |
    Select-Object @{
        Name = 'Version'
        Expression = { ([uri] $_).Segments?[-2] -replace '/$' }
    },@{
        Name = 'Link'
        Expression = { $_ }
    }
}
Catch { }