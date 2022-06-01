@{
    RootModule = '.\DownloadInfo.psm1'
    ModuleVersion = '2.0.0'
    GUID = 'ecfd0286-cadf-4e46-b389-f76977c4d0de'
    Author = 'Fabrice Sanga'
    CompanyName = 'sangafabrice'
    Copyright = '(c) sangafabrice. All rights reserved.'
    Description = 'Handles the information relative to updating an application'
    PowerShellVersion = '7.0.0'
    PowerShellHostVersion = '7.0.0'
    FunctionsToExport = @('Get-DownloadInfo')
    CmdletsToExport = @()
    VariablesToExport = ''
    AliasesToExport = @()
    FileList = @('.\en-US\DownloadInfo-help.xml')
    PrivateData = @{
        PSData = @{
            Tags = @('GitHub','Omaha', 'Sourceforge', 'DownloadInfo', 'Update')
            LicenseUri = 'https://github.com/sangafabrice/download-info/blob/LICENSE.md'
            ProjectUri = 'https://github.com/sangafabrice/download-info'
            IconUri = 'https://i.ibb.co/6wkd3Jy/shim-1.jpg'
            ReleaseNotes = 'Initial release of the module.'
        } 
    }
}

