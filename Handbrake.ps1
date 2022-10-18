<#
    Configuration file --
#>
Try {
    $UpdateInfo =
        Get-DownloadInfo -PropertyList @{ 
            RepositoryId = 'HandBrake/HandBrake'
            AssetPattern = 'x86_64-Win_GUI\.exe$'
        }
    Add-Member -InputObject $UpdateInfo -MemberType NoteProperty -Name Checksum -Value "$(
        Try {
            Import-Module "${Env:TEMP}\SelectHtml" -RequiredVersion '1.0.1' -ErrorAction SilentlyContinue -Force
            If ((Get-Module | Where-Object Name -Like 'SelectHTML').Count -le 0) { Throw }
        } Catch {
            Save-Module SelectHTML ${Env:TEMP} -RequiredVersion '1.0.1' -Force
            Import-Module "${Env:TEMP}\SelectHtml" -RequiredVersion '1.0.1' -Force
        }
        (
            Select-Html '//tr' -Uri 'https://handbrake.fr/checksums.php' |
            Where-Object { $_ -like "$(([uri] $UpdateInfo.Link).Segments[-1])*" }
        ).Split(' ', [StringSplitOptions]::RemoveEmptyEntries)[-1].Trim()
    )" -Passthru |
    Select-Object -ExcludeProperty Size
} Catch { }