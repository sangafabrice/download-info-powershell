$DevDependencies = @{
    Pester = '5.3.3';
    PlatyPS = '0.14.2';
    Manifest = { Invoke-Expression "$(Get-Content "$PSScriptRoot\DownloadInfo.psd1" -Raw)" }
}

Function New-DIMerge {
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
    $Manifest = & $DevDependencies.Manifest
    $FileList = $Manifest.FileList
    $ManifestFile = $FileList | Where-Object {$_ -like '*.psd1'}
    If ($Null -eq $CommitMessage) {
        $CommitMessage = Switch ($Manifest.PrivateData.PSData.ReleaseNotes) {
            { ($_ -split "`n").Count -eq 1 } { "$_" }
            Default { "RELEASE: v$($Manifest.ModuleVersion)" }
        }
    }
    Try {
        If ((git branch --show-current) -ne 'main') { Throw 'BranchNotMain' }
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
        If ((git branch --show-current) -ne 'pwsh-module') { Throw }
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

Function New-DIRelease {
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
                gh release create $_ --notes @"
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

    $CheckMain = { If ((git branch --show-current) -ne 'main') { Throw 'BranchNotMain' } }
    Try {
        & $CheckMain
        New-DIMerge
        & $CheckMain
        Push-DIModule
        New-DIRelease
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