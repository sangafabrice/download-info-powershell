@Echo OFF
For /F "Tokens=2 Delims=V" %%V In ("%~1") Do (
    Set %~2=%%~V
    Set %~3=https://wdl1.pcfg.cache.wpscdn.com/wpsdl/wpsoffice/download/%%~V/500.1001/WPSOffice_%%~V.exe
)
