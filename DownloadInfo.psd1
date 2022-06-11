@{
RootModule = 'DownloadInfo.psm1'
ModuleVersion = '3.1.5'
GUID = '63f08017-49ae-4ae7-b7f1-76cf9366f8da'
Author = 'Fabrice Sanga'
CompanyName = 'sangafabrice'
Copyright = '(c) 2022 SangaFabrice. All rights reserved.'
Description = 'Download information relative to updating an application hosted on GitHub, Omaha and SourceForge.'
PowerShellVersion = '5.0'
PowerShellHostVersion = '5.0'
FunctionsToExport = 'Get-DownloadInfo'
CmdletsToExport = @()
AliasesToExport = @()
FileList = 'en-US\DownloadInfo-help.xml','DownloadInfo.psm1', 
               'DownloadInfo.psd1'
PrivateData = @{
    PSData = @{
        Tags = 'GitHub','Omaha','Sourceforge','DownloadInfo','Update'
        LicenseUri = 'https://github.com/sangafabrice/download-info/blob/main/LICENSE.md'
        ProjectUri = 'https://github.com/sangafabrice/download-info'
        IconUri = 'https://i.ibb.co/6wkd3Jy/shim-1.jpg'
        ReleaseNotes = 'Add ability to mock OS Architecture in Omaha request.'
    }
}
}
