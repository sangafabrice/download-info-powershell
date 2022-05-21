@Echo OFF
For /F %%V In ('Call "%~dp0firefox-dev_getversion.bat" %~nx1') Do Set %~2=%%~V