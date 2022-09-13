<#
    Configuration file --
    OSArch = 'x86'|'x64'
#>

Try {
    Get-DownloadInfo -PropertyList @{
        UpdateServiceURL = 'https://update.googleapis.com/service/update2'
        ApplicationID    = '{8A69D345-D564-463c-AFF1-A69D9E530F96}'
        OwnerBrand       = "$(
            Switch ($OSArch) {
                'x64'   { 'YTUH' }
                Default { 'GGLS' }
            }
        )"
        ApplicationSpec  = "$(
            Switch ($OSArch) {
                'x64'   { 'x64-stable-statsdef_1' }
                Default { 'stable-arch_x86-statsdef_1' }
            }
        )"
    } -From Omaha | Select-Object @{
        Name = 'Link'
        Expression = { "$($_.Link.Where({ "$_" -like 'https://*' }, 'First'))" }
    },Version,Checksum
}
Catch { }