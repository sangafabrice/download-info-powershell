<#
    Configuration file --
    OSArch = 'x86'|'x64'
#>

Try {
    [pscustomobject] @{
        Version = $(
            ((Invoke-WebRequest 'https://browser.yandex.ru/corp' -Verbose:$False).Links |
            Where-Object outerHTML -Like "*Windows $(Switch ($OSArch) { 'x64' { 'x64' } 'x86' { 'x32' } })*").outerHTML |
            ForEach-Object { 
                [void] ($_ -match '(?<Version>(\d+\.)+\d+)')
                $Matches.Version
            } | Select-Object -Unique -First 1
        )
        Resource = $(
            @{
                Uri = 'https://browser.yandex.ru/corp/api/download/get/'
                Method = 'POST'
                ContentType = 'text/plain;charset=UTF-8'
                Body = ('{{"platform":"win_{0}"}}' -f $(Switch ($OSArch) { 'x64' { 'x64' } 'x86' { 'x32' } }))
            } | ForEach-Object { [uri] ("$(Invoke-WebRequest @_ -Verbose:$False)" | ConvertFrom-Json).url } |
            Select-Object @{
                Name = 'Link'
                Expression = { $_ }
            },@{
                Name = 'Name'
                Expression = {
                    ([uri] $_).query -replace '\?' -split '&' |
                    Where-Object { $_ -like 'filename=*' } |
                    ForEach-Object { ($_ -split '=')?[-1] }
                }
            }
        )
    } | Select-Object Version -ExpandProperty Resource
} Catch { }