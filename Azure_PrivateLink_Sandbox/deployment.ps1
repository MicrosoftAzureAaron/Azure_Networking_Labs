# This file will be used for testing purposes until a proper CI/CD pipeline is in place.

$mainBicepFile = ".\Azure_PrivateLink_Sandbox\src\main.bicep"
$mainJSONFile = ".\Azure_PrivateLink_Sandbox\src\main.json"
$mainParameterFile = ".\main.parameters.json"

$start = get-date -UFormat "%s"

$currentTime = Get-Date -Format "HH:mm K"
Write-Host "Starting Bicep Deployment.  Process began at: ${currentTime}"

Write-Host "`nBuilding main.json from main.bicep.."
bicep build $mainBicepFile --outfile $mainJSONFile

# Specifies the account and subscription where the deployment will take place.
if (!$subID) {
    $subID = Read-Host "Please enter the Subscription ID that you want to deploy this Resource Group to: "
}
Set-AzContext -Subscription $subID


$rgName = "Bicep_PrivateLink_Sandbox"
$locationA = "eastus2"
# $locationB = "eastus2"

Write-Host "Creating ${rgName}"
New-AzResourceGroup -Name $rgName -Location $locationA

Write-Host "`nStarting Bicep Deployment.."
New-AzResourceGroupDeployment -ResourceGroupName $rgName -TemplateFile $mainBicepFile -TemplateParameterFile $mainParameterFile `
    -locationA $srcLocation # -dstLocation $dstLocation

$end = get-date -UFormat "%s"
$timeTotalSeconds = $end - $start
$timeTotalMinutes = $timeTotalSeconds / 60
$currentTime = Get-Date -Format "HH:mm K"
Write-Host "Process finished at: ${currentTime}"
Write-Host "Total time taken in seconds: ${timeTotalSeconds}"
Write-Host "Total time taken in minutes: ${timeTotalMinutes}"
Read-Host "`nPress any key to exit.."