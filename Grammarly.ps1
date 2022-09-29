<#
    Configuration file --
#>

Try {
    'https://download-windows.grammarly.com/GrammarlyInstaller.exe' |
    Select-Object @{
        Name = 'LastModified'
        Expression = { [datetime] "$((Invoke-WebRequest $_ -Method Head -Verbose:$False).Headers.'Last-Modified')" }
    },@{
        Name = 'Link'
        Expression = { $_ }
    }
}
Catch { }