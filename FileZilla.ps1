<#
    Configuration file --
    Type = 'server'|'client'
    OSArch = 'x86'|'x64'
#>
Try {
    $Urls =
        (Invoke-WebRequest "https://filezilla-project.org/download.php?show_all=1&type=$($Type.ToLower())" -UserAgent 'Curl').Links.href |
        Where-Object { $_ -like '*?h=*' }
    [uri] @($Urls | Where-Object { $_ -like '*sha512?h=*' })[0] |
    Select-Object @{
        Name = 'Version'
        Expression = { ($_.Segments[-1] -replace '.sha512$' -split '_')[-1] }
    },@{
        Name = 'Resource'
        Expression = {
            ,(("$(Invoke-WebRequest $_.OriginalString)" -split "`n" | Where-Object { $_ -like "*win$(Switch($OSArch){'x64'{'64'}'x86'{'32'}})-setup.exe" }) -split ' ') |
            Select-Object @{
                Name = 'Checksum'
                Expression = { $_[0] }
            },@{
                Name = 'Link'
                Expression = { $Urls -like "$($_[-1])*" }
            }
        }
    } | Select-Object Version -ExpandProperty Resource
} Catch { }