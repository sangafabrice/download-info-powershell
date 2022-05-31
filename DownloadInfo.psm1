Function Get-DownloadInfo {
    [CmdletBinding(DefaultParameterSetName='UseFile')]
    Param (
        [Parameter(
            ParameterSetName='UseFile',
            Position=0,
            Mandatory=$true
        )]
        [Alias('Path')]
        [string] $ConfigPath,
        [Parameter(
            ParameterSetName='UseHashtable',
            Mandatory=$true
        )]
        [Alias('PropertyList')]
        [System.Collections.Hashtable] $ConfigHash,
        [ValidateSet('Github', 'Omaha', 'SourceForge')]
        [Alias('From')]
        [string] $ApiName = 'Github'
    )

    Switch ($PSCmdlet.ParameterSetName) {
        'UseHashtable' {
            $ConfigHash.Keys |
            ForEach-Object {
                $Arguments = @{
                    Name = $_;
                    Value = $ConfigHash[$_];
                    ErrorAction = 'Ignore'
                }
                Set-Variable @Arguments
            }
        }
        Default {
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
                        $_.assets |
                        ForEach-Object {
                            If ($_.browser_download_url -match $AssetPattern) { 
                                [PSCustomObject] @{
                                    Url = [uri] $_.browser_download_url;
                                    Size = $_.size
                                }
                            }
                        }
                    }
                } -Unique
            }
            Catch {}
        }
        'Omaha' {
            $RequestBody = [xml] @"
                <request
                protocol="3.1"
                updater="Omaha">
                    <os
                    platform="win"
                    version="$([Environment]::OSVersion.Version)"
                    arch="$([Environment]::Is64BitOperatingSystem ? 'x64':'x86')"/>
                    <app
                    appid=""
                    version=""
                    nextversion=""
                    ap="" 
                    lang="$((Get-WinSystemLocale).Name)"
                    brand="">
                        <updatecheck/>
                    </app>
                </request>
"@
            {
                Param ($Xpath, $Value)
                ($RequestBody.request | Select-Xml $Xpath).Node.Value = $Value
            } | ForEach-Object {
                & $_ '//@appid' $ApplicationID
                & $_ '//@brand' $OwnerBrand
                & $_ '//@ap' $ApplicationSpec
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
                    Expression = { & $_ '//@version' }
                },@{
                    Name = "Link";
                    Expression = {
                        $SetupName = & $_ '//@name'
                        & $_ '//@codebase' | 
                        ForEach-Object { [uri] "$_$(If ($_[-1] -ne '/') {'/'})$SetupName" }
                    }
                },@{
                    Name = "Checksum";
                    Expression = { (& $_ '//@hash_sha256').ToUpper() }
                },@{
                    Name = "Size";
                    Expression = { & $_ '//@size' }
                }
            }
            Catch {}
        } 
        'SourceForge' {
            $Arguments = @{
                UseBasicParsing = $true;
                Uri = "https://sourceforge.net/projects/$RepositoryId/files/latest/download";
                Method = 'HEAD';
                UserAgent = 'curl';
                MaximumRedirection = 1;
                SkipHttpErrorCheck = $true;
                ErrorAction = "Stop"
            }
            Try {
                Invoke-WebRequest @Arguments |
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
        }
    }
}

Export-ModuleMember -Function 'Get-DownloadInfo'