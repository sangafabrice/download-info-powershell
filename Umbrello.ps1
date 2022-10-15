<#
    Configuration file --
    OSArch = 'x86'|'x64'
#>
Try {
    $BaseUrl = "https://download.kde.org/stable/umbrello/latest/win$(Switch($OSArch){'x64'{'64'}'x86'{'32'}})/"
    @((Invoke-WebRequest $BaseUrl).Links.href | Where-Object { $_ -like '*setup.exe' })[0] |
    Select-Object @{
        Name = 'Version'
        Expression = { [version] ($_ -split '-')[2] }
    },@{
        Name = 'Link'
        Expression = { "$BaseUrl$_" }
    },@{
        Name = 'Checksum'
        Expression = { ("$(Invoke-WebRequest "$BaseUrl${_}?sha256")" -split ' ')[0] }
    }
} Catch { }