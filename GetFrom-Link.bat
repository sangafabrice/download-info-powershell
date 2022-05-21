@Echo OFF

:Main
: [2:=] Version reference of the application
: [3:=] Absolute URL reference of the setup

: -----------------------------------------------
: Optional parser: it does not work when URLs
: have special characters like %20 that is
: whitespace encoded
If Not ""=="%~2%~3" (
    For /F "Tokens=1* Delims==" %%U In ('Call "%~f0" %1') Do (
        If "version"=="%%U" If Not ""=="%~2" ( Set "%~2=%%V" ) Else Echo %%U=%%V
        If "link"=="%%U" If Not ""=="%~3" ( Set "%~3=%%V" ) Else Echo %%U=%%V
    )
    GoTo :EOF
)
: -----------------------------------------------

SetLocal ENABLEDELAYEDEXPANSION
PushD "%~dp0"
For /F "Skip=1 Tokens=*" %%P In (process\%~n1.ini) Do Set "%%P"
Call util\Batch.bat Delete-VariableList version link
: Set URL and send HTTP request with curl
: Parse HTTP response header
: Get the url and the version
For /F %%L In ('Call util\Get-UrlEffective.bat "%RedirectedURL:?=__qm__%" %TEMP%\%~n1.null') Do Set "link=%%~L"
Call process\%~n1.bat "!link:%%=%%%%!" version
Set link=!link:%%=%%%%!
Set version=!version:%%=%%%%!
Call util\Batch.bat Set version link
PopD
EndLocal