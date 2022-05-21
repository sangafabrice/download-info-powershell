@Echo OFF

SetLocal ENABLEDELAYEDEXPANSION
Set dump=%TEMP%\#%~n2
PushD "%~dp0"
Set "RedirectedURL=%~1"
Set "Output=%dump%"
Call Send-Request.bat urleffective.conf "--url --output" %2
PopD
Del /F /Q %dump%
EndLocal