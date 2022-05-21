@Echo OFF
SetLocal ENABLEDELAYEDEXPANSION
Set link_path=%~1
Call :Get-TruncateLastIndex PathFromVersion
Echo !link_path:~0,%index%!
EndLocal
GoTo :EOF

:Get-TruncateLastIndex
: 1=: The string reference
: index:= The index to truncate the string from
    Set index=-1
    :Loop
    (
        Set %~1 && (
            Set "%~1=!%~1:~0,-1!"
            Set /A index-=1
            GoTo Loop
        )
    ) > Nul 2>&1