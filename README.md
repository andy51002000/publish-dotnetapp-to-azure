# 前言

對於開發人員來說, routine的事情能夠自動化就自動化, 比如說編譯程式, 或是發布程式等等, 這些自動化之後, 才能將更多的專注力放在程式開發上, 以下就是介紹如何使用 MSBuild來佈署.NET Framework的程式到Azure App Service上


## MSBuild
用來佈署.Net framework到Azure 上的工具, 可以透過安裝Visual Studio來獲得, 使用方式如下:


```powershell
MSBuild <solution的位置>
/p:DeployOnBuild 
/p:PublishProfile
/p:Password
```


MSBuild需要吃一個Publish Profile才能正常運作, 以下教學將會演示如何編輯Publish Profile, 並且使用 MSBuild來做編譯以及佈署



## 必要條件

1. 需要安裝Visual Studio
2. 需要在Azure App Service建立Web App服務  
3. 需要取得佈署帳密(Publish Profile)
4. 需要安裝Azure Cli


```powershell
az webapp deployment list-publishing-profiles --name YOUR-APP-NAME --resource-group YOUR-RESOURCE-GROUP 
```



## Step 1. 下載佈署範本

```powershell
$appSolutionDeploymentProfile = ".\production.pubxml"
wget https://gist.githubusercontent.com/andy51002000/37a0af3fec1caf2955f109c0b583b3e3/raw/9b2105abd05a304b8ea6045fe78c8de781f4d0a2/publish.pubxml -OutFile $appSolutionDeploymentProfile
```

## Step 2. 開始來編輯publish profile的內容

宣告一些變數, 如Subscription Id, Resource Group的名字, 還有App的名字


```powershell
$SubcriptionId = "abcd-abcd-abcd-12312312"
$ResouceGroup = "MyGroup"
$appname = "MyApp"
```

取得佈署帳密(前提是Azure App Service上已經有開Web App了)


```powershell
$appUserPWD= $(az webapp deployment list-publishing-profiles --name $appname --resource-group $ResouceGroup  --query '[0].{userPWD:userPWD, userName:userName}' -o json | ConvertFrom-Json )
```



建立物件來暫存更新內容


```powershell
$profileObj = @{
    ResourceId = "/subscriptions/${SubcriptionId}/resourceGroups/${ResouceGroup}/providers/Microsoft.Web/sites/${appname}"
    ResourceGroup = ${ResouceGroup}
    SiteUrlToLaunchAfterPublish = "http://${appname}.azurewebsites.net"
    MSDeployServiceURL = "${appname}.scm.azurewebsites.net:443"
    DeployIisAppPath = "${appname}"
    UserName = $appUserPWD.userName
}
```

## Step 3. 更新publish profile的內容

```powershell
[xml]$myXML = Get-Content $appSolutionDeploymentProfile
$myXML.Project.PropertyGroup.ResourceId=$profileObj.ResourceId
$myXML.Project.PropertyGroup.ResourceGroup=$profileObj.ResourceGroup
$myXML.Project.PropertyGroup.SiteUrlToLaunchAfterPublish=$profileObj.SiteUrlToLaunchAfterPublish
$myXML.Project.PropertyGroup.DeployIisAppPath=$profileObj.DeployIisAppPath
$myXML.Project.PropertyGroup.UserName=$profileObj.UserName
$myXML.Project.PropertyGroup.MSDeployServiceURL=$profileObj.MSDeployServiceURL
$myXML.Save($appSolutionDeploymentProfile)
```

## Step 4. 最後呼叫MSBuild

```powershell
$AppSolution="solution的位置"
$MSBuild="MSBuild的位置"
&$MSBuild $AppSolution /p:DeployOnBuild=true /p:PublishProfile=$appSolutionDeploymentProfile /p:Password="$($appUserPWD.userPWD)"
```



## 結語

透過MSBuild這個工具, 開發人員可以編譯程式碼以及發布程式到Azure的行為指令化成腳本, 而這些指令化的腳本可以被應用在CI/CD的流程中, 進而使整個開發流程自動化





## 補充：


有人問說Visual Studio產生出的publish profile不是本來就有帶密碼了, 為什麼使用MSBuild的時候還要特別指定密碼
因為密碼會藏在.usr裡, command無法讀取, 所以需要表明密碼









