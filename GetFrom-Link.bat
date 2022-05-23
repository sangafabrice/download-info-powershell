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
Call util\Batch.bat Delete-VariableList version link RedirectedURL PageURL IsBaseURL FirstOnly SetupURL
For /F "Skip=1 Tokens=*" %%P In (process\%~n1.ini) Do Set "%%P"
: Set URL and send HTTP request with curl
: Parse HTTP response header
: Get the url and the version
If DEFINED RedirectedURL Call :GetLink-RedirectedURL
If DEFINED PageURL Call :GetLink-PageURL
If DEFINED SetupURL Call :GetLink-SetupURL
Set process_script=process\%~n1.bat
If EXIST %process_script% Call %process_script% "!link:%%=%%%%!" version link
Set link=!link:%%=%%%%!
Set version=!version:%%=%%%%!
Call util\Batch.bat Set version link
PopD
EndLocal
GoTo :EOF

:GetLink-RedirectedURL
    For /F %%L In ('Call util\Get-UrlEffective.bat "%RedirectedURL:?=__qm__%" %TEMP%\%~n1.null') Do Set "link=%%~L"
    GoTo :EOF

:GetLink-PageURL
    If DEFINED IsBaseURL Set "link=%PageURL%"
    For /F "Tokens=*" %%L In ('^
        Curl --url "%PageURL%" --silent ^|^
        Pup "%Selector%" ^
    ') Do (
        Set "link=%link%%%~L"
        If DEFINED FirstOnly GoTo :EOF
    )
    GoTo :EOF

:GetLink-SetupURL
    Call util\Get-LastModified.bat "%SetupURL%" version
    If DEFINED version Set link=%SetupURL%
    GoTo :EOF