<#
    Configuration file --
    OSArch = 'x86'|'x64'
#>

Try {
    (Invoke-WebRequest 'https://vivaldi.com/download/' -Verbose:$False).Links.href -like '*.exe' | 
    Select-Object @{
        Name = 'Version'
        Expression = {
            [void] ($_ -match "Vivaldi\.(?<Version>(\d+\.){3}\d+)$(If($OSArch -eq 'x64'){ '\.x64' })\.exe$")
            [version] $Matches.Version
        }
    },@{
        Name = 'Link'
        Expression = { $_ }
    } -Unique |
    Where-Object { ![string]::IsNullOrEmpty($_.Version) } |
    Sort-Object -Descending -Property Version |
    Select-Object -First 1
} Catch { }