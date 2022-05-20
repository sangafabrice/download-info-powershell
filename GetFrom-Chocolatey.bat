@Echo OFF

:Main
: [1:=] Version reference of the application
: [2:=] Absolute URL reference of the setup

: -----------------------------------------------
: Optional parser: it does not work when URLs
: have special characters like %20 that is
: whitespace encoded
If Not ""=="%~1%~2" (
    For /F "Tokens=1* Delims==" %%U In ('Call "%~f0"') Do (
        If "version"=="%%U" If Not ""=="%~1" ( Set "%~1=%%V" ) Else Echo %%U=%%V
        If "link"=="%%U" If Not ""=="%~2" ( Set "%~2=%%V" ) Else Echo %%U=%%V
    )
    GoTo :EOF
)
: -----------------------------------------------

SetLocal ENABLEDELAYEDEXPANSION
PushD "%~dp0"
: Set URL and send HTTP request with curl
: Parse HTTP response header
: Get the url and the version
For /F "Tokens=2 Delims=? " %%L In ('^
    Curl --url https://community.chocolatey.org/api/v2/package/chocolatey^
         --head ^
         --request  "GET"^
         --header "User-Agent: winhttp"^
         --silent ^|^
    FindStr /I /B "Location:"^
') Do (
    For /F "Tokens=1* Delims=." %%U In ("%%~nL") Do Set version=%%~V
    Set "link=%%~L"
)
Call util\Batch.bat Set version link
PopD
EndLocal