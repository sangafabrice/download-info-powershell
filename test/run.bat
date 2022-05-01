@Echo OFF
PushD "%~dp0"
If Not ""=="%~1" GoTo %~1
:Github
Echo **********************************
Echo *******From Github Tests**********
Echo.
Echo =============================START
Echo +- Test Hugo resource
Echo -- Start: hugo.ini: [verbose]
Type hugo.ini
Echo.
Echo -- End
Call ..\GetFrom-Github.bat hugo.ini
Echo Download info:
Set hugo
Call :Delete-VariableList hugo
Echo =================================1
Echo.
Echo +- Test Hugo resource: Get version
Call ..\GetFrom-Github.bat hugo.ini hugo.version > Nul
Echo Download info:
Set hugo
Call :Delete-VariableList hugo
Echo =================================2
Echo.
Echo +- Test Hugo resource: Get available URLs
Call ..\GetFrom-Github.bat hugo.ini "" hugo.link > Nul
Echo Download info:
Set hugo
Call :Delete-VariableList hugo
Echo =================================3
Echo.
Echo +- Test Hugo resource: Get available URLs count
Call ..\GetFrom-Github.bat hugo.ini "" "" hugo.count > Nul
Echo Download info:
Set hugo
Call :Delete-VariableList hugo
Echo =================================4
Echo.
Echo +- Test Hugo .zip resource
Echo -- Start: hugo2.ini: [verbose]
Type hugo2.ini
Echo.
Echo -- End
Call ..\GetFrom-Github.bat hugo2.ini
Echo Download info:
Set hugo
Call :Delete-VariableList hugo
Echo =================================5
Echo.
Echo +- Test Hugo .zip resource: Get version
Call ..\GetFrom-Github.bat hugo2.ini hugo.version > Nul
Echo Download info:
Set hugo
Call :Delete-VariableList hugo
Echo =================================6
Echo.
Echo +- Test Hugo .zip resource: Get available URLs
Call ..\GetFrom-Github.bat hugo2.ini "" hugo.link > Nul
Echo Download info:
Set hugo
Call :Delete-VariableList hugo
Echo =================================7
Echo.
Echo +- Test Hugo .zip resource: Get available URLs count
Call ..\GetFrom-Github.bat hugo2.ini "" "" hugo.count > Nul
Echo Download info:
Set hugo
Call :Delete-VariableList hugo
Echo ===============================END
If Not ""=="%~1" GoTo End
Echo.
: -------------------------------------------------------------------
:Omaha
Echo **********************************
Echo *******From Omaha Tests**********
Echo.
Echo =============================START
Echo +- Test Google Chrome
Echo -- Start: googlechrome.ini: [verbose]
Type googlechrome.ini
Echo.
Echo -- End
Call ..\GetFrom-Omaha.bat googlechrome.ini
Echo Download info:
Set chrome
Call :Delete-VariableList chrome
Echo =================================1
Echo.
Echo +- Test Google Chrome: Get version
Call ..\GetFrom-Omaha.bat googlechrome.ini chrome.version > Nul
Echo Download info:
Set chrome
Call :Delete-VariableList chrome
Echo =================================2
Echo.
Echo +- Test Google Chrome: Get available URLs
Call ..\GetFrom-Omaha.bat googlechrome.ini "" chrome.link > Nul
Echo Download info:
Set chrome
Call :Delete-VariableList chrome
Echo =================================3
Echo.
Echo +- Test Google Chrome: Get available URLs count
Call ..\GetFrom-Omaha.bat googlechrome.ini "" "" chrome.count > Nul
Echo Download info:
Set chrome
Call :Delete-VariableList chrome
Echo =================================4
Echo.
Echo +- Test Avast Secure: [verbose]
Echo -- Start: avastbrowser.ini
Type avastbrowser.ini
Echo.
Echo -- End
Call ..\GetFrom-Omaha.bat avastbrowser.ini
Echo Download info:
Set secure
Call :Delete-VariableList secure
Echo =================================5
Echo.
Echo +- Test Avast Secure: Get version [verbose]
Call ..\GetFrom-Omaha.bat avastbrowser.ini secure.version
Echo Download info:
Set secure
Call :Delete-VariableList secure
Echo =================================6
Echo.
Echo +- Test Avast Secure: Get available URLs [verbose]
Call ..\GetFrom-Omaha.bat avastbrowser.ini "" secure.link
Echo Download info:
Set secure
Call :Delete-VariableList secure
Echo =================================7
Echo.
Echo +- Test Avast Secure: Get available URLs count [verbose]
Call ..\GetFrom-Omaha.bat avastbrowser.ini "" "" secure.count
Echo Download info:
Set secure
Call :Delete-VariableList secure
Echo ===============================END
If Not ""=="%~1" GoTo End
Echo.
: -------------------------------------------------------------------
:SourceForge
Echo **********************************
Echo *******From SourceForge Tests**********
Echo.
Echo =============================START
Echo +- Test 7-Zip
Echo -- Start: sevenzip.ini: [verbose]
Type sevenzip.ini
Echo.
Echo -- End
Call ..\GetFrom-Sourceforge.bat sevenzip.ini
Echo Download info:
Set 7zip
Call :Delete-VariableList 7zip
Echo =================================1
Echo.
Echo +- Test 7-Zip: Get version
Call ..\GetFrom-Sourceforge.bat sevenzip.ini 7zip.version > Nul
Echo Download info:
Set 7zip
Call :Delete-VariableList 7zip
Echo =================================2
Echo.
Echo +- Test 7-Zip: Get available URLs
Call ..\GetFrom-Sourceforge.bat sevenzip.ini "" 7zip.link > Nul
Echo Download info:
Set 7zip
Call :Delete-VariableList 7zip
Echo =================================3
Echo.
Echo +- Test Wamp Server: [verbose]
Echo -- Start: wampserver.ini
Type wampserver.ini
Echo.
Echo -- End
Call ..\GetFrom-Sourceforge.bat wampserver.ini
Echo Download info:
Set wamp
Call :Delete-VariableList wamp
Echo =================================4
Echo.
Echo +- Test Wamp Server: Get version [verbose]
Call ..\GetFrom-Sourceforge.bat wampserver.ini wamp.version
Echo Download info:
Set wamp
Call :Delete-VariableList wamp
Echo =================================5
Echo.
Echo +- Test Wamp Server: Get available URLs [verbose]
Call ..\GetFrom-Sourceforge.bat wampserver.ini "" wamp.link
Echo Download info:
Set wamp
Call :Delete-VariableList wamp
Echo ===============================END
If Not ""=="%~1" GoTo End
:End
PopD
GoTo :EOF

:Delete-VariableList 
: 1=: The Leftmost substring of the variables to delete
    For /F "Delims==" %%C In ('Set %~1 2^> Nul') Do Set %%C=
    GoTo :EOF