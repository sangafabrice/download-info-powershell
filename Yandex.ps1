<#
    Configuration file --
    OSArch = 'x86'|'x64'
#>

Try {
    $OSArch = Switch ($OSArch) { 'x64' { '64' } 'x86' { '32' } }
    Do {
        $Url = $(
            @{
                Uri = "https://browser.yandex.com/download?bitness=$OSArch"
                Method = 'HEAD'
                MaximumRedirection = 0
                SkipHttpErrorCheck = $True
                ErrorAction = 'SilentlyContinue'
            } | ForEach-Object { [uri] (Invoke-WebRequest @_).Headers.Location[0] }
        )
    } 
    While ($Url.Segments[-1] -notlike 'Yandex.exe')
    [void] ($Url.LocalPath -match '(?<Version>(\d+_){4}\d+)')
    $Version = ($Matches.Version -split '_')[0..3] -join '.'
    [pscustomobject] @{
        Version = [version] $Version
        Resource = $(
            "https://api.browser.yandex.ru/update-info/browser/yandex/win-yandex.rss?version=$Version&manual=yes&uid=75C04F2E-8DB0-41B4-B728-79710A9EAE0D" |
            ForEach-Object { ([xml] "$(Invoke-WebRequest $_)").rss.channel.item } |
            Select-Object @{
                Name = 'Link'
                Expression = { $_."guid$OSArch" }
            },@{
                Name = 'Checksum'
                Expression = { $_."md5$OSArch" }
            }
        )
    } | Select-Object Version -ExpandProperty Resource
} Catch { $_ }