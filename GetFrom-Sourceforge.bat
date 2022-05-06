@Echo OFF

:Main
: 1=: Request properties in an ini-file
:     The ini-file template:
:     ----------------------
:     [RequestProperties]
:     RepositoryId=<url>
:     PathFromVersion=<guid>
:     ----------------------
: [2:=] Version reference of the application
: [3:=] Absolute URL reference of the setup

: -----------------------------------------------
: Optional parser: it does not work when URLs
: have special characters like %20 that is
: whitespace encoded
If Not ""=="%~2%~3%~4" (
    For /F "Tokens=1* Delims==" %%U In ('Call "%~f0" %1') Do (
        If "version"=="%%U" If Not ""=="%~2" ( Set "%~2=%%V" ) Else Echo %%U=%%V
        If "link"=="%%U" If Not ""=="%~4" ( Set "%~4=%%V" ) Else Echo %%U=%%V
    )
    GoTo :EOF
)
: -----------------------------------------------

SetLocal ENABLEDELAYEDEXPANSION
: Read ini-file
For /F "Skip=1 Tokens=*" %%P In (%~f1) Do Set "%%P"
PushD "%~dp0"
Call util\Batch.bat Delete-VariableList version link
: Set URL and send HTTP request with curl
: Parse HTTP response header
: Get the effective url and the version
Call :Get-TruncateLastIndex PathFromVersion
For /F "Tokens=2 Delims=? " %%L In ('^
    Curl --url https://sourceforge.net/projects/%RepositoryId%/files/latest/download^
         --silent^
         --head^
         --location ^|^
    FindStr /I /B "Location:"^
') Do (
    Set "link=%%~pL"
    For /F "Tokens=*" %%V In ("!link:~0,%index%!") Do Set version=%%~nxV
    Set "link=%%~L"
)
Call util\Batch.bat Set version link
PopD
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