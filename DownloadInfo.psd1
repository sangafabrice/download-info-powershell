@{
    RootModule = 'DownloadInfo.psm1'
    ModuleVersion = '2.0.0'
    GUID = '63f08017-49ae-4ae7-b7f1-76cf9366f8da'
    Author = 'Fabrice Sanga'
    CompanyName = 'sangafabrice'
    Copyright = '(c)2022 sangafabrice. All rights reserved.'
    Description = 'Handles the information relative to updating an application'
    PowerShellVersion = '7.0'
    PowerShellHostName = 'ConsoleHost'
    PowerShellHostVersion = '5.0'
    FunctionsToExport = @('Get-DownloadInfo')
    CmdletsToExport = @()
    VariablesToExport = ''
    AliasesToExport = @()
    FileList = @('en-US\DownloadInfo-help.xml', 'DownloadInfo.psm1', 'DownloadInfo.psd1')
    PrivateData = @{
        PSData = @{
            Tags = @('GitHub','Omaha', 'Sourceforge', 'DownloadInfo', 'Update')
            LicenseUri = 'https://github.com/sangafabrice/download-info/blob/main/LICENSE.md'
            ProjectUri = 'https://github.com/sangafabrice/download-info'
            IconUri = 'https://i.ibb.co/6wkd3Jy/shim-1.jpg'
            ReleaseNotes = 'Initial release of the module.'
        }
    }
}

