<#
    Configuration file --
    UpdateServiceURL = "update_service_uerl"
    ApplicationID = "application_guid"
    OwnerBrand = "owner_brand_code"
    ApplicationSpec = "application_spec"
#>

$RequestBody = [xml] @"
    <request
    protocol="$(Switch ($Protocol) {
        { ![string]::IsNullOrEmpty($_) } { $_ }
        Default { '3.1' }
    })"
    updater="Omaha"
    updaterversion="0"
    shell_version="0"
    ismachine="1"
    sessionid="{00000000-0000-0000-0000-000000000000}"
    installsource="taggedmi"
    testsource="auto"
    requestid="{00000000-0000-0000-0000-000000000000}"
    dedup="cr"
    domainjoined="0">
        <os
        platform="win"
        version="$([Environment]::OSVersion.Version)"
        sp=""
        arch="$(Switch ($OSArch) {
            {$_ -in @('x86','x64')} { $_ }
            Default { If ([Environment]::Is64BitOperatingSystem) { 'x64' } Else { 'x86' } }
        })"/>
        <app
        appid=""
        version=""
        nextversion=""
        ap="" 
        lang="$((Get-Culture).Name)"
        brand=""
        client=""
        installage="-1"
        installdate="-1">
            <updatecheck/>
        </app>
    </request>
"@
{
    Param ($Xpath, $Value)
    ($RequestBody.request | Select-Xml $Xpath).Node.Value = $Value
} | ForEach-Object {
    & $_ '//@appid' $ApplicationID
    & $_ '//@brand' $OwnerBrand
    & $_ '//@ap' $ApplicationSpec
}
Try {
    "$( 
        @{
            Uri = $UpdateServiceURL;
            Method = 'POST';
            UserAgent = 'winhttp';
            Body = $RequestBody.OuterXml
        } | ForEach-Object { Invoke-WebRequest @_ } 
    )" | ForEach-Object {
        $XmlResponse = ([xml] $_).response
        {
            Param ($Xpath)
            ($XmlResponse | Select-Xml $Xpath).Node.Value |
            Select-Object -Unique
        }
    } | Select-Object -Property @{
        Name = 'Version';
        Expression = { & $_ '//@version' }
    },@{
        Name = 'Link';
        Expression = {
            $SetupName = & $_ '//@name'
            & $_ '//@codebase' | 
            ForEach-Object { [uri] "$_$(If ($_[-1] -ne '/') {'/'})$SetupName" }
        }
    },@{
        Name = 'Checksum';
        Expression = { (& $_ '//@hash_sha256').ToUpper() }
    },@{
        Name = 'Size';
        Expression = { & $_ '//@size' }
    }
}
Catch {}