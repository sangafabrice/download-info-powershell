<#
    Configuration file --
    OSArch = 'x86'|'x64'
#>

Try {
    $UriBasis = "https://msedge.api.cdp.microsoft.com/api/v1.1/contents/Browser/namespaces/Default/names/msedge-stable-win-$OSArch/versions/"
    $WebRequestArgs = {
        Param($ActionString)
        Return @{
            Uri = "$UriBasis$ActionString"
            UserAgent = 'winhttp'
            Method = 'POST'
            Body = '{"targetingAttributes":{}}'
            Headers = @{ 'Content-Type' = 'application/json' }
            Verbose = $False
        }
    }
    & $WebRequestArgs 'latest?action=select' |
    ForEach-Object { 
        Invoke-WebRequest @_ |
        ConvertFrom-Json |
        ForEach-Object {
            $Version = $_.ContentId.Version
            & $WebRequestArgs "$Version/files?action=GenerateDownloadInfo" |
            ForEach-Object { 
                (Invoke-WebRequest @_).Content |
                ConvertFrom-Json |
                Select-Object @{
                    Name = 'Size'
                    Expression = { $_.SizeInBytes }
                },@{
                    Name = 'Version'
                    Expression = { $Version }
                },@{
                    Name = 'Name'
                    Expression = { $_.FileId }
                },@{
                    Name = 'Link'
                    Expression = { $_.Url }
                } |
                Sort-Object -Property Size -Descending |
                Select-Object Version,Link,Name -First 1
            }
        }
    }
} Catch { }