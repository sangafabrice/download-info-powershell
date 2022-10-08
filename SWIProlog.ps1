<#
    Configuration file --
    OSArch = 'x86'|'x64'
#>
#Requires -Module @{ModuleName = 'SelectHtml'; ModuleVersion = '1.0.1'}

Try {
    $BaseUrl = 'https://www.swi-prolog.org/download/stable'
    $url = Invoke-WebRequest $BaseUrl
    $Anchor = ($url.Links | Where-Object href -Like "*$OSArch.exe.envelope")
    $SetupDescription = ((Select-Html "//td[@class='dl_file']" -Html $url.Content) -like "$(Select-Html /a -Html $Anchor.outerHTML)*") -split "`n"
    [pscustomobject] @{
        Version = $(
            [void] ("$($SetupDescription.Where({ $_ },'First'))" -match '(?<Version>(\d+\.){2}\d+-\d+)')
            $Matches.Version
        )
        Link = $BaseUrl -replace '/download/stable$',$Anchor.href -replace '\.envelope$'
        Checksum = ($SetupDescription.Where({ $_ -like 'SHA256:*' }) -split ':')[-1]
    }
} Catch { }