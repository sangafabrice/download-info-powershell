<#
    Configuration file --
#>

Try {
    (Invoke-WebRequest 'https://gitlab.com/api/v4/projects/librewolf-community%2Fbrowser%2Fwindows/releases/').Content |
    Out-String | ConvertFrom-Json | Where-Object name -Like 'Release*' | 
    Select-Object tag_name,@{
        Name = 'link'
        Expression = { $_.assets.links.url -match '(\.exe$)|(\.txt$)' }
    } -First 1 |
    Select-Object @{
        Name = 'Version'
        Expression = { $_.tag_name }
    },@{
        Name = 'Link'
        Expression = { $_.link -like '*.exe' }
    },@{
        Name = 'Checksum'
        Expression = {
            ("$(Invoke-WebRequest "$($_.link -like '*.txt')")" -split "`n" |
            ConvertFrom-String | Where-Object P2 -Like '*.exe').P1 }
    }
}
Catch { }