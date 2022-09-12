<#
    Configuration file --
#>

Try {
    @{
        Uri = 'https://central.github.com/deployments/desktop/desktop/latest/win32'
        Method = 'HEAD'
        MaximumRedirection = 0
        ErrorAction = 'SilentlyContinue'
        SkipHttpErrorCheck = $True
    } | ForEach-Object {
        [uri] "$((Invoke-WebRequest @_ -Verbose:$False).Headers.Location)"
    } |
    Select-Object @{
        Name = 'Version'
        Expression = { ($_.Segments?[-2] -replace '/$' -split '-')?[0] }
    },@{
        Name = 'Link'
        Expression = { "$_" }
    }
}
Catch { }