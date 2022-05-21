@Echo OFF

:Main
: Set and send requests using config files
: 1=:config_template_file
: 2=:arguments_which_values_are_to_replace
: 3:=request_file_output

SetLocal ENABLEDELAYEDEXPANSION
Set request=%~f3
Set req_template=%~f1
PushD "%~dp0"
Set req_argname="%~2"
Type Nul > %request% 
For /F "UseBackq Tokens=1*" %%C In ("%req_template%") Do (
    Set request_arg=
    Echo %%C| FindStr /B %req_argname:-=\-% > Nul && Call :Set-Request %%D
    If Not DEFINED request_arg Set request_arg=%%D
    Echo %%C !request_arg!>> %request%
)
..\Curl --config %request%
Del /F /Q %request%
PopD
EndLocal
GoTo :EOF

:Set-Request 
: 1=: Curl config arguments
    Set request_arg=%1
    Set data_ref=%~1
    Set data_ref=%data_ref:@=%
    Call Set request_arg=%%request_arg:%data_ref%=!%data_ref%:\=/!%%
    GoTo :EOF