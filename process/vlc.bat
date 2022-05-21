@Echo OFF
For /F "Tokens=2 Delims=-" %%V In ("%~nx1") Do Set %~2=%%~V