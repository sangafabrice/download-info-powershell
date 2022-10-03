<#
    Configuration file --
    OSArch = 'x86'|'x64'
#>

Try {
    $BaseUrl = 'https://get.videolan.org/vlc/last/win{0}/' -f
        $(Switch ($OSArch) { 'x64' { '64' } 'x86' { '32' } })
    ,((Invoke-WebRequest $BaseUrl).Links.href -match '\.exe(\.sha256)?$') |
    ForEach-Object {
        $SelectMirrorUrl = {
            Param(
                $Array,
                $Extension
            )
            $Array -like "*$Extension" |
            ForEach-Object { ((Invoke-WebRequest "$BaseUrl$_").Links.href -like "https://mirror*$_")[0] }
        }
        [pscustomobject] @{
            Version = ($_[0] -split '-')[1]
            Link = & $SelectMirrorUrl $_ '.exe'
            Checksum = ("$(Invoke-WebRequest (& $SelectMirrorUrl $_ '.sha256'))" -split ' ')[0]
        }
    }
} Catch { $_ }