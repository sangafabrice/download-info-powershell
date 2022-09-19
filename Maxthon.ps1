<#
    Configuration file --
    OSArch = 'x86'|'x64'
#>

Try {
    @{
        Uri = "https://www.maxthon.com/mx6/formal-$(
            Switch ($OSArch) { 'x64' { '64' } 'x86' { '32' } }
        )/dl"
        Method  = 'HEAD'
        MaximumRedirection = 0
        SkipHttpErrorCheck = $True
        ErrorAction = 'SilentlyContinue'
        Verbose = $False
    } | ForEach-Object { (Invoke-WebRequest @_).Headers.Location?[0] } |
    Select-Object @{
        Name = 'Version'
        Expression = { (([uri] $_).Segments?[-1] -split '_')?[1] }
    },@{
        Name = 'Link'
        Expression = { $_ }
    }
} Catch { }