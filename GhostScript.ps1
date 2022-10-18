<#
    Configuration file --
    OSArch = 'x86'|'x64'
#>

Try {
    $MachineType = "w$(Switch ($OSArch) { 'x64' { '64' } 'x86' { '32' } }).exe"
    ,$(
        Get-DownloadInfo -PropertyList @{
            RepositoryId = 'ArtifexSoftware/ghostpdl-downloads'
            AssetPattern = 'ghostscript-.*.tar.xz$|{0}$|SHA512SUMS$' -f $MachineType
        }
    ) | ForEach-Object {
        [pscustomobject] @{
            Version = $(
                [void] (([uri]($_.Link -like '*tar.xz')[0]).Segments[-1] -match '(?<Version>(\d+\.)+\d+)')
                $Matches.Version
            )
            Link = ($_.Link -like '*.exe')[0]
            Checksum = (
                $_ | Where-Object Link -Like '*SHA512SUMS' |
                ForEach-Object {
                    "$(Invoke-WebRequest $_.Link)" -split "`n" | 
                    ConvertFrom-String |
                    Where-Object P2 -Like "*$MachineType"
                }
            ).P1
        }
    }
} Catch { }