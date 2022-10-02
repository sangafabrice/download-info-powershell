<#
    Configuration file --
#>

Try {
    ,$(
        Get-DownloadInfo -PropertyList @{
            RepositoryId = 'mltframework/shotcut'
            AssetPattern = 'shotcut\-win64\-.*\.exe$|sha256sums.txt$'
        }
    ) | ForEach-Object {
        [pscustomobject] @{
            Version = ($_ | Select-Object Version -Unique).Version
            Link = "$($_.Link -like '*shotcut-win64-*.exe')"
            Checksum = (
                $_ | Where-Object Link -Like '*sha256sums.txt' |
                ForEach-Object {
                    "$(Invoke-WebRequest $_.Link)" -split "`n" | 
                    ConvertFrom-String |
                    Where-Object P2 -Like 'shotcut-win64-*.exe'
                }
            ).P1
        }
    }
} Catch { }