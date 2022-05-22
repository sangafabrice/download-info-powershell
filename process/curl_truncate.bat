@Echo OFF
SetLocal ENABLEDELAYEDEXPANSION
Set version=%~f1
If "\"=="%version:~-1%" Set version=%version:~0,-1%
Echo %version:dl-=%
EndLocal