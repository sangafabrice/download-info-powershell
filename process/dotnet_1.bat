@Echo OFF
(
    Echo [URL]
    Echo PageURL=https://dotnet.microsoft.com%~1
    Echo Selector=a[href$=win.exe] attr{href}
) > "%~dp0dotnet_2.ini"
GetFrom-Link.bat dotnet_2 %~2 %~3