@Echo OFF

:Main
: 1=: Request properties in an ini-file
:     The ini-file template:
:     ----------------------
:     [RequestProperties]
:     RepositoryId=<url>
:     AssetPattern=<guid>
:     ExcludeTag=<regexp>
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
PushD "%~dp0"
Call util\Batch.bat Delete-VariableList version link count
: Set URL and send HTTP request with curl
: Parse HTTP response header with Jq
Set base=https://api.github.com/repos/%RepositoryId%/releases
Set curl_cmd=Curl --url %base%/latest --silent
If DEFINED ExcludeTag (
    Set curl_cmd=Curl --url %base% --silent
    Set "curl_cmd=!curl_cmd! ^^^| Jq --arg ExcludeTag %ExcludeTag% --from-file github\exclude-pattern.jq"
)
For /F "Tokens=*" %%L In ('^
    %curl_cmd% ^|^
    Jq --arg AssetPattern %AssetPattern% --from-file github\parse-response.jq 2^> Nul^
') Do Set "%%~L"
Call util\Batch.bat Set version link count
PopD
EndLocal
GoTo :EOF