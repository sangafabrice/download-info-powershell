<#
    Configuration file --
    OSArch = 'x86'|'x64'
#>

Try {
    ,$(
        Get-DownloadInfo -PropertyList @{
            RepositoryId = 'notepad-plus-plus/notepad-plus-plus'
            AssetPattern = 'Installer\.{0}exe$|checksums.sha256$' -f ($OSArch -eq 'x64' ? 'x64\.':'')
        }
    ) | ForEach-Object {
        [pscustomobject] @{
            Version = ($_ | Select-Object Version -Unique).Version
            Link = "$($_.Link -like '*.exe')"
            Checksum = (
                $_ | Where-Object Link -Like '*.sha256' |
                ForEach-Object {
                    "$(Invoke-WebRequest $_.Link)" -split "`n" | 
                    ConvertFrom-String |
                    Where-Object P2 -Like ('npp.*.Installer.{0}exe' -f ($OSArch -eq 'x64' ? 'x64.':''))
                }
            ).P1
        }
    }
} Catch { }