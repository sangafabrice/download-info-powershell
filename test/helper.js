function BuildPath(FileName) {
    with(new ActiveXObject("Scripting.FileSystemObject")) {
        return BuildPath(GetParentFolderName(WSH.ScriptFullName), FileName)
    }
}