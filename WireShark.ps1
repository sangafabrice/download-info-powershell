<#
    Configuration file --
    OSArch = 'x86'|'x64'
#>

Try {
    $BaseUrl = 'https://1.eu.dl.wireshark.org'
    $SetupPathUrl = "$BaseUrl/win$(Switch($OSArch){'x64'{'64'}'x86'{'32'}})"
    (Invoke-WebRequest $SetupPathUrl).Links.href | 
    ForEach-Object { 
        If ($_ -match '(?<Version>(\d+\.)+\d+)\.exe') {
            [pscustomobject] @{
                Version = [version] $Matches.Version
                Link = "$SetupPathUrl/$_"
                VersionString = $Matches.Version
                FileName = $_
            }
        }
    } | 
    Sort-Object Version -Descending -Unique -Top 1 |
    Select-Object Version,Link,@{
        Name = 'Checksum'
        Expression = {
            $FileName = $_.FileName
            (("$(Invoke-WebRequest "$BaseUrl/$((Invoke-WebRequest $BaseUrl).Links.href -like "*$($_.VersionString).txt" |
            Select-Object -First 1)")" -split "`n" |
            Where-Object { $_ -like "SHA256($FileName)*" }) -split '=')[-1]
        }
    } |
    ForEach-Object { $_.Checksum ? ${_}:($_ | Select-Object -ExcludeProperty Checksum) }
} Catch { }