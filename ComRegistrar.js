function ComRegistrar(strWorkDir, intTruncatedGuidSize) {
    this.Fso = new ActiveXObject('Scripting.FileSystemObject')
    this.Root = this.Fso.GetFolder(strWorkDir)
    this.TruncGuidSize = intTruncatedGuidSize
}

ComRegistrar.prototype.Load = function(strWscScriptPath) {
    var objCom = new ActiveXObject('Msxml2.DOMDocument.6.0')
    objCom.load(strWscScriptPath)
    var strClsid
    var strTargetPath
    do {
        strClsid = (new ActiveXObject('Scriptlet.TypeLib')).Guid.substr(0, 38)
        strTargetPath = this.Fso.BuildPath(this.Root, '$' + strClsid.substr(1, this.TruncGuidSize) + '.wsc')
    } while(this.Fso.FileExists(strTargetPath))
    this.Script = objCom
    with(objCom.documentElement.selectSingleNode('/package')) {
        selectSingleNode('//@classid').text = strClsid
        this.ProgId = selectSingleNode('//@progid').text
    }
    this.Target = strTargetPath
}

ComRegistrar.prototype.GetText = function() {
    return this.Script
}

ComRegistrar.prototype.Registered = function() {
    try {
        new ActiveXObject(this.ProgId)
        return true
    } catch (e) {
        return false
    }
}

ComRegistrar.prototype.Write = function() {
    with(this.Fso.OpenTextFile(this.Target, 2, true)) {
        Write(this.Script.xml)
        Close()
    }    
}

ComRegistrar.prototype.Register = function() {
    try {
        with(new ActiveXObject('WScript.Shell')) {
            RegRead('HKEY_USERS\\S-1-5-19\\Environment\\TEMP')
            var utilExec = Exec('RegSvr32 scrobj.dll /n /i:' + this.Target + ' /s')
        }
        while(utilExec.Status != 1) {}
    } catch (e) {}
}