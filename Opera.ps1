<#
    Configuration file --
    RepositoryID = 'repository_id'
    OSArch = 'x86'|'x64'
    FormatedName = 'formatted_name'
#>

Try {
    $UriBase = "https://get.geo.opera.com/pub/$RepositoryID/"
    (Invoke-WebRequest $UriBase -Verbose:$False).Links.href -notlike '../' |
    ForEach-Object { [version]($_ -replace '/') } |
    Sort-Object -Descending -Unique |
    Select-Object @{
        Name = 'Version'
        Expression = { "$_" }
    },@{
        Name = 'Link'
        Expression = { "$UriBase$_/win/${FormatedName}_$($_)_Setup$(If($OSArch -eq 'x64'){ '_x64' }).exe" }
    } -First 1 |
    Select-Object Version,Link,@{
        Name = 'Checksum';
        Expression = { "$(Invoke-WebRequest "$($_.Link).sha256sum" -Verbose:$False)" }
    }
} Catch { }