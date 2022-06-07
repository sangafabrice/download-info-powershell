$DevDependencies = @{
    Pester = '5.3.3';
    PlatyPS = '0.14.2';
    Manifest = { Invoke-Expression "$(Get-Content .\DownloadInfo.psd1 -Raw)" }
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
    #>

    Param($CommitMessage)

    Push-Location $PSScriptRoot
    $Manifest = & $DevDependencies.Manifest
    $ManifestFile = $Manifest.FileList | Where-Object {$_ -like '*.psd1'}
    If ($Null -eq $CommitMessage) {
        $CommitMessage = Switch ($Manifest.PrivateData.PSData.ReleaseNotes) {
            { ($_ -split "`n").Count -eq 1 } { "$_" }
            Default { "RELEASE: v$($Manifest.ModuleVersion)" }
        }
    }
    Try {
        If ((git branch --show-current) -ne 'main') { Throw }
        ,(@(git diff --name-only --cached) + @(git diff --name-only) |
        Select-Object -Unique) |
        ForEach-Object {
            If ($_.Count -eq $_.Where({$_ -in $Manifest.FileList}, 'Until').Count) { Throw }
            If ($Null -eq ($_ | Where-Object { $_ -eq $ManifestFile })) { Throw }
        }
        New-DITest
        Invoke-Expression "git add $($Manifest.FileList) Readme.md"
        Invoke-Expression "git commit --message '$CommitMessage' --quiet"
        git stash push --include-untracked --quiet
        git switch pwsh-module --quiet 2> $Null
        If (!$?) {
            git stash pop --quiet > $Null 2>&1 
            Throw
        }
        git merge --no-commit main
        $IsMergeError = !$?
        $CDPattern = "$($PWD -replace '\\','\\')\\"
        Get-ChildItem -Recurse -File |
        Where-Object { ($_.FullName -replace $CDPattern) -inotin $Manifest.FileList } |
        Remove-Item
        Get-ChildItem -Directory |
        Where-Object { ($_.FullName -replace $CDPattern) -inotin @($Manifest.FileList |
            Where-Object { $_ -like '*\*' } |
            ForEach-Object { ($_ -split '\\')[0] }) } |
        Remove-Item -Recurse -Force
        If ($IsMergeError) { Throw 'MergeConflict' }
        Invoke-Expression "git commit --all --message '$CommitMessage' --quiet"
        git switch main --quiet 2> $Null
        git stash pop --quiet > $Null 2>&1
    }
    Catch {
        "ERROR: $($_.Exception.Message)"
    }
    Pop-Location
}

Filter Publish-DIModule {
    <#
    .SYNOPSIS
        Publish DownloadInfo module to PowerShell Gallery
    .NOTES
        Precondition:
        1. The current branch does not have unstaged changes.
        2. The NUGET_API_KEY environment variable is set.
    #>

    Get-Module DownloadInfo -ListAvailable |
    ForEach-Object {
        Push-Location $PSScriptRoot
        git branch --show-current |
        ForEach-Object {
            Try {
                If ($null -eq $Env:NUGET_API_KEY) { 
                    Throw 'The NUGET_API_KEY environment variable is not set.'
                }
                git switch pwsh-module --quiet 2> $Null
                If (!$?) { Throw }
                git switch $_ --quiet 2> $Null
                git stash push --include-untracked --quiet
                git switch pwsh-module --quiet
                Publish-Module -Name DownloadInfo -NuGetApiKey $Env:NUGET_API_KEY
                git switch $_ --quiet 2> $Null
                git stash pop --quiet > $Null 2>&1
            }
            Catch { "ERROR: $($_.Exception.Message)" }
        }
        Pop-Location
    }
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
                Get-Content $Readme -Raw |
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