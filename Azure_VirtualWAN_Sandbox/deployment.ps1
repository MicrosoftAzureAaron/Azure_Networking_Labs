# This file will be used for testing purposes until a proper CI/CD pipeline is in place.

$mainBicepFile = ".\Azure_VirtualWAN_Sandbox\src\main.bicep"
$mainParameterFile = ".\main.parameters.json"

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

$stopwatch = [system.diagnostics.stopwatch]::StartNew()

Write-Host "`nStarting Bicep Deployment.  Process began at: $(Get-Date -Format "HH:mm K")"

New-AzResourceGroupDeployment -ResourceGroupName $rgName `
-TemplateParameterFile $mainParameterFile -TemplateFile $mainBicepFile `
-mainLocation $location_vhubA `
-branchLocation $location_vhubB `
-onPremLocation $location_OnPrem

# $vms = Get-AzVM -ResourceGroupName $rgName

# foreach ($vm in $vms) {
#     $vmStatus = Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Status
#     $vmName = $vm.Name 

#     if ($vmStatus.Statuses[1].DisplayStatus -eq "VM deallocated") {
#         Write-Host "${vmName} is already deallocated."
#     }
#     else {
#         Write-Host "Stopping ${vmName}.."
#         Stop-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Force -AsJob
#     }
# }

$stopwatch.Stop()

Write-Host "Process finished at: $(Get-Date -Format "HH:mm K")"
Write-Host "Total time taken in minutes: $($stopwatch.Elapsed.TotalMinutes)"
Read-Host "`nPress any key to exit.."