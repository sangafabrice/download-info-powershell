@Echo OFF
For /F %%V In ('Call "%~dp0curl_truncate.bat" %~p1') Do Set %~2=%%~nxV