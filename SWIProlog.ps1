<#
    Configuration file --
    OSArch = 'x86'|'x64'
#>
Try {
    Import-Module "${Env:TEMP}\SelectHtml" -RequiredVersion '1.0.1' -ErrorAction SilentlyContinue -Force
    Get-Module
    If ((Get-Module | Where-Object Name -Like 'SelectHTML').Count -le 0) { Throw }
} Catch {
    Save-Module SelectHTML ${Env:TEMP} -RequiredVersion '1.0.1' -Force
    Import-Module "${Env:TEMP}\SelectHtml" -RequiredVersion '1.0.1' -Force
}
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