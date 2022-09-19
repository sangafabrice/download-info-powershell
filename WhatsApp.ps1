<#
    Configuration file --
    OSArch = 'x86'|'x64'
#>

Try {
    [pscustomobject] @{
        Version = ("$(Invoke-WebRequest "https://web.whatsapp.com/check-update?version=0&platform=win$(Switch ($OSArch) { 'x64' { '64' } 'x86' { '32' } })")" | ConvertFrom-Json).currentVersion
        Link = "https://web.whatsapp.com/desktop/windows/release/$(Switch ($OSArch) { 'x64' { 'x64' } 'x86' { 'ia32' } })/WhatsAppSetup.exe"
    }
} Catch { }