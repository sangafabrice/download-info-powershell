@Echo OFF
(
    Echo [URL]
    Echo PageURL=https://dotnet.microsoft.com%~1
    Echo Selector=a[href$=win-x64.exe] attr{href}
) > "%~dp0dotnet_1.ini"
GetFrom-Link.bat dotnet_1 %~2 %~3