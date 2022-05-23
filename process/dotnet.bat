@Echo OFF
(
    Echo [URL]
    Echo PageURL=https://dotnet.microsoft.com%~1
    Echo Selector=a[href$=windows-hosting-bundle-installer] attr{href}
) > "%~dp0dotnet_1.ini"
GetFrom-Link.bat dotnet_1 version %~3