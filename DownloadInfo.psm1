Function Get-DownloadInfo {
    Param (
        [Parameter(Mandatory=$true)]
        [Alias('Path')]
        [string] $ConfigPath,
        [ValidateSet('Github', 'Omaha', 'SourceForge')]
        [Alias('From')]
        [string] $ApiName = 'Github'
    )

    Get-Content $ConfigPath |
    ForEach-Object {
        ,($_ -split '=') |
        ForEach-Object {
            $Arguments = @{
                Name = $_[0].Trim();
                Value = ($_[1] -replace '"').Trim();
                ErrorAction = 'Ignore'
            }
            Set-Variable @Arguments
        }
    }

    Switch ($ApiName) {
        
        'GitHub' {
            $Arguments = @{
                UseBasicParsing = $true;
                Uri = "https://api.github.com/repos/$RepositoryId/releases/latest";
                ErrorAction = "Stop"
            }
            Try {
                (Invoke-WebRequest @Arguments).Content |
                Out-String | ConvertFrom-Json |
                Select-Object -Property @{
                    Name = 'Version';
                    Expression = { $_.tag_name }
                },@{
                    Name = 'Link';
                    Expression = {
                        $_.assets.browser_download_url |
                        ForEach-Object {
                            If ($_ -match $AssetPattern) { [uri] $_ }
                        }
                    }
                } -Unique
            }
            Catch {}
        }

        'Omaha' {
            $RequestBody = [xml] @'
<request
protocol="3.1"
updater="Omaha"
ismachine="1"
is_omaha64bit="0"
is_os64bit="1"
installsource="otherinstallcmd"
testsource="auto"
dedup="cr"
domainjoined="0">
    <os
    platform="win"
    version="10"
    sp=""
    arch="x64"/>
    <app
    appid=""
    version=""
    nextversion=""
    ap=""
    lang="en-US"
    brand=""
    client=""
    installage="-1"
    installdate="-1">
        <updatecheck />
    </app>
</request>
'@
            {
                Param ($Xpath, $Value)
                ($RequestBody.request | Select-Xml $Xpath).Node.Value = $Value
            } | ForEach-Object {
                & $_ '//@appid' $ApplicationID
                & $_ '//@brand' $OwnerBrand
            }
            $Arguments = @{
                UseBasicParsing = $true;
                Uri = $UpdateServiceURL;
                Method = 'POST';
                UserAgent = 'winhttp';
                Body = $RequestBody.OuterXml;
                ErrorAction = "Stop"
            }
            Try {
                (Invoke-WebRequest @Arguments).Content |
                Out-String |
                ForEach-Object {
                    $XmlResponse = ([xml] $_).response
                    {
                        Param ($Xpath)
                        ($XmlResponse | Select-Xml $Xpath).Node.Value |
                        Select-Object -Unique
                    }
                } | Select-Object -Property @{
                    Name = "Version";
                    Expression = {
                        & $_ '//@version'
                    }
                },@{
                    Name = "Link";
                    Expression = {
                        $SetupName = & $_ '//@name'
                        & $_ '//@codebase' | 
                        ForEach-Object { [uri] "$_$(If ($_[-1] -ne '/') {'/'})$SetupName" }
                    }
                }
            }
            Catch {}
        }
        
        'SourceForge' {
            Try {
                $Arguments = @{
                    UseBasicParsing = $true;
                    Uri = "https://sourceforge.net/projects/$RepositoryId/files/latest/download";
                    Method = 'HEAD';
                    UserAgent = 'curl';
                    MaximumRedirection = 1;
                    SkipHttpErrorCheck = $true;
                    ErrorAction = "Stop"
                }
                Invoke-WebRequest @Arguments |
                ForEach-Object {
                    If($_.StatusCode -eq 302) {
                        [uri] [string] $_.Headers.Location |
                        Select-Object -Property @{
                            Name = 'Version';
                            Expression = { 
                                $_.Segments[-(2 + ($PathFromVersion.Split('/', [System.StringSplitOptions]::RemoveEmptyEntries)).Length)] -replace '/'
                            }
                        },@{
                            Name = 'Link';
                            Expression = { $_ }
                        }
                    } Else { Throw }
                }
            }
            Catch {}
        }
    }
}

Export-ModuleMember -Function 'Get-DownloadInfo'