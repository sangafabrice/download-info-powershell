@Echo OFF
PushD "%~dp0"
:Loop
If Not ""=="%~2" (
    If EXIST "%~1.bat" ( Call %~1.bat %~2 ) Else %~1 %~2
    Shift /2
    GoTo Loop
)
PopD