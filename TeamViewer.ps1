<#
    Configuration file --
    OSArch = 'x86'|'x64'
#>

Try {
    [pscustomobject] @{
        Version = [version] (([uri] ((Invoke-WebRequest 'https://community.teamviewer.com//English/discussions/tagged/windows').Links.href -match 'windows-v(\d+-)+\d+$')[0]).Segments[-1] -split 'v' -replace '-','.')[-1]
        Link = "https://dl.teamviewer.com/download/TeamViewer_Setup$($OSArch -eq 'x64' ? '_x64':'').exe"
    }
} Catch { }