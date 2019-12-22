$appSolutionDeploymentProfile = ".\production.pubxml"
wget https://gist.githubusercontent.com/andy51002000/37a0af3fec1caf2955f109c0b583b3e3/raw/9b2105abd05a304b8ea6045fe78c8de781f4d0a2/publish.pubxml -OutFile $appSolutionDeploymentProfile


$SubcriptionId = "abcd-abcd-abcd-12312312"
$ResouceGroup = "MyGroup"
$appname = "MyApp"

$appUserPWD= $(az webapp deployment list-publishing-profiles --name $appname --resource-group $ResouceGroup  --query '[0].{userPWD:userPWD, userName:userName}' -o json | ConvertFrom-Json )


$profileObj = @{
    ResourceId = "/subscriptions/${SubcriptionId}/resourceGroups/${ResouceGroup}/providers/Microsoft.Web/sites/${appname}"
    ResourceGroup = ${ResouceGroup}
    SiteUrlToLaunchAfterPublish = "http://${appname}.azurewebsites.net"
    MSDeployServiceURL = "${appname}.scm.azurewebsites.net:443"
    DeployIisAppPath = "${appname}"
    UserName = $appUserPWD.userName
}


[xml]$myXML = Get-Content $appSolutionDeploymentProfile
$myXML.Project.PropertyGroup.ResourceId=$profileObj.ResourceId
$myXML.Project.PropertyGroup.ResourceGroup=$profileObj.ResourceGroup
$myXML.Project.PropertyGroup.SiteUrlToLaunchAfterPublish=$profileObj.SiteUrlToLaunchAfterPublish
$myXML.Project.PropertyGroup.DeployIisAppPath=$profileObj.DeployIisAppPath
$myXML.Project.PropertyGroup.UserName=$profileObj.UserName
$myXML.Project.PropertyGroup.MSDeployServiceURL=$profileObj.MSDeployServiceURL
$myXML.Save($appSolutionDeploymentProfile)


$AppSolution=".\source\DeployToAzureByMSBuild.sln"
$MSBuild="MSBuild的位置"
&$MSBuild $AppSolution /p:DeployOnBuild=true /p:PublishProfile=$appSolutionDeploymentProfile /p:Password="$($appUserPWD.userPWD)"


