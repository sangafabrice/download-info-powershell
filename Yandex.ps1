<#
    Configuration file --
    OSArch = 'x86'|'x64'
#>

Try {
    (
        (Invoke-WebRequest 'https://browser.yandex.ru/corp' -Verbose:$False).Links |
        Where-Object outerHTML -Like "*Windows $(Switch ($OSArch) { 'x64' { 'x64' } 'x86' { 'x32' } })*" |
        Select-Object href -Unique
    ).href |
    Select-Object @{
        Name = 'Version'
        Expression = {
            [version] (
                (($_ -split '/')?[-3] -split '_',4 |
                ForEach-Object { $i = 0 } { If ($i -eq 3) { ($_ -split '_')[0] } Else { $_ } $i++ }) -join '.'
            )
        }
    },@{
        Name = 'Link'
        Expression = { $_ }
    }
} Catch { }