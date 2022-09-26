<#
    Configuration file --
#>

Try {
    'https://www.messenger.com/messenger/desktop/downloadV2/?platform=win' |
    Select-Object @{
        Name = 'Resource'
        Expression = {
            $ResponseHeader = (Invoke-WebRequest $_ -Method Head -Verbose:$False).Headers
            [pscustomobject] @{
                Version = [datetime] "$($ResponseHeader.'Last-Modified')"
                Name = ($ResponseHeader.'Content-Disposition' -split '=')?[-1]
            }
        }
    },@{
        Name = 'Link'
        Expression = { $_ }
    } | Select-Object Link -ExpandProperty Resource
}
Catch { }