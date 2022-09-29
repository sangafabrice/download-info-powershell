<#
    Configuration file --
    OSArch = 'x86'|'x64'
#>

Try {
    "https://t1.daumcdn.net/potplayer/PotPlayer/Version/Latest/PotPlayerSetup$(If($OSArch -eq 'x64'){ '64' }).exe" |
    Select-Object @{
        Name = 'LastModified'
        Expression = { [datetime] "$((Invoke-WebRequest $_ -Method Head -Verbose:$False).Headers.'Last-Modified')" }
    },@{
        Name = 'Link'
        Expression = { $_ }
    }
} Catch { }