@Echo OFF
For /F "Tokens=2 Delims=-" %%V In ("%~n1") Do Set %~2=%%~V