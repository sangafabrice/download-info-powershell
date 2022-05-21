@Echo OFF
For /F "Tokens=1* Delims=." %%U In ("%~n1") Do Set %~2=%%~V