[CmdletBinding()]
Param (
    [string] $__CommonPath = "$PSScriptRoot\common",
    [string] $__CommonUrl = 'https://api.github.com/repos/sangafabrice/download-info/git/trees/common'
)

New-Item -Path $__CommonPath -ItemType Directory -ErrorAction SilentlyContinue
$__GetCommonApis = {
    $Script:__CommonApis = $(
        Try {
            (
                (Invoke-WebRequest $__CommonUrl).Content |
                ConvertFrom-Json
            ).tree.path | ForEach-Object { $_ -replace '\.ps1$' }   
        }
        Catch { }
    )
    Return $__CommonApis
}

Class FromServer : System.Management.Automation.IValidateSetValuesGenerator {
    [string[]] GetValidValues() {
        Return [string[]] $(
            $Script:__CommonApis ?? (& $Script:__GetCommonApis) ??
            (Get-ChildItem $Script:__CommonPath -ErrorAction SilentlyContinue).Name
        )
    }
}

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
        [ValidateSet([FromServer])]
        [string] $From = 'Github'
    )

    Begin {
        Switch ($PSCmdlet.ParameterSetName) {
            'UseHashtable' {
                $PropertyList.Keys |
                ForEach-Object { Set-Variable $_ -Value $PropertyList[$_] }
            }
            Default {
                Get-Content $Path |
                ForEach-Object {
                    ,($_ -split '=') |
                    ForEach-Object { Set-Variable $_[0].Trim() -Value ($_[1] -replace '"').Trim() }
                }
            }
        }
    }

    Process {
        $__CommonScriptPath = "$($Script:__CommonPath)\$From"
        Try {
            $__RequestArguments = @{
                Uri = "https://github.com/sangafabrice/download-info/raw/common/$(
                    ((Invoke-WebRequest 'https://api.github.com/repos/sangafabrice/download-info/git/trees/common').Content |
                    ConvertFrom-Json).tree.path.Where({ $_ -ieq "$From.ps1" })
                )"
                Method = 'HEAD'
                Verbose = $False
            }
            $__ReplacePattern = '"|\s|#'
            $__CommonScriptEtag = (Invoke-WebRequest @__RequestArguments).Headers.ETag -replace $__ReplacePattern
            $__LocalCommonScriptEtag = (Get-Content $__CommonScriptPath -Tail 1 -ErrorAction SilentlyContinue) -replace $__ReplacePattern
            If ($__LocalCommonScriptEtag -ieq $__CommonScriptEtag) { Throw }
            $__RequestArguments.Method = 'GET'
            $__CommonScript = "$(Invoke-WebRequest @__RequestArguments)"
            Set-Content $__CommonScriptPath -Value $__CommonScript
            Add-Content $__CommonScriptPath -Value "# $__CommonScriptEtag"
        }
        Catch {
            $ErrorActionPreference = 'SilentlyContinue'
            $__CommonScript = (Get-Content $__CommonScriptPath -Raw)?.Substring(0,(Get-Item $__CommonScriptPath).Length - 68)
        }
        Finally {
            $__CommonScript.Where({ $_ }) |
            ForEach-Object { Invoke-Expression $_ -ErrorAction SilentlyContinue }
        }
    }

    End { }
}

Export-ModuleMember -Function 'Get-DownloadInfo'