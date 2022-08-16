<#
    Configuration file --
    RepositoryId = "repository_id"
    PathFromVersion = "relative_path_from_version"
#>

Try {
    @{
        Uri = "https://sourceforge.net/projects/$RepositoryId/files/latest/download";
        Method = 'HEAD';
        UserAgent = 'curl';
        MaximumRedirection = 0;
        ErrorAction = 'SilentlyContinue';
        SkipHttpErrorCheck = $true;
    } | ForEach-Object { Invoke-WebRequest @_ } | 
    ForEach-Object {
        If($_.StatusCode -eq 302) {
            [uri] [string] $_.Headers.Location |
            Select-Object -Property @{
                Name = 'Version';
                Expression = { 
                    $_.Segments[-(2 + ($PathFromVersion.Split('/', [StringSplitOptions]::RemoveEmptyEntries)).Length)] -replace '/'
                }
            },@{
                Name = 'Link';
                Expression = { $_ }
            }
        } Else { Throw }
    }
}
Catch {}