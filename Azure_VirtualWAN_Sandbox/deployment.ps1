# This file will be used for testing purposes until a proper CI/CD pipeline is in place.

$mainBicepFile = ".\Azure_VirtualWAN_Sandbox\src\main.bicep"
$mainJSONFile = ".\Azure_VirtualWAN_Sandbox\src\main.json"
$mainParameterFile = ".\main.parameters.json"

# Sets the Environment for either Prod or Dev depending on what is in the DeploymentParameters.json file
# $deploymentParameters = Get-Content -raw $deploymentParametersFile | ConvertFrom-Json
# $environment = $deploymentParameters.Environment

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

$rgName = "Bicep_VirtualWAN_Sandbox"
$location_vhubA = "eastus2"
$location_vhubB = "westus2"
$location_OnPrem = "eastus"

Write-Host "Creating ${rgName}"
New-AzResourceGroup -Name $rgName -Location $location_Main

Write-Host "`nStarting Bicep Deployment.."
New-AzResourceGroupDeployment -ResourceGroupName $rgName `
-TemplateParameterFile $mainParameterFile -TemplateFile $mainBicepFile `
-mainLocation $location_vhubA `
-branchLocation $location_vhubB `
-onPremLocation $location_OnPrem

$vms = Get-AzVM -ResourceGroupName $rgName

foreach ($vm in $vms) {
    $vmStatus = Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Status
    $vmName = $vm.Name 

    if ($vmStatus.Statuses[1].DisplayStatus -eq "VM deallocated") {
        Write-Host "${vmName} is already deallocated."
    }
    else {
        Write-Host "Stopping ${vmName}.."
        Stop-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Force -AsJob
    }
}

$end = get-date -UFormat "%s"
$timeTotalSeconds = $end - $start
$timeTotalMinutes = $timeTotalSeconds / 60
$currentTime = Get-Date -Format "HH:mm K"
Write-Host "Process finished at: ${currentTime}"
Write-Host "Total time taken in seconds: ${timeTotalSeconds}"
Write-Host "Total time taken in minutes: ${timeTotalMinutes}"
Read-Host "`nPress any key to exit.."