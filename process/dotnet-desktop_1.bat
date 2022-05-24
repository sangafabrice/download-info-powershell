@Echo OFF
(
    Echo [URL]
    Echo PageURL=https://dotnet.microsoft.com%~1
    Echo Selector=a[href$=win-x64.exe] attr{href}
) > "%~dp0dotnet-desktop_2.ini"
GetFrom-Link.bat dotnet-desktop_2 %~2 %~3