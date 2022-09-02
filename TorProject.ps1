<#
    Configuration file --
    OSArch = 'x86'|'x64'
#>

Try {
    $UriBase = 'https://dist.torproject.org/torbrowser'
    (Invoke-WebRequest $UriBase -Verbose:$False).Links.href -match '(\d+\.)+\d+/$' |
    Select-Object @{
		Name = 'Version'
		Expression = { [version] ($_ -replace '/$') }
	},@{
		Name = 'Path'
		Expression = { $_ }
	} -First 1 |
    Select-Object Version,@{
        Name = 'Resource'
        Expression = {
            $Culture = Get-Culture
            $Lang = $Culture.TwoLetterISOLanguageName
            $UriBase = "$UriBase/$($_.Path)"
            $OSArch = $(Switch ($OSArch) { 'x64' { 'win64-' } 'x86' { '' } })
            $VersionString = "$($_.Version)"
            $LangInstallers = 
                "$(Invoke-WebRequest "$UriBase/sha256sums-signed-build.txt" -Verbose:$False)" -split "`n" |
                ForEach-Object {
                    ,@($_ -split ' ',2) |
                    ForEach-Object {
                        [pscustomobject] @{
                            Checksum = $_[0]
                            Link = "$($_[1])".Trim()
                        }
                    } |
                    Where-Object Link -Like "torbrowser-install-$OSArch${VersionString}_*.exe"
                }
            $GroupInstaller = $LangInstallers | Where-Object Link -Like "*_$Lang*.exe"
            Switch ($GroupInstaller.Count) {
                0 { $GroupInstaller = $LangInstallers | Where-Object Link -Like "*_en-US.exe" }
                { $_ -gt 1 } {
                    [void] ($Culture.Name -match '\-(?<Country>[A-Z]{2})$')
                    $TempLine = $GroupInstaller | Where-Object Link -Like "*_$Lang-$($Matches.Country).exe"
                    If ([string]::IsNullOrEmpty($TempLine)) {
                        If ($Lang -ieq 'en') { $TempLine = $GroupInstaller | Where-Object Link -Like "*_en-US.exe" }
                        Else { $TempLine = $GroupInstaller[0] }
                    }
                    $GroupInstaller = $TempLine
                }
            }
            $GroupInstaller.Link = "$UriBase$($GroupInstaller.Link)"
            $GroupInstaller
        }
    } |
    Select-Object Version -ExpandProperty Resource
}
Catch { }