@Echo OFF
(
    Echo [URL]
    Echo PageURL=https://dotnet.microsoft.com%~1
    Echo Selector=a[href$=win.exe] attr{href}
) > "%~dp0dotnet-asp_2.ini"
GetFrom-Link.bat dotnet-asp_2 %~2 %~3