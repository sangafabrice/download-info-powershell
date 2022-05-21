@Echo OFF
For /F "Tokens=2 Delims=_" %%V In ("%~n1") Do Set %~2=%%~V