# This file will be used for testing purposes until a proper CI/CD pipeline is in place.

$mainBicepFile = ".\TD_Repro\src\main.bicep"
$mainJSONFile = ".\TD_Repro\src\main.json"
$mainParameterFile = ".\virtualMachines.parameters.json"

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


$iteration = "12"
$scenario_Name = "privatelink${iteration}"
$rgName = "Connection_${scenario_Name}_Sandbox"
$locationClient = 'westeurope'
$locationServer = 'westeurope'
$randomFiveLetterString = .\scripts\deployment_Scripts\Get-LetterGUID.ps1

# Might have to test with the same size VM the customer uses.
# --Update 11/20 - Could not repro with same size as customer's VM
# $virtualMachine_Size = 'Standard_E48s_v5'
$virtualMachine_Size = 'Standard_E4d_v5'

Write-Host "Creating ${rgName}"
New-AzResourceGroup -Name $rgName -Location $locationClient

Write-Host "`nStarting Bicep Deployment.."
New-AzResourceGroupDeployment -ResourceGroupName $rgName -TemplateFile $mainBicepFile -TemplateParameterFile $mainParameterFile `
    -locationClient $locationClient -locationServer $locationServer `
    -virtualMachine_Size $virtualMachine_Size `
    -storageAccount_Name "plconntestsa${randomFiveLetterString}" `
    -scenario_Name $scenario_Name `
    -numberOfClientVMs 1 `
    -numberOfServerVMs 1 `
    -usingAzureFirewall $false

$end = get-date -UFormat "%s"
$timeTotalSeconds = $end - $start
$timeTotalMinutes = $timeTotalSeconds / 60
$currentTime = Get-Date -Format "HH:mm K"
Write-Host "Process finished at: ${currentTime}"
Write-Host "Total time taken in seconds: ${timeTotalSeconds}"
Write-Host "Total time taken in minutes: ${timeTotalMinutes}"
Read-Host "`nPress any key to exit.."