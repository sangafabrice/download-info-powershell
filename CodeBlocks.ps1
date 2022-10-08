<#
    Configuration file --
#>

Try {
    Get-DownloadInfo -PropertyList @{
        RepositoryId = 'codeblocks'
        PathFromVersion = 'Windows/'
    } -From SourceForge |
    Select-Object Version,Link,@{
        Name = 'Checksum'
        Expression = {
            $FileName = $_.Link.Segments[-1]
            @{
                Uri = "https://sourceforge.net/projects/codeblocks/files/Binaries/$($_.Version)/Windows/checkums.txt/download"
                Method = 'HEAD'
                UserAgent = 'curl'
                MaximumRedirection = 1
                ErrorAction = 'SilentlyContinue'
                SkipHttpErrorCheck = $True
            } | ForEach-Object {
                (
                    (
                        (
                            [char[]] $(
                                ForEach ($i in @(
                                    (Invoke-WebRequest "$((Invoke-WebRequest @_).Headers.Location)").Content |
                                    Select-Object -Skip 2
                                )) {
                                    $ForEach.Current
                                    [void] $ForEach.MoveNext()
                                }
                            )
                        ) -join '' -split "`n" |
                        ConvertFrom-String |
                        Where-Object P1 -In 'Filename','SHA-512' |
                        Select-Object P1,P3
                    ).Where({$_.P3 -like $FileName}, 'SkipUntil', 2) |
                    Select-Object P3 -Last 1
                ).P3
            }
        }
    },@{
        Name = 'Name'
        Expression = { $_.Link.Segments[-1] }
    }
}
Catch {}