@Echo OFF

:Main
: 1=: Request properties in an ini-file
:     The ini-file template:
:     ----------------------
:     [RequestProperties]
:     UpdateServiceURL=<url>
:     ApplicationID=<guid>
:     OwnerBrand=<string>
:     ----------------------
: [2:=] Version reference of the application
: [3:=] Absolute URL reference of the setup
: [4:=] The number of available URLs

: -----------------------------------------------
: Optional parser: it does not work when URLs
: have special characters like %20 that is
: whitespace encoded
If Not ""=="%~2%~3%~4" (
    For /F "Tokens=1* Delims==" %%U In ('Call "%~f0" %1') Do (
        If "version"=="%%U" If Not ""=="%~2" ( Set "%~2=%%V" ) Else Echo %%U=%%V
        Echo %%U| Find "link" > Nul && If Not ""=="%~3" ( Call :Get-URLs %%U %%V %~3 ) Else Echo %%U=%%V
        If "count"=="%%U" If Not ""=="%~4" ( Set "%~4=%%V" ) Else Echo %%U=%%V
    )
    GoTo :EOF
)
GoTo Jump
:Get-URLs
: 1=: A string matching the pattern=link[0-9]*
: 2=: The value of the reference named %1
: 3=: The input of the script
    If "link"=="%~1" (
        Set "%~3=%~2"
        GoTo :EOF
    )
    For /F "Delims=link" %%# In ("%~1") Do Set "%~3%%#=%~2" 
    GoTo :EOF
:Jump
: -----------------------------------------------

SetLocal ENABLEDELAYEDEXPANSION
: Read ini-file
For /F "Skip=1 Tokens=*" %%P In (%~f1) Do Set "%%P"
: Set request body
Set body=%TEMP%\%~n1-request.xml
Set request=%TEMP%\%~n1-request.conf
Set response=%TEMP%\%~n1-response.xml
PushD "%~dp0"
Xml ed --update request//@appid --value "%ApplicationID%" omaha\request.xml |^
Xml ed --update request//@brand --value "%OwnerBrand%" |^
Xml ed --update request//@lang --value "%ApplicationLang%" |^
Xml ed --update request//@ap --value "%ApplicationSpec%" > %body%
Call util\Send-Request.bat omaha\request.conf "--url --data --output" %request%
: Parse HTTP response body
Call util\Batch.bat Delete-VariableList version link count name codebase
Call :Get-NodeValue version
Call :Get-NodeValue codebase count
Call :Get-NodeValue name
For /F "Delims==" %%C In ('Set codebase 2^> Nul') Do (
    Set index=%%C
    Set index=!index:codebase=!
    If Not "!%%C:~-1!"=="/" Set %%C=!%%C!/
    Set link!index!=!%%C!%name%
)
Call util\Batch.bat Set version link count
PopD
: Clean filesystem
Del /F /Q %body% %response%
EndLocal
GoTo :EOF


:Set-Request 
: 1=: Curl config arguments
    Set request_arg=%1
    Set data_ref=%~1
    Set data_ref=%data_ref:@=%
    Call Set request_arg=%%request_arg:%data_ref%=!%data_ref%!%%
    GoTo :EOF

:Get-NodeValue 
: 1=: The node reference in the response
: [2=:] The number of references of the node in the response
    If Not ""=="%~2" Set %~2=0
    For /F %%V In ('Xml sel -t -v "response//@%~1" %response%') Do (
        If Not ""=="%~2" (
            If !%~2!==0 ( Set "%~1=%%~V" ) Else Set "%~1!%~2!=%%~V"
            Set /A %~2+=1
        ) Else Set "%~1=%%~V"
    )
    GoTo :EOF