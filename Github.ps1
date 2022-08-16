<#
    Configuration file --
    RepositoryId = "repository_id"
    AssetPattern = "asset_pattern"
#>

Try {
    ( @{
        UseBasicParsing = $true;
        Uri = "https://api.github.com/repos/$RepositoryId/releases/latest"
    } |
    ForEach-Object { Invoke-WebRequest @_ } ).Content |
    Out-String | ConvertFrom-Json |
    Select-Object -Property @{
        Name = 'Version';
        Expression = { $_.tag_name }
    },@{
        Name = 'Link';
        Expression = {
            ,@($_.assets |
            ForEach-Object {
                If ($_.browser_download_url -match $AssetPattern) { 
                    [PSCustomObject] @{
                        Url = [uri] $_.browser_download_url;
                        Size = $_.size
                    }
                }
            }) | ForEach-Object {
                Add-Member -InputObject $_ -TypeName array -PassThru
            }
        }
    } -Unique
}
Catch {}