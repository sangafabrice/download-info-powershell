<#
    Configuration file --
    OSArch = 'x86'|'x64'
#>

Try {
    $UriBase = 'https://dist.torproject.org/torbrowser'
    (Invoke-WebRequest $UriBase -Verbose:$False).Links.href |
    Where-Object { $_ -match '(\d+\.)+\d+/$' } |
    Select-Object @{Name = 'Version'; Expression = { [version] ($_ -replace '/$') }},@{Name = 'Path'; Expression = { $_ }} |
    Select-Object @{
        Name = 'Link'
        Expression = {
            $UriBase = "$UriBase/$($_.Path)"
            $Culture = Get-Culture
            $Lang = $Culture.TwoLetterISOLanguageName
            $OSArch = $(Switch ($OSArch) { 'x64' { 'win64-' } 'x86' { '' } })
            $LangInstallers = (Invoke-WebRequest $UriBase -Verbose:$False).Links.href
            $GroupInstaller = $LangInstallers | Where-Object { $_ -like "torbrowser-install-$OSArch*_$Lang*.exe" }
            Switch ($GroupInstaller.Count) {
                0 { $GroupInstaller = $LangInstallers | Where-Object { $_ -like "torbrowser-install-$OSArch*_en-US.exe" } }
                { $_ -gt 1 } {
                    [void] ($Culture.Name -match '\-(?<Country>[A-Z]{2})$')
                    $TempLine = $GroupInstaller | Where-Object { $_ -like "torbrowser-install-$OSArch*_$Lang-$($Matches.Country).exe" }
                    If ([string]::IsNullOrEmpty($TempLine)) {
                        If ($Lang -ieq 'en') { $TempLine = $GroupInstaller | Where-Object { $_ -like "torbrowser-install-$OSArch*_en-US.exe" } }
                        Else { $TempLine = $GroupInstaller[0] }
                    }
                    $GroupInstaller = $TempLine
                }
            }
            Return "$UriBase$GroupInstaller"
        }
    } -First 1 | Select-Object Link,@{
        Name = 'Version'
        Expression = { ([uri] $_.Link).Segments?[-2] -replace '/$' }
    },@{
        Name = 'LastModified'
        Expression = { [datetime] "$((Invoke-WebRequest $_.Link -Method Head -Verbose:$False).Headers.'Last-Modified')" }
    }
}
Catch { }