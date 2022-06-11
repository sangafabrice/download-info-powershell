<#
.SYNOPSIS
    Tests Get-DownloadInfo function from DownloadInfo Module
.DESCRIPTION
    The script tests the 3 phases of the function Get-DownloadInfo
    Phase 1:
    The configuration variables are set from either a file or a hashtable.
    The function uses Set-Variable to convert from file/hashtable to variables.
    The context 'Test property list inputs' implements tests that ensure
    the Set-Variable inputs are all correct.
    Phase 2:
    Send HTTP request with Invoke-WebRequest. It is important to make sure that
    the correct endpoints and request body are set.
    The context 'Test http request arguments' implements tests that ensure the
    Invoke-WebRequest arguments are all correct.
    Phase 3:
    Parse the response and return the Update Information properties.
#>

Begin {
    $Private:DownloadInfoModule = Get-Module | Where-Object Name -eq 'DownloadInfo'
    Import-Module $PSScriptRoot\DownloadInfo.psm1 -Force
}

Process {
    Describe 'Test Get-DownloadInfo Components' {

        InModuleScope DownloadInfo {

            BeforeAll {
                $TestPptyList = @{
                    UpdateServiceURL = 'Update Service URL';
                    ApplicationID = 'ApplicationID';
                    OwnerBrand = 'Owner Brand';
                    ApplicationSpec = 'ApplicationSpec'
                }
                Mock 'Invoke-WebRequest' { }
            }

            Context 'Property list inputs' {
                <#
                    Tests Set-Variable -Name and -Value parameters
                    and that it is called the correct number of times.
                #>

                BeforeAll { Mock 'Set-Variable' { } }

                BeforeEach {
                    $TestPath = 'TestDrive:\test.toml'
                    $TestKey = 'UpdateURL'
                }

                Context 'Use hashtable parameter set' {

                    It 'Test conversion from hash key to variable' -TestCases @(
                        @{ PropertyList = @{ 
                            RepositoryId = ''
                            AssetPattern = '' 
                        } }
                        @{ PropertyList = @{
                            UpdateServiceURL = ''
                            ApplicationID = ''
                            OwnerBrand = ''
                            ApplicationSpec = ''
                        } }
                        @{ PropertyList = @{
                            RepositoryId = ''
                            PathFromVersion = ''
                        } }
                    ) {

                        Param($PropertyList)

                        Get-DownloadInfo -PropertyList $PropertyList
                        $PLKeys = $PropertyList.Keys
                        Should -Invoke 'Set-Variable' -ParameterFilter { $Name -in $PLKeys } -Times $PLKeys.Count -Exactly
                        Should -Not -Invoke 'Set-Variable' -ParameterFilter { ! $Name -in $PLKeys }
                    }
        
                    It 'Test conversion from hash value to variable value' -TestCases @(
                        @{ PropertyList = @{ RepositoryId = 'RepositoryId' } }
                        @{ PropertyList = @{ OwnerBrand = 2101 } }
                        @{ PropertyList = @{ PathFromVersion = '' } }
                    ) {

                        Param($PropertyList)

                        Get-DownloadInfo -PropertyList $PropertyList
                        Should -Invoke 'Set-Variable' -ParameterFilter {
                            $Name -eq $($PropertyList.Keys)
                            $Value -eq $($PropertyList.Values)
                        } -Times 1 -Exactly
                        Should -Not -Invoke 'Set-Variable' -ParameterFilter {
                            $Name -ne $($PropertyList.Keys) -or $Value -ne $($PropertyList.Values)
                        }
                    }
                }

                Context 'Use file parameter set' {

                    It 'Test keys whitespace trimming' {

                        $PLKeys = $TestPptyList.Keys
                        Set-Content $TestPath -Value @"
$($($PLKeys)[0])="value0"
$($($PLKeys)[1])  ="value1"
    $($($PLKeys)[2])="value2"
    $($($PLKeys)[3])    ="value3"
"@
                        Get-DownloadInfo -Path $TestPath
                        Should -Invoke 'Set-Variable' -ParameterFilter { $Name -in $PLKeys } -Times 4 -Exactly
                    }
        
                    It 'Test values whitespace trimming' {

                        $PLValues = $TestPptyList.Values
                        Set-Content $TestPath -Value @"
Name0="$($($PLValues)[0])  "
Name1="$($($PLValues)[1])"     
Name2=    "$($($PLValues)[2])"
Name3=    "$($($PLValues)[3])"     
"@
                        Get-DownloadInfo -Path $TestPath
                        Should -Invoke 'Set-Variable' -ParameterFilter { $Value -in $PLValues } -Times 4 -Exactly
                    }
        
                    It 'Test both keys and values whitespace trimming' {

                        $TestValue = 'Update Service URL'
                        Set-Content $TestPath -Value "    $TestKey   =  `"$TestValue `"   "
                        Get-DownloadInfo -Path $TestPath
                        Should -Invoke 'Set-Variable' -ParameterFilter {
                            $Name -eq $TestKey -and $Value -eq $TestValue
                        }  -Times 1 -Exactly
                    }
        
                    It 'Test keys repetition' {

                        Set-Content $TestPath -Value @"
$TestKey="value0"
    $TestKey="value1"
        $TestKey    ="value0"
"@
                        Get-DownloadInfo -Path $TestPath
                        Should -Invoke 'Set-Variable' -ParameterFilter { $Name -eq $TestKey } -Times 3 -Exactly
                        Should -Invoke 'Set-Variable' -ParameterFilter { $Value -eq 'value0' } -Times 2 -Exactly
                        Should -Invoke 'Set-Variable' -ParameterFilter { $Value -eq 'value1' } -Times 1 -Exactly
                    }
                }
            }

            Context 'Http request arguments' {
                <#
                    Tests Invoke-WebRequest -Uri and -Body arguments.
                #>

                It 'Test Github latest release endpoint URI' -TestCases @(
                    @{ Repository = 'gohugoio/hugo' }
                    @{ Repository = 'cli/cli' }
                    @{ Repository = 'vercel/hyper' }
                    @{ Repository = 'notepad-plus-plus/notepad-plus-plus' }
                    @{ Repository = 'mjmlio/mjml-app' }
                ) {

                    Param($Repository)

                    Get-DownloadInfo -PropertyList @{ RepositoryId = $Repository }
                    Should -Invoke 'Invoke-WebRequest' -ParameterFilter {
                        $Uri -eq "https://api.github.com/repos/$Repository/releases/latest"
                    }
                }

                It 'Test SourceForge latest release endpoint URI' -TestCases @(
                    @{ Repository = 'sevenzip' }
                    @{ Repository = 'wampserver' }
                    @{ Repository = 'xmlstar' }
                ) {

                    Param($Repository)

                    Get-DownloadInfo -PropertyList @{ RepositoryId = $Repository } -From SourceForge
                    Should -Invoke 'Invoke-WebRequest' -ParameterFilter {
                        $Uri -eq "https://sourceforge.net/projects/$Repository/files/latest/download"
                    }
                }

                It 'Test Omaha request body and URI' -TestCases @(
                    @{ 
                        AppID='{8A69D345-D564-463c-AFF1-A69D9E530F96}'
                        Brand='GGLS'
                        Spec='stable-arch_x86-statsdef_1'
                    }
                    @{ 
                        AppID='{8A69D345-D564-463c-AFF1-A69D9E530F96}'
                        Brand='YTUH'
                        Spec='x64-stable-statsdef_1'
                    }
                    @{ 
                        AppID='{A8504530-742B-42BC-895D-2BAD6406F698}'
                        Brand='2101'
                    }
                    @{ 
                        AppID='{A8504530-742B-42BC-895D-2BAD6406F698}'
                        Brand='2101'
                        Arch='x86'
                    }
                ) {

                    Param(
                        $AppID,
                        $Brand,
                        $Spec,
                        $Arch
                    )

                    $ServiceUrl = 'service/update2'
                    Get-DownloadInfo -PropertyList @{
                        UpdateServiceURL = $ServiceUrl
                        ApplicationID = $AppID
                        OwnerBrand = $Brand
                        ApplicationSpec = $Spec
                        OSArch = $Arch
                    } -From Omaha
                    Should -Invoke 'Invoke-WebRequest' -ParameterFilter {
                        $Request = ([xml] $Body).request
                        ($Request | Select-Xml '//@appid').Node.Value -eq $AppID
                        ($Request | Select-Xml '//@brand').Node.Value -eq $Brand
                        ($Request | Select-Xml '//@ap').Node.Value -eq $Spec
                        If ($Null -ne $Arch) { ($Request | Select-Xml '//@arch').Node.Value -eq $Arch }
                        $Uri -eq $ServiceUrl
                    }
                }
            }

            Context 'Update information object' {
                <#
                    Test returned update information object
                    Mocked Invoke-WebRequest returns contents of
                    files located in .\http-response directory.
                #>

                BeforeAll { $TestHttpResponsePath = "$PSScriptRoot\http-response" }

                Context 'GitHub and Omaha case' {

                    BeforeEach {
                        Mock 'Invoke-WebRequest' { 
                            [PSCustomObject] @{
                                Content = Get-Content "$TestHttpResponsePath\$Content" -Raw
                            }
                        }
                    }

                    It 'GitHub update info object' -TestCases @(
                        @{ 
                            Content = 'atom.json'
                            Pattern = '\.exe$'
                            UpdateInfo = @{
                                Version = 'v1.60.0'
                                Link_0 = 'https://github.com/atom/atom/releases/download/v1.60.0/AtomSetup-x64.exe'
                                Link_Length = 2
                                Size = 198986592
                            }
                        }
                        @{ 
                            Content = 'atom.json'
                            Pattern = 'AtomSetup-x64\.exe$'
                            UpdateInfo = @{
                                Version = 'v1.60.0'
                                Link_0 = 'https://github.com/atom/atom/releases/download/v1.60.0/AtomSetup-x64.exe'
                                Link_Length = 1
                                Size = 198986592
                            }
                        }
                        @{ 
                            Content = 'ghcli.json'
                            Pattern = '\.zip$'
                            UpdateInfo = @{
                                Version = 'v2.11.3'
                                Link_0 = 'https://github.com/cli/cli/releases/download/v2.11.3/gh_2.11.3_windows_386.zip'
                                Link_Length = 2
                                Size = 7630834
                            }
                        }
                        @{ 
                            Content = 'hugo.json'
                            Pattern = '\.zip$'
                            UpdateInfo = @{
                                Version = 'v0.99.1'
                                Link_0 = 'https://github.com/gohugoio/hugo/releases/download/v0.99.1/hugo_0.99.1_Windows-32bit.zip'
                                Link_Length = 5
                                Size = 15687709
                            }
                        }
                        @{ 
                            Content = 'hugo.json'
                            Pattern = 'hugo_extended_.*_Windows-64bit\.zip$'
                            UpdateInfo = @{
                                Version = 'v0.99.1'
                                Link_0 = 'https://github.com/gohugoio/hugo/releases/download/v0.99.1/hugo_extended_0.99.1_Windows-64bit.zip'
                                Link_Length = 1
                                Size = 18560918
                            }
                        }
                    ) {

                        Param(
                            $Content,
                            $Pattern,
                            $UpdateInfo
                        )

                        $Info = Get-DownloadInfo -PropertyList @{ AssetPattern = $Pattern }
                        $Info.Version | Should -BeExactly $UpdateInfo.Version
                        $Info.Link[0].Size | Should -BeExactly $UpdateInfo.Size
                        $Info.Link.Length | Should -BeExactly $UpdateInfo.Link_Length
                        $Info.Link[0].Url | Should -BeExactly $UpdateInfo.Link_0
                    }

                    It 'Omaha update info object' -TestCases @(
                        @{ 
                            Content = 'chrome.xml'
                            UpdateInfo = @{
                                Version = '102.0.5005.63'
                                Link_0 = 'http://edgedl.me.gvt1.com/edgedl/release2/chrome/mqb6vsdr3sjna6t734prkfnc2i_102.0.5005.63/102.0.5005.63_chrome_installer.exe'
                                Link_Length = 8
                                Checksum = 'F6419BFDBD5DC67DAC5350683052C4EDABDFC8651DB69F1C4F27FA62D017D556'
                                Size = 81049248
                            }
                        }
                        @{ 
                            Content = 'chrome64.xml'
                            UpdateInfo = @{
                                Version = '102.0.5005.63'
                                Link_0 = 'http://edgedl.me.gvt1.com/edgedl/release2/chrome/ade5ivbjyqxhzr5n4rtzkimdjmpq_102.0.5005.63/102.0.5005.63_chrome_installer.exe'
                                Link_Length = 8
                                Checksum = 'BAB92549E4A2B09897206D2B115195FE8594757406FB573F4AB1B2C2C1E0FD12'
                                Size = 84243616
                            }
                        }
                        @{ 
                            Content = 'secure.xml'
                            UpdateInfo = @{
                                Version = '101.0.16440.68'
                                Link_0 = 'https://browser-update.avast.com/browser/win/x64/101.0.16440.68/AvastBrowserInstaller.exe'
                                Link_Length = 1
                                Checksum = '4BD6F4DF5B9776569225AD9EB5F929A459942EE08DB4AFB833A9F02F85CBD394'
                                Size = 95350968
                            }
                        }
                        @{ 
                            Content = 'secure32.xml'
                            UpdateInfo = @{
                                Version = '102.0.16815.63'
                                Link_0 = 'https://browser-update.avast.com/browser/win/x86/102.0.16815.63/AvastBrowserInstaller.exe'
                                Link_Length = 1
                                Checksum = '7EE73EF78AACDA80763A22B5FD552EDB17B9EDA58A83014072806DBD7290ACD1'
                                Size = 92392352
                            }
                        }
                    ) {

                        Param(
                            $Content,
                            $UpdateInfo
                        )

                        $Info = Get-DownloadInfo -PropertyList $TestPptyList -From Omaha
                        $Info.Version | Should -BeExactly $UpdateInfo.Version
                        $Info.Checksum | Should -BeExactly $UpdateInfo.Checksum
                        $Info.Size | Should -BeExactly $UpdateInfo.Size
                        $Info.Link.Length | Should -BeExactly $UpdateInfo.Link_Length
                        $Info.Link[0] | Should -BeExactly $UpdateInfo.Link_0
                    }
                }

                It 'Sourceforge update info object' -TestCases @(
                    @{
                        Content = 'sevenzip.xml'
                        PathFrom = ''
                        UpdateInfo = @{
                            Version = '21.07'
                            Link_0 = 'https://netix.dl.sourceforge.net/project/sevenzip/7-Zip/21.07/7z2107-x64.exe'
                        }
                    }
                    @{
                        Content = 'xmlstarlet.xml'
                        PathFrom = ''
                        UpdateInfo = @{
                            Version = '1.6.1'
                            Link_0 = 'https://netix.dl.sourceforge.net/project/xmlstar/xmlstarlet/1.6.1/xmlstarlet-1.6.1-win32.zip'
                        }
                    }
                    @{
                        Content = 'wampserver.xml'
                        PathFrom = 'Addons/Mysql/'
                        UpdateInfo = @{
                            Version = 'WampServer%203.0.0'
                            Link_0 = 'https://netix.dl.sourceforge.net/project/wampserver/WampServer%203/WampServer%203.0.0/Addons/MariaDB/wampserver3_x64_addon_mariadb10.2.44.exe'
                        }
                    }
                ) {

                    Param(
                        $Content,
                        $UpdateInfo,
                        $PathFrom
                    )

                    Mock 'Invoke-WebRequest' { Import-Clixml "$TestHttpResponsePath\$Content" }
                    $Info = Get-DownloadInfo -PropertyList @{ PathFromVersion = $PathFrom } -From SourceForge
                    $Info.Version | Should -BeExactly $UpdateInfo.Version
                    $Info.Link.AbsoluteUri | Should -BeExactly $UpdateInfo.Link_0
                }
            }
        }
    }
}

End {
    Remove-Module DownloadInfo -Force
    If ($DownloadInfoModule.Count -gt 0) {
        Get-Item $DownloadInfoModule.Path |
        ForEach-Object {
            $Private:ManifestPath = "$($_.DirectoryName)\$($_.BaseName).psd1"
            If (Test-Path $ManifestPath) {
                Import-Module $ManifestPath -Force
            } Else {
                Import-Module "$_" -Force
            }
        }
    }
}