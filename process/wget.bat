@Echo OFF
For /F "Tokens=5 Delims=/" %%V In ("%~1") Do Set %~2=%%~V