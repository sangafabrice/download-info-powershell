Get-Module DownloadInfo -ListAvailable |
ForEach-Object {
    Push-Location $PSScriptRoot
    (git branch |
    ConvertFrom-String |
    Where-Object P1 -eq *).P2 |
    ForEach-Object {
        Try {
            git switch pwsh-module --quiet 2> $Null
            If (!$?) { Throw }
            git switch $_ --quiet 2> $Null
            git stash push --include-untracked --quiet
            git switch pwsh-module --quiet
            # Publish-Module -Name DownloadInfo -NuGetApiKey $Env:NUGET_API_KEY
            Start-Sleep -Seconds 10
            git switch $_ --quiet 2> $Null
            git stash pop 'stash@{0}' --quiet > $Null 2>&1
        }
        Catch { "ERROR: $($_.Exception.Message)" }
    }
    Pop-Location
}