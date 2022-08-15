<#
    Configuration file --
#>

Try {
    @{
        Uri = 'https://blisk.io/download/?os=win'
        UserAgent = 'NSISDL/1.2 (Mozilla)'
        MaximumRedirection = 0
        SkipHttpErrorCheck = $True
        ErrorAction = 'SilentlyContinue'
        Verbose = $False
    } | ForEach-Object { (Invoke-WebRequest @_).Headers.Location } |
    Select-Object @{
        Name = 'Version'
        Expression = {
            [void] ($_ -match "BliskInstaller_(?<Version>(\d+\.){3}\d+)\.exe$")
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