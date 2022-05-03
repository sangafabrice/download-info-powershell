/*
    Helper object to retrieve
    update info of an application
    hosted on GitHub Servers
*/
function SourceForgeDownloadInfo(ConfigFile) {
    /*
    (1) Read the Configuration File and
        retrieve configuration variables.
        The Configuration File template:
        =======================
        RepositoryId=<username>/<repo>
        AssetPattern=<regexp>
        =======================
    */
    var ObjFSO = new ActiveXObject("Scripting.FileSystemObject")
    with(ObjFSO.OpenTextFile(ObjFSO.GetFile(ConfigFile).Path, 1)) {
        eval(ReadAll())
        Close()
    }
    /*
    (2) Set the url with the repository
        identifier, send the request and
        get the reponse.
    */
    with(new ActiveXObject("WinHttp.WinHttpRequest.5.1")) {
        Open('HEAD', 'https://sourceforge.net/projects/' + RepositoryId + '/files/latest/download', false)
        Option(0) = 'curl' // Set the User Agent
        Option(6) = false  // Disable Redirects
        Send()
        this.Link = GetResponseHeader('Location')
    }
    /*
    (3) Parse the response and set
        the property values:
        Version and Link
    */
    segments = this.Link.split('?')[0].split('/')
    this.Version = segments.slice(segments.length - 1 - PathFromVersion.split('/').length)[0]
}