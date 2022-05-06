@Echo OFF
:Delete-VariableList 
: 1=: The Leftmost substring of the variables to delete
    For /F "Delims==" %%C In ('Set %~1 2^> Nul') Do Set %%C=
    GoTo :EOF