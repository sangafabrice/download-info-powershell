<#
    Configuration file --
    OSArch = 'x86'|'x64'
#>
Try {
    [uri] @(
        (Invoke-WebRequest 'https://krita.org/en/download/krita-desktop/').Links.href |
        Where-Object { $_ -like "*/krita-$OSArch-*-setup.exe" }
    )[0] |
    Select-Object @{
        Name = 'Version'
        Expression = { [version] ($_.Segments[-2] -replace '/$') }
    },@{
        Name = 'Link'
        Expression = { "$_" }
    },@{
        Name = 'Checksum'
        Expression = { ("$(Invoke-WebRequest "${_}?sha256")" -split ' ')[0] }
    }
} Catch { }