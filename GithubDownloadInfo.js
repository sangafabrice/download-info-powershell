/*
    Helper object to retrieve
    update info of an application
    hosted on GitHub Servers
*/
function GithubDownloadInfo(ConfigFile) {
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
        Open('GET', 'https://api.github.com/repos/' + RepositoryId + '/releases/latest', false)
        Send()
        response = this.JSON.parse(ResponseText)
    }
    /*
    (3) Parse the response and set
        the property values:
        Version and Link
    */
    this.Version = response.tag_name
    this.Link = new Array()
    var count = 0
    Assets = response.assets
    for(var i = 0; i < Assets.length; i++) {
        var Url = Assets[i].browser_download_url
        if((Url.split('/').reverse())[0].match(AssetPattern)) this.Link[count++] = Url
    }
}

with(new ActiveXObject('htmlfile')) {
    write('<meta http-equiv="x-ua-compatible" content="IE=11"/>')
    close(GithubDownloadInfo.prototype.JSON = parentWindow.JSON)
}