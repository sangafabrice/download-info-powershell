@Echo OFF

:Main
: 1=:url
: 2:=last_modified_string

For /F "Tokens=1* Delims=/ " %%h In ('Curl "%~1" --head --silent') Do (
    If /I "%%~h" EQU "HTTP" Echo %%i| Find "200" > nul 2>&1 || GoTo :EOF
    If /I "%%~h" EQU "last-modified:" (
        For /F "Tokens=2-7 Delims=,: " %%D In ("%%~i") Do (
            For /F %%m In ("%%~E") Do (
                If /I "%%~m" EQU "Jan" Set %~2=%%~F01%%~D%%~G%%~H%%~I
                If /I "%%~m" EQU "Feb" Set %~2=%%~F02%%~D%%~G%%~H%%~I
                If /I "%%~m" EQU "Mar" Set %~2=%%~F03%%~D%%~G%%~H%%~I
                If /I "%%~m" EQU "Apr" Set %~2=%%~F04%%~D%%~G%%~H%%~I
                If /I "%%~m" EQU "May" Set %~2=%%~F05%%~D%%~G%%~H%%~I
                If /I "%%~m" EQU "Jun" Set %~2=%%~F06%%~D%%~G%%~H%%~I
                If /I "%%~m" EQU "Jul" Set %~2=%%~F07%%~D%%~G%%~H%%~I
                If /I "%%~m" EQU "Aug" Set %~2=%%~F08%%~D%%~G%%~H%%~I
                If /I "%%~m" EQU "Sep" Set %~2=%%~F09%%~D%%~G%%~H%%~I
                If /I "%%~m" EQU "Oct" Set %~2=%%~F10%%~D%%~G%%~H%%~I
                If /I "%%~m" EQU "Nov" Set %~2=%%~F11%%~D%%~G%%~H%%~I
                If /I "%%~m" EQU "Dec" Set %~2=%%~F12%%~D%%~G%%~H%%~I
            )
        )
    )
)