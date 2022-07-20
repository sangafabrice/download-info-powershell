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
        [ValidateSet('Blisk', 'Github', 'Mozilla', 'MSEdge', 'Omaha', 'Opera', 'SourceForge', 'Vivaldi')]
        [string] $From = 'Github'
    )

    Begin {
        Switch ($PSCmdlet.ParameterSetName) {
            <#
                Initialize configuration variables
            #>

            'UseHashtable' {
                $PropertyList.Keys |
                ForEach-Object { @{
                    Name = $_;
                    Value = $PropertyList[$_];
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
                    protocol="$(Switch ($Protocol) {
                        { ![string]::IsNullOrEmpty($_) } { $_ }
                        Default { '3.1' }
                    })"
                    updater="Omaha"
                    updaterversion="0"
                    shell_version="0"
                    ismachine="1"
                    sessionid="{00000000-0000-0000-0000-000000000000}"
                    installsource="taggedmi"
                    testsource="auto"
                    requestid="{00000000-0000-0000-0000-000000000000}"
                    dedup="cr"
                    domainjoined="0">
                        <os
                        platform="win"
                        version="$([Environment]::OSVersion.Version)"
                        sp=""
                        arch="$(Switch ($OSArch) {
                            {$_ -in @('x86','x64')} { $_ }
                            Default { If ([Environment]::Is64BitOperatingSystem) { 'x64' } Else { 'x86' } }
                        })"/>
                        <app
                        appid=""
                        version=""
                        nextversion=""
                        ap="" 
                        lang="$((Get-Culture).Name)"
                        brand=""
                        client=""
                        installage="-1"
                        installdate="-1">
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
                        Body = $RequestBody.OuterXml
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
                        Name = 'Version';
                        Expression = { & $_ '//@version' }
                    },@{
                        Name = 'Link';
                        Expression = {
                            $SetupName = & $_ '//@name'
                            & $_ '//@codebase' | 
                            ForEach-Object { [uri] "$_$(If ($_[-1] -ne '/') {'/'})$SetupName" }
                        }
                    },@{
                        Name = 'Checksum';
                        Expression = { (& $_ '//@hash_sha256').ToUpper() }
                    },@{
                        Name = 'Size';
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
                        UserAgent = 'curl';
                        MaximumRedirection = 0;
                        ErrorAction = 'SilentlyContinue'
                    } + $(
                        Switch($PSVersionTable.PSVersion.Major) {
                            7 { @{ SkipHttpErrorCheck = $true; } }
                            Default { @{} }
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

            'Mozilla' {
                <#
                    Configuration file --
                    RepositoryId = 'repository_id'
                    OSArch = 'x86'|'x64'
                    VersionDelim = 'b'|'.'|$Null
                #>
                
                Try {
                    If ($VersionDelim -in '.','\.') { $VersionDelim = $Null }
                    $UriBase = "https://releases.mozilla.org/pub/$RepositoryId/releases/"
                    (Invoke-WebRequest $UriBase).Links.href |
                    ForEach-Object {
                        [void] ($_ -match "/(?<Version>[0-9\.$VersionDelim]+)/$")
                        Switch ($Matches.Version -replace 'b','.') { 
                            { ![string]::IsNullOrEmpty($_) } { 
                                [PSCustomObject] @{
                                    VersionString = $Matches.Version
                                    Version = [version] $_
                                }
                        } }
                    } |
                    Sort-Object -Descending -Property Version |
                    Select-Object @{
                        Name = 'Resource'
                        Expression = {
                            $Culture = Get-Culture
                            $Lang = $Culture.TwoLetterISOLanguageName
                            $VersionString = $_.VersionString
                            $UriBase = "$UriBase$VersionString"
                            $OSArch = $(Switch ($OSArch) { 'x64' { 'win64' } 'x86' { 'win32' } })
                            $LangInstallers = 
                                "$(Invoke-WebRequest "$UriBase/SHA512SUMS" -Verbose:$False)" -split "`n" |
                                ForEach-Object {
                                    ,@($_ -split ' ',2) |
                                    ForEach-Object {
                                        [pscustomobject] @{
                                            Checksum = $_[0]
                                            Link = "$($_[1])".Trim()
                                        }
                                    } |
                                    Where-Object Link -Like "$OSArch/*$VersionString.exe"
                                }
                            $GroupInstaller = $LangInstallers | Where-Object Link -Like "$OSArch/$Lang*.exe"
                            Switch ($GroupInstaller.Count) {
                                0 { $GroupInstaller = $LangInstallers | Where-Object Link -Like "$OSArch/en-US/*" }
                                { $_ -gt 1 } {
                                    [void] ($Culture.Name -match '\-(?<Country>[A-Z]{2})$')
                                    $TempLine = $GroupInstaller | Where-Object Link -Like "$OSArch/$Lang-$($Matches.Country)/*"
                                    If ([string]::IsNullOrEmpty($TempLine)) {
                                        If ($Lang -ieq 'en') { $TempLine = $GroupInstaller | Where-Object Link -Like "$OSArch/en-US/*" }
                                        Else { $TempLine = $GroupInstaller[0] }
                                    }
                                    $GroupInstaller = $TempLine
                                }
                            }
                            $GroupInstaller.Link = "$UriBase/$($GroupInstaller.Link)"
                            $GroupInstaller
                        } 
                    },@{
                        Name = 'Version'
                        Expression = { $_.VersionString }
                    } -First 1 |
                    Select-Object Version -ExpandProperty Resource
                } Catch { }
            }

            'Blisk' {
                <#
                    Configuration file --
                #>
                
                Try {
                    @{
                        Uri = 'https://blisk.io/download/?os=win'
                        UserAgent = 'NSISDL/1.2 (Mozilla)'
                        MaximumRedirection = 0
                        SkipHttpErrorCheck = $True
                        ErrorAction = 'SilentlyContinue'
                        Verbose = $False
                    } | ForEach-Object { (Invoke-WebRequest @_).Headers.Location } |
                    Select-Object @{
                        Name = 'Version'
                        Expression = {
                            [void] ($_ -match "BliskInstaller_(?<Version>(\d+\.){3}\d+)\.exe$")
                            [version] $Matches.Version
                        }
                    },@{
                        Name = 'Link'
                        Expression = { $_ }
                    } -Unique |
                    Where-Object { ![string]::IsNullOrEmpty($_.Version) } |
                    Sort-Object -Descending -Property Version |
                    Select-Object -First 1
                } Catch { }
            }

            'MSEdge' {
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
            }

            'Vivaldi' {
                <#
                    Configuration file --
                    OSArch = 'x86'|'x64'
                #>
                
                Try {
                    (Invoke-WebRequest 'https://vivaldi.com/download/' -Verbose:$False).Links.href -like '*.exe' | 
                    Select-Object @{
                        Name = 'Version'
                        Expression = {
                            [void] ($_ -match "Vivaldi\.(?<Version>(\d+\.){3}\d+)$(If($OSArch -eq 'x64'){ '\.x64' })\.exe$")
                            [version] $Matches.Version
                        }
                    },@{
                        Name = 'Link'
                        Expression = { $_ }
                    } -Unique |
                    Where-Object { ![string]::IsNullOrEmpty($_.Version) } |
                    Sort-Object -Descending -Property Version |
                    Select-Object -First 1
                } Catch { }
            }

            'Opera' {
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
            }
        }
    }
}

Export-ModuleMember -Function 'Get-DownloadInfo'