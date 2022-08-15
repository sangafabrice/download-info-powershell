<#
    Configuration file --
    RepositoryId = 'repository_id'
    OSArch = 'x86'|'x64'
    VersionDelim = 'b'|'.'|$Null
#>

Try {
    If ($VersionDelim -in '.','\.') { $VersionDelim = $Null }
    $UriBase = "https://releases.mozilla.org/pub/$RepositoryId/releases/"
    (Invoke-WebRequest $UriBase).Links.href |
    ForEach-Object {
        [void] ($_ -match "/(?<Version>[0-9\.$VersionDelim]+)/$")
        Switch ($Matches.Version -replace 'b','.') { 
            { ![string]::IsNullOrEmpty($_) } { 
                [PSCustomObject] @{
                    VersionString = $Matches.Version
                    Version = [version] $_
                }
        } }
    } |
    Sort-Object -Descending -Property Version |
    Select-Object @{
        Name = 'Resource'
        Expression = {
            $Culture = Get-Culture
            $Lang = $Culture.TwoLetterISOLanguageName
            $VersionString = $_.VersionString
            $UriBase = "$UriBase$VersionString"
            $OSArch = $(Switch ($OSArch) { 'x64' { 'win64' } 'x86' { 'win32' } })
            $LangInstallers = 
                "$(Invoke-WebRequest "$UriBase/SHA512SUMS" -Verbose:$False)" -split "`n" |
                ForEach-Object {
                    ,@($_ -split ' ',2) |
                    ForEach-Object {
                        [pscustomobject] @{
                            Checksum = $_[0]
                            Link = "$($_[1])".Trim()
                        }
                    } |
                    Where-Object Link -Like "$OSArch/*$VersionString.exe"
                }
            $GroupInstaller = $LangInstallers | Where-Object Link -Like "$OSArch/$Lang*.exe"
            Switch ($GroupInstaller.Count) {
                0 { $GroupInstaller = $LangInstallers | Where-Object Link -Like "$OSArch/en-US/*" }
                { $_ -gt 1 } {
                    [void] ($Culture.Name -match '\-(?<Country>[A-Z]{2})$')
                    $TempLine = $GroupInstaller | Where-Object Link -Like "$OSArch/$Lang-$($Matches.Country)/*"
                    If ([string]::IsNullOrEmpty($TempLine)) {
                        If ($Lang -ieq 'en') { $TempLine = $GroupInstaller | Where-Object Link -Like "$OSArch/en-US/*" }
                        Else { $TempLine = $GroupInstaller[0] }
                    }
                    $GroupInstaller = $TempLine
                }
            }
            $GroupInstaller.Link = "$UriBase/$($GroupInstaller.Link)"
            $GroupInstaller
        } 
    },@{
        Name = 'Version'
        Expression = { $_.VersionString }
    } -First 1 |
    Select-Object Version -ExpandProperty Resource
} Catch { }