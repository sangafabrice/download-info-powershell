<#
    Configuration file --
    OSArch = 'x86'|'x64'
#>

Try {
    $MachineType = Switch ($OSArch) { 'x64' { '64' } 'x86' { '32' } }
    (
        Invoke-WebRequest 'https://dl.pstmn.io/api/version/' |
        ConvertFrom-Json
    ).Where({ $_.channel -ieq 'stable' }).assets.Where({
        $_.platform -like "windows_$MachineType" -and
        $_.filetype -like '.exe'
    }) | Select-Object @{
        Name = 'Resource'
        Expression = {
            [pscustomobject] @{
                Name = $_.name
                Checksum = $_.hash
            }
        }
    },@{
        Name = 'Version'
        Expression = { [version] $_.version }
    } | Sort-Object Version -Descending |
    Select-Object -First 1 |
    Select-Object Version,@{
        Name = 'Link'
        Expression = { "https://dl.pstmn.io/download/version/$($_.Version)/win$MachineType" }
    } -ExpandProperty Resource
}
Catch { }