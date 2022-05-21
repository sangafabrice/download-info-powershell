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
If Not ""=="%~2%~3" (
    For /F "Tokens=1* Delims==" %%U In ('Call "%~f0" %1') Do (
        If "version"=="%%U" If Not ""=="%~2" ( Set "%~2=%%V" ) Else Echo %%U=%%V
        If "link"=="%%U" If Not ""=="%~3" ( Set "%~3=%%V" ) Else Echo %%U=%%V
    )
    GoTo :EOF
)
: -----------------------------------------------

SetLocal ENABLEDELAYEDEXPANSION
: Read ini-file
For /F "Skip=1 Tokens=*" %%P In (%~f1) Do Set "%%P"
Call "%~dp0GetFrom-Link.bat" SourceForge
EndLocal