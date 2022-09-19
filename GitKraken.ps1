<#
    Configuration file --
    OSArch = 'x86'|'x64'
#>

Try {
    [pscustomobject] @{
        Version = $(
            (Invoke-WebRequest -Uri 'https://help.gitkraken.com/gitkraken-client/current/').
            Links.href.Where({ $_ -like '#version-*' }, 'First') |
            ForEach-Object { ($_ -split '\-',2)?[-1] -replace '\-','.' }
        )
        Link = "https://release.gitkraken.com/win$(Switch ($OSArch) { 'x64' { '64' } 'x86' { '32' } })/GitKrakenSetup.exe"
    }
} Catch { }