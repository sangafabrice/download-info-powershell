<#
    Configuration file --
#>

Try {
    ,$(
        Get-DownloadInfo -PropertyList @{
            RepositoryId = 'darktable-org/darktable'
            AssetPattern = 'win64\.exe$'
        }
    ) | ForEach-Object {
        @{
            Version = ($_ | Select-Object Version -Unique).Version
            Link = "$(,$_.Link -like '*.exe')"
        }
    } | ForEach-Object {
        $_.Checksum = ((((("$(Invoke-WebRequest $(
            [void] ($_.Link -match '(?<Path>https.*)/[^/]+')
            $Matches.Path -replace '/download/','/tag/'
        ))" -split '(<code>)|(</code>)') -like '$ sha256*') -split "`n") -like '*win64.exe')[-1] -split ' ')[0]
        [pscustomobject] $_
    }
} Catch { }