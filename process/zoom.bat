@Echo OFF
For /F %%V In ('Call "%~dp0zoom_truncate.bat" %~1') Do Set "%~2=%%~nxV"