@description('Azure Datacenter location for the Hub and Server A resources')
param locationClient string = 'westeurope'

@description('URL location for custom scripts')
param customScriptURL string = 'https://raw.githubusercontent.com/MicrosoftAzureAaron/Azure_Networking_Labs/main/scripts/TDTestScripts/'

@description('''
Azure Datacenter location for the Server B resources.  
Use the same region as locationClient if you do not want to test multi-region
''')
param locationServer string = 'westeurope'

@description('Username for the admin account of the Virtual Machines')
<<<<<<< HEAD
param virtualMachine_adminUsername string = 'bob'
=======
param virtualMachine_AdminUsername string
>>>>>>> a0d753352a1da0ad4a3cdfd85f3902b00c9d51cf

@description('Password for the admin account of the Virtual Machines')
@secure()
param virtualMachine_AdminPassword string

@description('Password for the Virtual Machine Admin User')
param virtualMachine_Size string = 'Standard_D2s_v3'

@description('''True enables Accelerated Networking and False disabled it.  
Not all VM sizes support Accel Net (i.e. Standard_B2ms).  
I'd recommend Standard_D2s_v3 for a cheap VM that supports Accel Net.
''')
param acceleratedNetworking bool = true

<<<<<<< HEAD
=======
@description('Use this name to help differentiate between tests.')
param scenario_Name string

@maxValue(1000)
>>>>>>> a0d753352a1da0ad4a3cdfd85f3902b00c9d51cf
@description('Number of Client Virtual Machines to be used as the source of the traffic')
param numberOfClientVMs int = 1

@maxValue(1000)
@description('Number of Server Virtual Machines to be used as the destination of the traffic')
<<<<<<< HEAD
param numberOfServerVMs int = 1
=======
param numberOfServerVMs int

@description('Set to true if you want to use an Azure Firewall between client and server.')
param usingAzureFirewall bool = false
>>>>>>> a0d753352a1da0ad4a3cdfd85f3902b00c9d51cf

@description('''
Storage account name restrictions:
- Storage account names must be between 3 and 24 characters in length and may contain numbers and lowercase letters only.
- Your storage account name must be unique within Azure. No two storage accounts can have the same name.
''')
@minLength(3)
@maxLength(24)
<<<<<<< HEAD
param storageAccount_Name string

var storageAccountUnicornName = '${storageAccount_Name}${uniqueString(resourceGroup().id, 'storage')}'

@description('Duration to run test script for, in seconds')
param dur int = 300
=======
param storageAccount_Name string = 'stortemp${uniqueString(resourceGroup().id)}'
>>>>>>> a0d753352a1da0ad4a3cdfd85f3902b00c9d51cf

module virtualNetwork_Client '../../modules/Microsoft.Network/VirtualNetworkBasic.bicep' = {
  name: 'clientVNet'
  params: {
    // firstTwoOctetsOfVirtualNetworkPrefix: '10.100'
    virtualNetwork_AddressPrefix: '10.100.0.0/16'
    location: locationClient
    virtualNetwork_Name: 'Client_VNet'

  }
}

module virtualNetwork_Server '../../modules/Microsoft.Network/VirtualNetworkBasic.bicep' = {
  name: 'serverVNet'
  params: {
    // firstTwoOctetsOfVirtualNetworkPrefix: '10.101'
    virtualNetwork_AddressPrefix: '10.101.0.0/16'
    location: locationServer
    virtualNetwork_Name: 'Server_VNet'
  }
}
module clientToServerPeering '../../modules/Microsoft.Network/VirtualNetworkPeering.bicep' = {
  name: 'clientToServerPeering'
  params: {
    virtualNetwork_Source_Name: virtualNetwork_Client.outputs.virtualNetwork_Name
    virtualNetwork_Destination_Name: virtualNetwork_Server.outputs.virtualNetwork_Name
  }
}

module clientVM_Linux '../../modules/Microsoft.Compute/Ubuntu20/VirtualMachine.bicep' = [for i in range(0, numberOfClientVMs): {
  name: 'clientVM${i}'
  params: {
    acceleratedNetworking: acceleratedNetworking
    location: locationClient
    subnet_ID: virtualNetwork_Client.outputs.general_SubnetID
    virtualMachine_AdminPassword: virtualMachine_AdminPassword
    virtualMachine_AdminUsername: virtualMachine_AdminUsername
    virtualMachine_Name: 'ClientVM${i}'
    virtualMachine_Size: virtualMachine_Size
<<<<<<< HEAD
    virtualMachine_ScriptFileLocation: customScriptURL
    virtualMachine_ScriptFileName: 'client.sh'
    commandToExecute: './client.sh ${privateEndpoint_NIC.outputs.privateEndpoint_IPAddress} ${storageAccount.outputs.storageAccount_Name} ${storageAccount.outputs.storageAccountFileShare_Name} ${storageAccount.outputs.storageAccount_key0} ${dur}'
=======
    virtualMachine_ScriptFileLocation: 'https://raw.githubusercontent.com/jimgodden/Azure_Networking_Labs/main/scripts/'
    virtualMachine_ScriptFileName: 'conntestClient.sh'
    // Use the following for Private Link testing
    // commandToExecute: './conntestClient.sh ${privateEndpoint_NIC.outputs.privateEndpoint_IPAddress} ${scenario_Name} ${storageAccount.outputs.storageAccount_Name} ${storageAccount.outputs.storageAccountFileShare_Name} ${storageAccount.outputs.storageAccount_key0}'
    // Use the following for Load Balancer testing
    commandToExecute: './conntestClient.sh ${privateLink.outputs.internalLoadBalancer_FrontendIPAddress} ${scenario_Name} ${storageAccount.outputs.storageAccount_Name} ${storageAccount.outputs.storageAccountFileShare_Name} ${storageAccount.outputs.storageAccount_key0}'

>>>>>>> a0d753352a1da0ad4a3cdfd85f3902b00c9d51cf
  }
  dependsOn: [
    storageAccount
    client_StorageAccount_File_PrivateEndpoint
  ]
}]

module ServerVM_Linux '../../modules/Microsoft.Compute/Ubuntu20/VirtualMachine.bicep' = [for i in range(0, numberOfServerVMs): {
  name: 'serverVM${i}'
  params: {
    acceleratedNetworking: acceleratedNetworking
    location: locationServer
    subnet_ID: virtualNetwork_Server.outputs.general_SubnetID
    virtualMachine_AdminPassword: virtualMachine_AdminPassword
    virtualMachine_AdminUsername: virtualMachine_AdminUsername
    virtualMachine_Name: 'ServerVM${i}'
    virtualMachine_Size: virtualMachine_Size
    virtualMachine_ScriptFileLocation: customScriptURL
    virtualMachine_ScriptFileName: 'server.sh'
    commandToExecute: './server.sh ${virtualNetwork_Client.outputs.virtualNetwork_AddressPrefix} ${storageAccount.outputs.storageAccount_Name} ${storageAccount.outputs.storageAccountFileShare_Name} ${storageAccount.outputs.storageAccount_key0} ${dur}'
  }
  dependsOn: [
<<<<<<< HEAD
    storageAccount
  ]
}]
=======
    client_StorageAccount_File_PrivateEndpoint
  ]
} ]


module firewall '../../modules/Microsoft.Network/AzureFirewall.bicep' = if (usingAzureFirewall) {
  name: 'azfw'
  params: {
    azureFirewall_ManagementSubnet_ID: virtualNetwork_Client.outputs.azureFirewallManagement_SubnetID
    azureFirewall_Name: 'azfw'
    azureFirewall_SKU: 'Basic'
    azureFirewall_Subnet_ID: virtualNetwork_Client.outputs.azureFirewall_SubnetID
    azureFirewallPolicy_Name: 'azfw_policy'
    location: locationClient
  }
}

module udrToAzFW_Hub '../../modules/Microsoft.Network/RouteTable.bicep' = if (usingAzureFirewall) {
  name: 'udrToAzFW_Hub'
  params: {
    addressPrefix: '10.101.0.0/24'
    nextHopType: 'VirtualAppliance'
    routeTable_Name: virtualNetwork_Client.outputs.routeTable_Name
    routeTableRoute_Name: 'toAzFW'
    nextHopIpAddress: firewall.outputs.azureFirewall_PrivateIPAddress
  }
}

module udrToAzFW_Server '../../modules/Microsoft.Network/RouteTable.bicep' = if (usingAzureFirewall) {
  name: 'udrToAzFW_Server'
  params: {
    addressPrefix: '10.100.0.0/24'
    nextHopType: 'VirtualAppliance'
    routeTable_Name: virtualNetwork_Server.outputs.routeTable_Name
    routeTableRoute_Name: 'toAzFW'
    nextHopIpAddress: firewall.outputs.azureFirewall_PrivateIPAddress
  }
}

module clientBastion '../../modules/Microsoft.Network/Bastion.bicep' = {
  name: 'clientBastion'
  params: {
    bastion_SubnetID: virtualNetwork_Client.outputs.bastion_SubnetID
    location: locationClient
  }
}
>>>>>>> a0d753352a1da0ad4a3cdfd85f3902b00c9d51cf

module storageAccount '../../modules/Microsoft.Storage/StorageAccount.bicep' = {
  name: 'storageAccount'
  params: {
    location: locationClient
<<<<<<< HEAD
    privateDNSZoneLinkedVnetIDList: [ virtualNetwork_Client.outputs.virtualNetwork_ID, virtualNetwork_Server.outputs.virtualNetwork_ID ]
    privateDNSZoneLinkedVnetNamesList: [ virtualNetwork_Client.outputs.virtualNetwork_Name, virtualNetwork_Server.outputs.virtualNetwork_Name ]
    privateEndpoint_SubnetID: [ virtualNetwork_Client.outputs.general_SubnetID, virtualNetwork_Server.outputs.general_SubnetID ]
    privateEndpoint_VirtualNetwork_Name: [ virtualNetwork_Client.outputs.virtualNetwork_Name, virtualNetwork_Server.outputs.virtualNetwork_Name ]
    privateEndpoints_Blob_Name: 'blob_pe'
    privateEndpoints_File_Name: 'fileshare_pe'
    usingFilePrivateEndpoints: true
    usingBlobPrivateEndpoints: true
    storageAccount_Name: storageAccountUnicornName
  }
}

=======
    storageAccount_Name: storageAccount_Name
  }
}

module client_StorageAccount_File_PrivateEndpoint '../../modules/Microsoft.Network/PrivateEndpoint.bicep' = {
  name: 'client_StorageAccount_File_PrivateEndpoint'
  params: {
    fqdn: '${storageAccount_Name}.file.${environment().suffixes.storage}'
    groupID: 'file'
    location: locationClient
    privateDNSZone_Name: 'privatelink.file.${environment().suffixes.storage}'
    privateEndpoint_Name: '${storageAccount_Name}_file_pe'
    privateEndpoint_SubnetID: virtualNetwork_Client.outputs.privateEndpoint_SubnetID
    privateLinkServiceId: storageAccount.outputs.storageAccount_ID
    virtualNetwork_IDs: [
      virtualNetwork_Client.outputs.virtualNetwork_ID
      virtualNetwork_Server.outputs.virtualNetwork_ID
    ]  
  }
}

>>>>>>> a0d753352a1da0ad4a3cdfd85f3902b00c9d51cf
module privateLink '../../modules/Microsoft.Network/PrivateLink.bicep' = {
  name: 'privatelink'
  params: {
    acceleratedNetworking: acceleratedNetworking
    internalLoadBalancer_SubnetID: virtualNetwork_Server.outputs.general_SubnetID
    location: locationServer
    networkInterface_IPConfig_Names: [for i in range(0, numberOfServerVMs): ServerVM_Linux[i].outputs.networkInterface_IPConfig0_Name]
    networkInterface_Names: [for i in range(0, numberOfServerVMs): ServerVM_Linux[i].outputs.networkInterface_Name]
    networkInterface_SubnetID: virtualNetwork_Server.outputs.general_SubnetID
    privateEndpoint_SubnetID: virtualNetwork_Client.outputs.general_SubnetID
    privateLink_SubnetID: virtualNetwork_Server.outputs.general_SubnetID
    tcpPort: 5001
  }
}

module privateEndpoint_NIC '../../modules/Microsoft.Network/PrivateEndpointNetworkInterface.bicep' = {
  name: 'pe_NIC'
  params: {
    existing_PrivateEndpoint_NetworkInterface_Name: privateLink.outputs.privateEndpoint_NetworkInterface_Name
  }
}
<<<<<<< HEAD
=======


>>>>>>> a0d753352a1da0ad4a3cdfd85f3902b00c9d51cf
