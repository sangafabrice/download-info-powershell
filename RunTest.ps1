Begin {
    $Private:PesterModule = Get-Module | Where-Object Name -eq 'Pester'
    Import-Module Pester -RequiredVersion 5.3.3 -Force
}

Process {
    New-PesterConfiguration |
    ForEach-Object {
        Push-Location $PSScriptRoot
        . .\DownloadInfo.Tests.ps1
        $_.CodeCoverage.Enabled = $true
        $_.CodeCoverage.CoveragePercentTarget = 95
        $_.CodeCoverage.OutputPath = '.\DownloadInfo.Test.xml'
        $_.Output.Verbosity = 'Detailed'
        $_.CodeCoverage.Path = '.\DownloadInfo.psm1'
        $_.Run.Path = '.\DownloadInfo.Tests.ps1'
        Invoke-Pester -Configuration $_
        {
            Param ($State)
            (Select-Xml .\DownloadInfo.Test.xml -XPath "/report/counter[@type = 'INSTRUCTION']/@$State").Node.Value |
            Select-Object -Unique
        } | ForEach-Object {
            $Private:Covered = [int] (& $_ 'covered')
            $Private:Coverage = 100 * ($Covered / ($Covered + (& $_ 'missed')))
            $Private:BadgeColor = Switch ($Coverage) {
                {$_ -gt 90 -and $_ -le 100} { 'green' }
                {$_ -gt 75 -and $_ -le 90}  { 'yellow' }
                {$_ -gt 60 -and $_ -le 75}  { 'orange' }
                Default { 'red' }
            }
            $Private:Readme = '.\Readme.md'
            Get-Content $Readme -Raw |
            Out-String | ForEach-Object {
                $_ -replace '!\[Test Coverage\].+\)', "![Test Coverage](https://img.shields.io/badge/coverage-$($Coverage.ToString('#.##'))%25-$BadgeColor)"
            } | Set-Content -Path $Readme
        }
        Remove-Item .\DownloadInfo.Test.xml
        Pop-Location
    }
}

End {
    Remove-Module Pester -Force
    If ($PesterModule.Count -gt 0) {
        Import-Module Pester -RequiredVersion $PesterModule.Version -Force
    }
}