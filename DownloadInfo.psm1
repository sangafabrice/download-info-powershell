Function Get-DownloadInfo {
    [CmdletBinding(DefaultParameterSetName='UseFile')]
    Param (
        [Parameter(
            ParameterSetName='UseFile',
            Position=0,
            Mandatory=$true
        )]
        [string] $Path,
        [Parameter(
            ParameterSetName='UseHashtable',
            Mandatory=$true
        )]
        [System.Collections.Hashtable] $PropertyList,
        [ValidateSet('Github', 'Omaha', 'SourceForge')]
        [string] $From = 'Github'
    )

    Begin {
        Switch ($PSCmdlet.ParameterSetName) {
            'UseHashtable' {
                $PropertyList.Keys |
                ForEach-Object { @{
                    Name = $_;
                    Value = $PropertyList[$_];
                    ErrorAction = 'Ignore'
                } } | 
                ForEach-Object { Set-Variable @_ }
            }
            Default {
                Get-Content $Path |
                ForEach-Object {
                    ,($_ -split '=') |
                    ForEach-Object { @{
                        Name = $_[0].Trim();
                        Value = ($_[1] -replace '"').Trim();
                        ErrorAction = 'Ignore'
                    } } | 
                    ForEach-Object { Set-Variable @_ }
                }
            }
        }
    }

    Process {
        Switch ($From) {
    
            'GitHub' {
                <#
                    Configuration file --
                    RepositoryId = "repository_id"
                    AssetPattern = "asset_pattern"
                #>
    
                Try {
                    ( @{
                        UseBasicParsing = $true;
                        Uri = "https://api.github.com/repos/$RepositoryId/releases/latest";
                        ErrorAction = 'Stop'
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
            }
    
            'Omaha' {
                <#
                    Configuration file --
                    UpdateServiceURL = "update_service_uerl"
                    ApplicationID = "application_guid"
                    OwnerBrand = "owner_brand_code"
                    ApplicationSpec = "application_spec"
                #>
    
                $RequestBody = [xml] @"
                    <request
                    protocol="3.1"
                    updater="Omaha">
                        <os
                        platform="win"
                        version="$([Environment]::OSVersion.Version)"
                        arch="$(If([Environment]::Is64BitOperatingSystem){'x64'}Else{'x86'})"/>
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
                Try {
                    ( @{
                        UseBasicParsing = $true;
                        Uri = $UpdateServiceURL;
                        Method = 'POST';
                        UserAgent = 'winhttp';
                        Body = $RequestBody.OuterXml;
                        ErrorAction = 'Stop'
                    } |
                    ForEach-Object { Invoke-WebRequest @_ } ).Content |
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
                <#
                    Configuration file --
                    RepositoryId = "repository_id"
                    PathFromVersion = "relative_path_from_version"
                #>
    
                Try {
                    @{
                        UseBasicParsing = $true;
                        Uri = "https://sourceforge.net/projects/$RepositoryId/files/latest/download";
                        Method = 'HEAD';
                        UserAgent = 'curl'
                    } + $(
                        Switch($PSVersionTable.PSVersion.Major) {
                            5 { @{
                                MaximumRedirection = 0;
                                ErrorAction = 'SilentlyContinue'
                            } }
                            7 { @{
                                MaximumRedirection = 1;
                                SkipHttpErrorCheck = $true;
                                ErrorAction = 'Stop'
                            } }
                        }
                    ) | 
                    ForEach-Object { Invoke-WebRequest @_ } | 
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
}

Export-ModuleMember -Function 'Get-DownloadInfo'