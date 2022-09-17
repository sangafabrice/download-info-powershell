<#
    Configuration file --
#>

Try {
    @{
        Uri = 'https://updates.insomnia.rest/downloads/windows/latest'
        MaximumRedirection = 0
        SkipHttpErrorCheck = $True
        ErrorAction = 'SilentlyContinue'
    } | ForEach-Object { Invoke-WebRequest @_ -Verbose:$False } |
    Where-Object StatusCode -EQ 302 |
    ForEach-Object { $_.Headers.Location } |
    Select-Object @{
        Name = 'Version'
        Expression = { ([uri] $_).Segments?[-2] -replace '/$' }
    },@{
        Name = 'Link'
        Expression = { $_ }
    }
}
Catch { }