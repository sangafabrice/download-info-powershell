Begin {
    $Private:PlatyPsModule = Get-Module | Where-Object Name -eq 'PlatyPS'
    Import-Module PlatyPS -Force
}
Process {
    Set-Location $PSScriptRoot
    New-ExternalHelp -Path .\en_us\ -OutputPath en-US -Force
    Set-Location -
}
End {
    Remove-Module PlatyPS -Force
    If ($PlatyPsModule.Count -gt 0) {
        Import-Module PlatyPS -RequiredVersion $PlatyPsModule.Version -Force
    }
}