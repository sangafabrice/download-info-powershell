<#
    Configuration file --
    OSArch = 'x86'|'x64'
#>

Try {
    $BaseUrl = [uri] 'https://inkscape.org/release/'
    $Url = Invoke-WebRequest $BaseUrl.AbsoluteUri -Method Head -MaximumRedirection 0 -SkipHttpErrorCheck -ErrorAction SilentlyContinue
    $DownloadPage = Invoke-WebRequest "$($BaseUrl.AbsoluteUri -replace '/release/',$Url.Headers.Location)windows/$(Switch($OSArch){'x64'{'64'}'x86'{'32'}})-bit/exe/dl/"
    $Culture = Get-Culture | Select-Object Name,TwoLetterISOLanguageName
    If ($Culture.TwoLetterISOLanguageName -ne 'en') {
        $LinkTagPattern = '(?<Language><link .*hreflang="{0}".*>)'
        If ("$DownloadPage" -match ($LinkTagPattern -f $Culture.Name)) { } ElseIf ("$DownloadPage" -match ($LinkTagPattern -f $Culture.TwoLetterISOLanguageName)) { }
        $DownloadPage = Invoke-WebRequest ($BaseUrl.AbsoluteUri -replace '/release/',([xml] ($Matches.Language -replace '([^/])>$','$1/>')).link.href)
    }
    [pscustomobject] @{
        Version = (($Url.Headers.Location -replace '(^/)|(/$)' -split '/')[-1] -split '-')[-1]
        Link = $(
            [void] ("$DownloadPage" -match '(?<Meta><meta .*http-equiv="Refresh".*>)')
            $BaseUrl.AbsoluteUri -replace '/release/',(([xml] $Matches.Meta).meta.content -split '=')[-1]
        )
        Checksum = ("$(Invoke-WebRequest "$($DownloadPage.Links.href -like '*.sha256')")" -split ' ')[0]
    }
} Catch { }