Class FromServer : System.Management.Automation.IValidateSetValuesGenerator {
    [string[]] GetValidValues() {
        Return [string[]] $(
            Try {
                (
                    (Invoke-WebRequest 'https://api.github.com/repos/sangafabrice/download-info/git/trees/common').Content |
                    ConvertFrom-Json
                ).tree.path | ForEach-Object { $_ -replace '\.ps1$' }   
            }
            Catch { (Get-ChildItem "$PSScriptRoot\common" -ErrorAction SilentlyContinue).Name ?? 'Github' }
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

    DynamicParam {
        If ('Github' -eq $PSBoundParameters.From) {
            $ParamName = 'Version'
            $AttributeCollection = [System.Collections.ObjectModel.Collection[System.Attribute]]::New()
            $AttributeCollection.Add([System.Management.Automation.ParameterAttribute] @{ Mandatory = $False })
            $ParamDictionary = [System.Management.Automation.RuntimeDefinedParameterDictionary]::New()
            $ParamDictionary.Add($ParamName,[System.Management.Automation.RuntimeDefinedParameter]::New($ParamName,[string],$AttributeCollection))
            $ParamDictionary
        }
    }

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
        $__CommonPath = "$PSScriptRoot\common"
        $__CommonScriptPath = "$__CommonPath\$From"
        New-Item -Path $__CommonPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
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