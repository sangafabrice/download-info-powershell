$DevDependencies = @{
    Pester = '5.3.3';
    PlatyPS = '0.14.2';
    ExtensionsNuspec = [xml] @'
<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://schemas.microsoft.com/packaging/2015/06/nuspec.xsd">
<metadata>
    <id>download-info.extension</id>
    <version></version>
    <packageSourceUrl></packageSourceUrl>
    <owners>Fabrice Sanga</owners>
    <title></title>
    <authors>sangafabrice</authors>
    <projectUrl></projectUrl>
    <iconUrl></iconUrl>
    <copyright></copyright>
    <licenseUrl></licenseUrl>
    <requireLicenseAcceptance>true</requireLicenseAcceptance>
    <projectSourceUrl></projectSourceUrl>
    <docsUrl></docsUrl>
    <tags>download-info extension github omaha sourceforge</tags>
    <description></description>
    <releaseNotes></releaseNotes>
</metadata>
<files>
    <file src="extensions\**" target="extensions" />
</files>
</package>
'@;
    RemoteRepo = (git ls-remote --get-url) -replace '\.git$';
    Manifest = { Invoke-Expression "$(Get-Content "$PSScriptRoot\DownloadInfo.psd1" -Raw)" }
}

Filter New-DIManifest {
    <#
    .SYNOPSIS
        Create module manifest
    .NOTES
        Precondition:
        1. The current branch is main
        2. latest.json exists
    #>

    $GithubRepo = $DevDependencies.RemoteRepo
    $ModuleName = 'DownloadInfo'
    Push-Location $PSScriptRoot
    If ((git branch --show-current) -ne 'main') { Throw 'BranchNotMain' }
    Get-Content .\latest.json -Raw |
    ConvertFrom-Json |
    ForEach-Object {
        @{
            Path = "$ModuleName.psd1"
            RootModule = "$ModuleName.psm1"
            ModuleVersion = $_.version
            GUID = '63f08017-49ae-4ae7-b7f1-76cf9366f8da'
            Author = 'Fabrice Sanga'
            CompanyName = 'sangafabrice'
            Copyright = "(c) $((Get-Date).Year) SangaFabrice. All rights reserved."
            Description = 'Download information relative to updating an application hosted on GitHub, Omaha and SourceForge.'
            PowerShellVersion = '5.0'
            PowerShellHostVersion = '5.0'
            FunctionsToExport = @('Get-DownloadInfo')
            CmdletsToExport = @()
            VariablesToExport = @()
            AliasesToExport = @()
            FileList = @("en-US\$ModuleName-help.xml","$ModuleName.psm1","$ModuleName.psd1")
            Tags = @('GitHub','Omaha','Sourceforge','DownloadInfo','Update')
            LicenseUri = "$GithubRepo/blob/main/LICENSE.md"
            ProjectUri = $GithubRepo
            IconUri = 'https://i.ibb.co/6wkd3Jy/shim-1.jpg'
            ReleaseNotes = $_.releaseNotes -join "`n"
        }
    } | ForEach-Object {
        New-ModuleManifest @_
        (Get-Content $_.Path |
        Where-Object { $_ -match '.+' } |
        Where-Object { $_ -notmatch '^\s*#\.*' }) -replace ' # End of .+' -replace ", '",",'" |
        Out-File "$ModuleName.psd1"
    }
    Pop-Location
}

Filter New-DIMerge {
    <#
    .SYNOPSIS
        Merge pwsh-module into main
    .NOTES
        Precondition:
        1. The current branch is main
        2. Module files are modified in main
        3. The module manifest is modified
    .OUTPUTS
        Pester Test Details
    #>

    Param($CommitMessage)

    Push-Location $PSScriptRoot
    Try {
        If ((git branch --show-current) -ne 'main') { Throw 'BranchNotMain' }
        New-DIManifest
        $Manifest = & $DevDependencies.Manifest
        $FileList = $Manifest.FileList
        $ManifestFile = $FileList | Where-Object {$_ -like '*.psd1'}
        Test-ModuleManifest $ManifestFile
        If ($Null -eq $CommitMessage) {
            $CommitMessage = Switch ($Manifest.PrivateData.PSData.ReleaseNotes) {
                { ($_ -split "`n").Count -eq 1 } { "$_" }
                Default { "RELEASE: v$($Manifest.ModuleVersion)" }
            }
        }
        $GitDiffFiles = @(git diff --name-only --cached) + @(git diff --name-only)
        If ($GitDiffFiles.Count -eq 0) { Throw }
        ,($GitDiffFiles | Select-Object -Unique) |
        ForEach-Object {
            If ($_.Count -eq $_.Where({$_ -in $FileList}, 'Until').Count) { Throw 'ModuleFilesNotModified' }
            If ($Null -eq ($_ | Where-Object { $_ -eq $ManifestFile })) { Throw 'ModuleManifestNotModified' }
        }
        New-DITest
        Invoke-Expression "git add $($FileList) Readme.md"
        git commit --message "$CommitMessage" --quiet
        git stash push --include-untracked --quiet
        git switch pwsh-module --quiet 2> $Null
        If (!$?) {
            git stash pop --quiet > $Null 2>&1 
            Throw
        }
        git merge --no-commit main > $Null 2>&1 
        $IsMergeError = !$?
        $CDPattern = "$($PWD -replace '\\','\\')\\"
        Get-ChildItem -Recurse -File |
        Where-Object { ($_.FullName -replace $CDPattern) -inotin $FileList } |
        Remove-Item
        Get-ChildItem -Directory |
        Where-Object { ($_.FullName -replace $CDPattern) -inotin @($FileList |
            Where-Object { $_ -like '*\*' } |
            ForEach-Object { ($_ -split '\\')[0] }) } |
        Remove-Item -Recurse -Force
        If ($IsMergeError) {
            ,@(git diff --name-only) |
            ForEach-Object { If ($_ -in $FileList) { Throw 'MergeConflict' } }
            git add .
        }
        git commit --message "$CommitMessage" --quiet
        git switch main --quiet 2> $Null
        git stash pop --quiet > $Null 2>&1
    }
    Catch { "ERROR: $($_.Exception.Message)" }
    Pop-Location
}

Filter Invoke-OnModuleBranch {
    <#
    .SYNOPSIS
        Process a scriptblock on pwsh-module branch
    .NOTES
        Precondition:
        1. The current branch does not have unstaged changes.
        2. The script block does not modify pwsh-module
    #>

    Param([Parameter(Mandatory=$true)] $ScriptBlock)

    Get-Module DownloadInfo -ListAvailable |
    ForEach-Object {
        Push-Location $PSScriptRoot
        git branch --show-current |
        ForEach-Object {
            Try {
                git switch pwsh-module --quiet 2> $Null
                If (!$?) { Throw "StayOn_$_" }
                git switch $_ --quiet 2> $Null
                git stash push --include-untracked --quiet
                git switch pwsh-module --quiet
                & $ScriptBlock
            }
            Catch { "ERROR: $($_.Exception.Message)" }
            Finally {
                git switch $_ --quiet 2> $Null
                git stash pop --quiet > $Null 2>&1
            }
        }
        Pop-Location
    }
}

## TODO: Function must implement -WhatIf
Filter Publish-DIModule {
    <#
    .SYNOPSIS
        Publish module to PSGallery
    .NOTES
        Precondition:
        1. The current branch is pwsh-module
        2. The NUGET_API_KEY environment variable is set.
    #>

    Invoke-OnModuleBranch {
        If ((git branch --show-current) -ne 'pwsh-module') { Throw 'BranchNotPwshModule' }
        If ($null -eq $Env:NUGET_API_KEY) { Throw 'NUGET_API_KEY_IsNull' }
        @{
            Name = 'DownloadInfo';
            NuGetApiKey = $Env:NUGET_API_KEY;
        } | ForEach-Object { Publish-Module @_ }
        Write-Host "DownloadInfo@v$((& $DevDependencies.Manifest).ModuleVersion) published"
    }
}

## TODO: Function must implement -WhatIf
Filter Push-DIModule {
    <#
    .SYNOPSIS
        Push new module commit to GitHub
    .NOTES
        Precondition:
        1. The current branch is pwsh-module
    .OUTPUTS
        Push details
    #>

    Invoke-OnModuleBranch {
        If ((git branch --show-current) -ne 'pwsh-module') { Throw 'BranchNotPwhModule' }
        git push origin pwsh-module --force
        If (!$?) { Throw 'PushModuleToGitHubFailed' }
        "v$((& $DevDependencies.Manifest).ModuleVersion)" |
        ForEach-Object {
            If ($_ -inotin @(git tag --list)) {
                git tag $_
                git push --tags
            }
        }
    }
}

Filter New-DIChocoExtension {
    <#
    .SYNOPSIS
        Create a nuget package to be used as chocolatey extensions
    .NOTES
        Precondition:
        1. The current branch is main
        2. choco must be installed
    #>

    Push-Location $PSScriptRoot
    Try {
        If ((git branch --show-current) -ne 'main') { Throw 'BranchNotMain' }
        If ((where.exe choco.exe).Count -eq 0) { Throw 'ChocoNotFoundOnPath' }
        $Manifest = & $DevDependencies.Manifest
        $ModuleVersion = $Manifest.ModuleVersion
        $Nuspec = $DevDependencies.ExtensionsNuspec
        $ExtensionId = $Nuspec.package.metadata.id
        ${DIExtension\Extensions} = "$ExtensionId\extensions"
        $NuspecPath = "$("$ExtensionId\$ExtensionId").nuspec"
        $GithubRepo = $DevDependencies.RemoteRepo
        @{
            Path = ${DIExtension\Extensions};
            ItemType = 'Directory';
            ErrorAction = 'SilentlyContinue'
        } | ForEach-Object { New-Item @_ | Out-Null }
        @{
            Path = ".\$($Manifest.FileList | Where-Object {$_ -like '*.psm1'})";
            Destination = "${DIExtension\Extensions}\$($ExtensionId -replace '\.extension').psm1"
        } | ForEach-Object { Copy-Item @_ }
        $Nuspec.package.metadata |
        ForEach-Object {
            $_.version = $ModuleVersion
            $_.title = (Get-Culture).TextInfo.ToTitleCase($_.id) -replace '\-' -replace '\.',' '
            $_.copyright = $Manifest.Copyright
            $_.releaseNotes = $Manifest.PrivateData.PSData.ReleaseNotes
            $_.iconUrl = $Manifest.PrivateData.PSData.IconUri
            $_.projectUrl = $GithubRepo
            $_.licenseUrl = "$GithubRepo/blob/main/LICENSE.md"
            $_.docsUrl = "$GithubRepo/blob/main/Readme.md"
            $_.packageSourceUrl = "$GithubRepo/releases/download/v$ModuleVersion/$ExtensionId.$ModuleVersion.nupkg"
            $_.projectSourceUrl = "$GithubRepo/tree/pwsh-module"
            $_.description = $Manifest.Description
        }
        @{
            Path = $NuspecPath;
            Value = $Nuspec.OuterXml
        } | ForEach-Object { Set-Content @_ }
        choco pack $NuspecPath --outputdirectory . > $Null
        If (!$?) { Throw "ChocoExtensionCreationFailed" }
        Remove-Item $ExtensionId -Recurse -Force
        "$ExtensionId.$ModuleVersion.nupkg"
    }
    Catch { "ERROR: $($_.Exception.Message)" }
    Pop-Location
}

Filter Publish-DIChocoExtension {
    <#
    .SYNOPSIS
        Publish chocolatey extension to Community repository
    .NOTES
        Precondition:
        1. The current branch is main
        2. The CHOCO_API_KEY environment variable is set.
    #>

    Param([Parameter(Mandatory=$true)] $NugetPackage)

    Try {
        If ($null -eq $Env:CHOCO_API_KEY) { Throw 'CHOCO_API_KEY_IsNull' }
        If ((where.exe choco.exe).Count -eq 0) { Throw 'ChocoNotFoundOnPath' }
        choco apikey --key $Env:CHOCO_API_KEY --source https://push.chocolatey.org/
        If (!$?) { Throw }
        choco push $NugetPackage --source https://push.chocolatey.org/
        If (!$?) { Throw }
    }
    Catch { "ERROR: $($_.Exception.Message)" }
}

Filter New-DIRelease {
    <#
    .SYNOPSIS
        Create new module release on GitHub
    .NOTES
        Precondition:
        1. The current branch is main
        2. gh must be installed
        3. Module version tag is listed on Github
        4. The release tag is not listed on Github
    #>

    Param($Files)

    Push-Location $PSScriptRoot
    Try {
        If ((git branch --show-current) -ne 'main') { Throw 'BranchNotMain' }
        If ((where.exe gh.exe).Count -eq 0) { Throw 'GithubCliNotFoundOnPath' }
        $Manifest = & $DevDependencies.Manifest
        Switch ("v$($Manifest.ModuleVersion)") {
            {$_ -inotin @(git ls-remote --tags origin |
            ForEach-Object { ($_ -split '/')[-1] })} { Throw 'TagNotListedOnGithub' }
            {$_ -in @(gh release list |
            ConvertFrom-String | ForEach-Object { $_.P1 })} { Throw 'ReleaseTagExistsOnGitHub' }
            Default {
                gh release create $_ $Files --notes @"
- [x] $(((Get-Content .\Readme.md -TotalCount 2 |
Where-Object {$_ -like '*`[Test Coverage`]*'}) -split ' ',3)[2])
$($Manifest.PrivateData.PSData.ReleaseNotes -split "`n" |
ForEach-Object { "- [x] $_" } |
Out-String)
"@
            }
        }
    }
    Catch { "ERROR: $($_.Exception.Message)" }
    Pop-Location
}

Filter Deploy-DIModule {
    <#
    .SYNOPSIS
        Deploy module Everywhere
    #>

    Try {
        { If ((git branch --show-current) -ne 'main') { Throw 'BranchNotMain' } } |
        ForEach-Object {
            & $_
            New-DIMerge
            & $_
        }
        Push-DIModule
        New-DIChocoExtension |
        ForEach-Object {
            New-DIRelease $_
            Publish-DIChocoExtension $_
        }
        Publish-DIModule
    }
    Catch { "ERROR: $($_.Exception.Message)" }
}

Function Update-DIHelp {
    <#
    .SYNOPSIS
        Update Get-DownloadInfo help document
    .NOTES
        Precondition: PlatyPS is installed
    #>

    Begin {
        $PlatyPsModule = Get-Module | Where-Object Name -eq 'PlatyPS'
        Import-Module PlatyPS -RequiredVersion $DevDependencies.PlatyPS -Force
    }
    Process {
        Push-Location $PSScriptRoot
        New-ExternalHelp -Path .\en_us\ -OutputPath en-US -Force
        Pop-Location
    }
    End {
        Remove-Module PlatyPS -Force
        If ($PlatyPsModule.Count -gt 0) {
            Import-Module PlatyPS -RequiredVersion $PlatyPsModule.Version -Force
        }
    }
}

Function New-DITest {
    <#
    .SYNOPSIS
        Run a Pester test on Get-DownloadInfo function
    .NOTES
        Precondition: Pester v5.3.3 is installed
    #>

    Begin {
        $PesterModule = Get-Module | Where-Object Name -eq 'Pester'
        Import-Module Pester -RequiredVersion $DevDependencies.Pester -Force
    }
    Process {
        New-PesterConfiguration |
        ForEach-Object {
            $Manifest = & $DevDependencies.Manifest
            $CodeCoverageDoc = '.\DownloadInfo.Tests.xml'
            $PesterTest = '.\DownloadInfo.Tests.ps1'
            $Readme = '.\Readme.md'
            Push-Location $PSScriptRoot
            # [BUGFIX] Run test without configuration
            # Then run a second test with Pester configuration
            # TODO: Find a way to avoid this bugfix test
            . $PesterTest
            # Configure and run Pester test
            $_.CodeCoverage.Enabled = $true
            $_.CodeCoverage.CoveragePercentTarget = 95
            $_.CodeCoverage.OutputPath = $CodeCoverageDoc
            $_.Output.Verbosity = 'Detailed'
            $_.CodeCoverage.Path = ".\$($Manifest.FileList | Where-Object {$_ -like '*.psm1'})"
            $_.Run.Path = $PesterTest
            Invoke-Pester -Configuration $_
            # Document Module version and Code Coverage to Readme.md
            {
                Param($State)
                (Select-Xml $CodeCoverageDoc -XPath "/report/counter[@type = 'INSTRUCTION']/@$State").Node.Value |
                Select-Object -Unique
            } | ForEach-Object {
                $Covered = [int] (& $_ 'covered')
                $Coverage = 100 * ($Covered / ($Covered + (& $_ 'missed')))
                $BadgeColor = Switch ($Coverage) {
                    {$_ -gt 90 -and $_ -le 100} { 'green' }
                    {$_ -gt 75 -and $_ -le 90}  { 'yellow' }
                    {$_ -gt 60 -and $_ -le 75}  { 'orange' }
                    Default { 'red' }
                }
                ,@(Get-Content $Readme) |
                ForEach-Object { $_ | Select-Object -First ($_.Count -1) } |
                Out-String | ForEach-Object {
                    $_ -replace '!\[Module Version\].+\)', "![Module Version](https://img.shields.io/badge/version-v$($Manifest.ModuleVersion)-yellow) ![Test Coverage](https://img.shields.io/badge/coverage-$($Coverage.ToString('#.##'))%25-$BadgeColor)"
                } | Set-Content -Path $Readme
            }
            Remove-Item $CodeCoverageDoc
            Pop-Location
        }
    }
    End {
        Remove-Module Pester -Force
        If ($PesterModule.Count -gt 0) {
            Import-Module Pester -RequiredVersion $PesterModule.Version -Force
        }
    }
}

Filter Install-BuildDependencies {
    <#
    .SYNOPSIS
        Install build modules
    #>

    {
        Param(
            $Name,
            $PreInstall
        )
        If ((Get-Module $Name -ListAvailable |
        Where-Object Version -eq $DevDependencies[$Name]).Count -eq 0) {
            If ($Null -ne $PreInstall) { & $PreInstall }
            Install-Module $Name -RequiredVersion $DevDependencies[$Name] -Force
        }
    } | ForEach-Object {
        & $_ Pester {
            If ($PSVersionTable.PSVersion.Major -eq 5) {
                Install-PackageProvider Nuget -Force | Out-Null
                'PackageManagement','PowershellGet' |
                ForEach-Object { Import-Module $_ -RequiredVersion 1.0.0.1 -Force }
                @(
                    "${Env:ProgramFiles(x86)}\WindowsPowerShell\Modules\Pester\3.4.0"
                    "${Env:ProgramFiles}\WindowsPowerShell\Modules\Pester\3.4.0"
                ) | ForEach-Object {
                    $TakeOwn = {
                        Param($Path)
                        $FileAcl = Get-Acl $Path
                        $Identity = 'BUILTIN\Administrators'
                        $FileAcl.SetOwner([System.Security.Principal.NTAccount]::new($Identity))
                        $FileAcl.SetAccessRule([System.Security.AccessControl.FileSystemAccessRule]::new($Identity, 'FullControl', 'Allow'))
                        Set-Acl $Path -AclObject $FileAcl
                    }
                } {
                    If (Test-Path $_) {
                        Try {
                            & $TakeOwn $_
                            (Get-ChildItem $_ -Recurse).FullName |
                            ForEach-Object { & $TakeOwn $_ }
                            Remove-Item $_ -Recurse -Force
                        }
                        Catch { }
                    }
                }
            }
        }
        & $_ PlatyPS
    }
}

Filter New-DIJunction {
    <#
    .SYNOPSIS
        Create the DownloadInfo Junction in PSModulePath
    #>

    Param([switch] $Force)

    $FirstPath = "$(($env:PSModulePath -split ';')[0])\DownloadInfo"
    If (Test-Path $FirstPath) {
        If ($Force) {
            Remove-Item $FirstPath -Force
        } Else {
            Return 'DownloadInfo junction already exists'
        }
    }
    @{
        Path = $FirstPath;
        ItemType = 'Junction';
        Value = $PSScriptRoot
    } | ForEach-Object { New-Item @_ }
}