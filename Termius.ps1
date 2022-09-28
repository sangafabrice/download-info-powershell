<#
    Configuration file --
#>

Try {
    'https://termius.com/download/windows/Termius.exe' |
    Select-Object @{
        Name = 'LastModified'
        Expression = { [datetime] "$((Invoke-WebRequest $_ -Method Head -Verbose:$False).Headers.'Last-Modified')" }
    },@{
        Name = 'Link'
        Expression = { $_ }
    }
}
Catch { }