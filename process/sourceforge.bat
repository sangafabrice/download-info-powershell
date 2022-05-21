@Echo OFF
For /F "Tokens=*" %%V In ('Call "%~dp0sourceforge_truncate.bat" %~p1') Do Set "%~2=%%~nxV"