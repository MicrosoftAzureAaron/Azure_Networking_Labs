# This file will be used for testing purposes until a proper CI/CD pipeline is in place.

<<<<<<< HEAD
$mainBicepFile = ".\src\main.bicep"
$mainJSONFile = ".\src\main.json"
#$mainParameterFile = ".\virtualMachines.parameters.json"

$start = get-date -UFormat "%s"
 
$currentTime = Get-Date -Format "HH:mm K"
Write-Host "Starting Bicep Deployment.  Process began at: ${currentTime}"
=======
$deploymentName = "TD_Repro"
$deploymentFilePath = ".\${deploymentName}\"
$mainBicepFile = "${deploymentFilePath}src\main.bicep"
$mainParameterFile = "${deploymentFilePath}main.parameters.bicepparam"
$iterationFile = "${deploymentFilePath}iteration.txt"

if (!(Test-Path $iterationFile)) {
    New-Item -Path $iterationFile
    Set-Content -Path $iterationFile -Value 1
}

$iteration = [int](Get-Content $iterationFile)
$scenario_Name = "ilb"
$rgName = "${deploymentName}_${scenario_Name}_${iteration}"
$location = "eastus2"
>>>>>>> a0d753352a1da0ad4a3cdfd85f3902b00c9d51cf

if (Get-AzResourceGroup -Name $rgName) {
    $response = Read-Host "Resource Group ${rgName} already exists.  How do you want to handle this?  Below are the options.  Type the corresponding number and enter to choose.

    1 - Delete this Resource Group and create another Resource Group with a higher iteration number.
    2 - Leave this Resource Group alone and create another Resource Group with a higher iteration number.
    3 - Update this Resource Group with the latest changes."

    if ($response -eq "1") {
        Write-Host "Deleting $rgName"
        Remove-AzResourceGroup -Name $rgName -Force -AsJob
        Set-Content -Path $iterationFile -Value "$($iteration + 1)"
        $iteration = [int](Get-Content $iterationFile)
        $rgName = "${deploymentName}_${iteration}"
        Write-Host "Creating $rgName"
    } 
    elseif ($response -eq "2") {
        Write-Host "Disregarding $rgName"
        Set-Content -Path $iterationFile -Value "$($iteration + 1)"
        $iteration = [int](Get-Content $iterationFile)
        $rgName = "${deploymentName}_${iteration}"
        Write-Host "Creating $rgName"
    } 
    elseif ($response -eq "3") {
        Write-Host "Updating $rgName"
    } 
    else {
        Write-Host "Invalid response.  Canceling Deploment.."
        return
    }
} 
else {
    Set-Content -Path $iterationFile -Value "$($iteration + 1)"
    $iteration = [int](Get-Content $iterationFile)
    $rgName = "${deploymentName}_${iteration}"
}


<<<<<<< HEAD
# # Specifies the account and subscription where the deployment will take place.
# if (!$subID) {
#     $subID = Read-Host "Please enter the Subscription ID that you want to deploy this Resource Group to: "
# }
# #Set-AzContext -Subscription $subID

# $iteration = "0012"
# $scenario_Name = "privatelink${iteration}"
# $rgName = "Connection_${scenario_Name}_Sandbox"
# $locationClient = 'westeurope'
# $locationServer = 'westeurope'
# $randomFiveLetterString = .\scripts\deployment_Scripts\Get-LetterGUID.ps1

# # Might have to test with the same size VM the customer uses.
# # --Update 11/20 - Could not repro with same size as customer's VM
# # $virtualMachine_Size = 'Standard_E48s_v5'
# $virtualMachine_Size = 'Standard_E4d_v5'

# Write-Host "Creating ${rgName}"
# New-AzResourceGroup -Name $rgName -Location $locationClient

# Write-Host "`nStarting Bicep Deployment.."
# New-AzResourceGroupDeployment -ResourceGroupName $rgName -TemplateFile $mainBicepFile -TemplateParameterFile $mainParameterFile `
#     -locationClient $locationClient -locationServer $locationServer `
#     -virtualMachine_Size $virtualMachine_Size `
#     -storageAccount_Name "plconntestsa${randomFiveLetterString}" `
#     ##-scenario_Name $scenario_Name `
#     -numberOfClientVMs 1 `
#     -numberOfServerVMs 1
# # -usingAzureFirewall $false
# # -storageAccount_ID $storageAccount_ID `
=======
Write-Host "`nCreating Resource Group ${rgName}"
New-AzResourceGroup -Name $rgName -Location $location

$stopwatch = [system.diagnostics.stopwatch]::StartNew()

Write-Host "`nStarting Bicep Deployment.  Process began at: $(Get-Date -Format "HH:mm K")"

New-AzResourceGroupDeployment -ResourceGroupName $rgName -TemplateFile $mainBicepFile -TemplateParameterFile $mainParameterFile

$stopwatch.Stop()
>>>>>>> a0d753352a1da0ad4a3cdfd85f3902b00c9d51cf

Write-Host "Process finished at: $(Get-Date -Format "HH:mm K")"
Write-Host "Total time taken in minutes: $($stopwatch.Elapsed.TotalMinutes)"
Read-Host "`nPress any key to exit.."