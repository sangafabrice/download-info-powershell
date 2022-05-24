@Echo OFF
(
    Echo [URL]
    Echo PageURL=https://dotnet.microsoft.com%~1
    Echo Selector=a[href$=windows-x64-installer]
    Echo Selector1=a[href*=runtime-desktop] attr{href}
) > "%~dp0dotnet-desktop_1.ini"
GetFrom-Link.bat dotnet-desktop_1 %~2 %~3