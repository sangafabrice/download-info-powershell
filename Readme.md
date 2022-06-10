# **DownloadInfo.psm1**
![Module Version](https://img.shields.io/badge/version-v3.1.4-yellow) ![Test Coverage](https://img.shields.io/badge/coverage-98.35%25-green)
##### Author: Fabrice Sanga
<br/>

## **`Get-DownloadInfo`**
Gets the information to update an application
<br/>

### **Syntax**
```PowerShell
Get-DownloadInfo
    [-Path] <string>
    [-From {Github | Omaha | SourceForge}]

Get-DownloadInfo
    -PropertyList <hashtable>
    [-From {Github | Omaha | SourceForge}]
```

### **Description**
The `Get-DownloadInfo` function retrieves from a server information relative to updating a specific application. The canonical information set consists of:
- `Version`: the latest version of the application
- `Link`: the URL to the setup resource.

This set can be augmented with additional elements depending on the server that hosts the application. Those elements may be the size of the resource or its checksum code.

The command takes two parameters: either `-Path` or `-PropertyList`, and `-From`.

The parameter `-From` is the server name to get the information from, and its values are either **Github**, **Omaha**, or **Sourceforge**. The parameter `-PropertyList` is a set of name-value arguments required to build the HTTP request to the server. `-Path` is the path to a file holding the properties list.

### **Examples**

#### **Example 1: Get update information from GitHub using a configuration file**
```PowerShell
PS > Get-Content .\test\hugo.toml
RepositoryId="gohugoio/hugo"
AssetPattern="hugo_extended_.*_Windows-64bit\.zip$"

PS > Get-DownloadInfo -Path .\test\hugo.toml -From Github | Format-List
Version : v0.99.1
Link    : @{Url=https://github.com/gohugoio/hugo/releases/download/v0.99.1/hugo_extended_0.99.1_Windows-64bit.zip; Size=18560918}
```

#### **Example 2: Get update information from Omaha using the inline hashtable**
```PowerShell
PS > $PropertyList = @{
    UpdateServiceURL="https://update.googleapis.com/service/update2";
    ApplicationID="{8A69D345-D564-463c-AFF1-A69D9E530F96}";
    OwnerBrand="YTUH";
    ApplicationSpec="x64-stable-statsdef_1"
}

PS > $ChromeUpdate = Get-DownloadInfo -PropertyList $PropertyList -From Omaha

PS > $ChromeUpdate.Link[2].AbsoluteUri
https://edgedl.me.gvt1.com/edgedl/release2/chrome/ade5ivbjyqxhzr5n4rtzkimdjmpq_102.0.5005.63/102.0.5005.63_chrome_installer.exe

PS > $ChromeUpdate.Checksum
BAB92549E4A2B09897206D2B115195FE8594757406FB573F4AB1B2C2C1E0FD12
```

#### **Example 3: Get update information from SourceForge**
```PowerShell
PS > Get-DownloadInfo -PropertyList @{
    RepositoryId="sevenzip";
    PathFromVersion=""
} -From Sourceforge

Version Link
------- ----
21.07   https://netix.dl.sourceforge.net/project/sevenzip/7-Zip/21.07/7z2107-x64.exe
```

### **Parameters**

### **`-Path`**
The path to the configuration file.
| | | |
|-|-|-|
|Type:| String |
|Required:| True |
|Position:| 0 |
|Default value:| none |
|Accept pipeline input:| False |
|Accept wildcard characters:| False |

### **`-PropertyList`**
The list of configuration arguments.
| | | |
|-|-|-|
|Type:| Hashtable |
|Required:| True |
|Position:| Named |
|Default value:| none |
|Accept pipeline input:| False |
|Accept wildcard characters:| False |

### **`-From`**
The host server to get the information from.
| | | |
|-|-|-|
|Type:| String |
|Required:| False |
|Position:| Named |
|Default value:| "Github" |
|Accept pipeline input:| False |
|Accept wildcard characters:| False |

