@Echo OFF
For /F "Tokens=3 Delims=-" %%V In ("%~n1") Do Set %~2=%%~V