@description('Azure Datacenter location for the Hub and Server A resources')
param locationClient string = 'westeurope'

@description('''
Azure Datacenter location for the Server B resources.  
Use the same region as locationClient if you do not want to test multi-region
''')
param locationServer string = 'westeurope'

@description('Username for the admin account of the Virtual Machines')
param virtualMachine_adminUsername string

@description('Password for the admin account of the Virtual Machines')
@secure()
param virtualMachine_adminPassword string

@description('Password for the Virtual Machine Admin User')
param virtualMachine_Size string = 'Standard_D2s_v3'

@description('''True enables Accelerated Networking and False disabled it.  
Not all VM sizes support Accel Net (i.e. Standard_B2ms).  
I'd recommend Standard_D2s_v3 for a cheap VM that supports Accel Net.
''')
param acceleratedNetworking bool = true

param scenario_Name string

// param storageAccount_ID string

param numberOfServerVMs int

// param usingAzureFirewall bool = true

@description('''
Storage account name restrictions:
- Storage account names must be between 3 and 24 characters in length and may contain numbers and lowercase letters only.
- Your storage account name must be unique within Azure. No two storage accounts can have the same name.
''')
@minLength(3)
@maxLength(24)
param storageAccount_Name string

// param aaron bool = false



module virtualNetwork_Client '../../modules/Microsoft.Network/VirtualNetworkHub.bicep' = {
  name: 'clientVNet'
  params: {
    firstTwoOctetsOfVirtualNetworkPrefix: '10.100'
    location: locationClient
    virtualNetwork_Name: 'Client_VNet'
  }
}

module virtualNetwork_Server '../../modules/Microsoft.Network/VirtualNetworkSpoke.bicep' = {
  name: 'serverVNet'
  params: {
    firstTwoOctetsOfVirtualNetworkPrefix: '10.101'
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

module clientVM_Linux '../../modules/Microsoft.Compute/Ubuntu20/VirtualMachine.bicep' = {
  name: 'clientVM'
  params: {
    acceleratedNetworking: acceleratedNetworking
    location: locationClient
    subnet_ID: virtualNetwork_Client.outputs.general_SubnetID
    virtualMachine_AdminPassword: virtualMachine_adminPassword
    virtualMachine_AdminUsername: virtualMachine_adminUsername
    virtualMachine_Name: 'clientVM-Linux'
    virtualMachine_Size: virtualMachine_Size
    virtualMachine_ScriptFileLocation: 'https://raw.githubusercontent.com/jimgodden/Azure_Networking_Labs/main/scripts/'
    virtualMachine_ScriptFileName: 'conntestClient.sh'
    commandToExecute: './conntestClient.sh ${privateEndpoint_NIC.outputs.privateEndpoint_IPAddress} ${scenario_Name} ${storageAccount.outputs.storageAccount_Name} ${storageAccount.outputs.storageAccountFileShare_Name} ${storageAccount.outputs.storageAccount_key0}'
  }
  dependsOn: [
    // filesharePrivateEndpoints
    // blobPrivateEndpoints
    storageAccount
  ]
}

module ServerVM_Linux '../../modules/Microsoft.Compute/Ubuntu20/VirtualMachine.bicep' = [ for i in range(0, numberOfServerVMs): {
  name: 'serverVM${i}'
  params: {
    acceleratedNetworking: acceleratedNetworking
    location: locationServer
    subnet_ID: virtualNetwork_Server.outputs.general_SubnetID
    virtualMachine_AdminPassword: virtualMachine_adminPassword
    virtualMachine_AdminUsername: virtualMachine_adminUsername
    virtualMachine_Name: 'ServerVM${i}'
    virtualMachine_Size: virtualMachine_Size
    virtualMachine_ScriptFileLocation: 'https://raw.githubusercontent.com/jimgodden/Azure_Networking_Labs/main/scripts/'
    virtualMachine_ScriptFileName: 'conntestServer.sh'
    commandToExecute: './conntestServer.sh ${scenario_Name} ${storageAccount.outputs.storageAccount_Name} ${storageAccount.outputs.storageAccountFileShare_Name} ${storageAccount.outputs.storageAccount_key0}'
  }
  dependsOn: [
    // filesharePrivateEndpoints
    // blobPrivateEndpoints
    storageAccount
  ]
} ]


// module firewall '../../modules/Microsoft.Network/AzureFirewall.bicep' = if (usingAzureFirewall) {
//   name: 'azfw'
//   params: {
//     azureFirewall_ManagementSubnet_ID: virtualNetwork_Hub.outputs.azureFirewallManagement_SubnetID
//     azureFirewall_Name: 'azfw'
//     azureFirewall_SKU: 'Basic'
//     azureFirewall_Subnet_ID: virtualNetwork_Hub.outputs.azureFirewall_SubnetID
//     azureFirewallPolicy_Name: 'azfw_policy'
//     location: locationClient
//   }
// }

// module udrToAzFW_Hub '../../modules/Microsoft.Network/RouteTable.bicep' = if (usingAzureFirewall) {
//   name: 'udrToAzFW_Hub'
//   params: {
//     addressPrefix: '10.101.0.0/24'
//     nextHopType: 'VirtualAppliance'
//     routeTable_Name: virtualNetwork_Hub.outputs.routeTable_Name
//     routeTableRoute_Name: 'toAzFW'
//     nextHopIpAddress: firewall.outputs.azureFirewall_PrivateIPAddress
//   }
// }

// module udrToAzFW_Server '../../modules/Microsoft.Network/RouteTable.bicep' = if (usingAzureFirewall) {
//   name: 'udrToAzFW_Server'
//   params: {
//     addressPrefix: '10.100.0.0/24'
//     nextHopType: 'VirtualAppliance'
//     routeTable_Name: virtualNetwork_Server.outputs.routeTable_Name
//     routeTableRoute_Name: 'toAzFW'
//     nextHopIpAddress: firewall.outputs.azureFirewall_PrivateIPAddress
//   }
// }

module clientBastion '../../modules/Microsoft.Network/Bastion.bicep' = {
  name: 'clientBastion'
  params: {
    bastion_SubnetID: virtualNetwork_Client.outputs.bastion_SubnetID
    location: locationClient
  }
}

module storageAccount '../../modules/Microsoft.Storage/StorageAccount.bicep' = {
  name: 'storageAccount'
  params: {
    location: locationClient
    privateDNSZoneLinkedVnetIDList: [virtualNetwork_Client.outputs.virtualNetwork_ID, virtualNetwork_Server.outputs.virtualNetwork_ID]
    privateDNSZoneLinkedVnetNamesList: [virtualNetwork_Client.outputs.virtualNetwork_Name, virtualNetwork_Server.outputs.virtualNetwork_Name]
    privateEndpoint_SubnetID: [virtualNetwork_Client.outputs.privateEndpoint_SubnetID, virtualNetwork_Server.outputs.privateEndpoint_SubnetID]
    privateEndpoint_VirtualNetwork_Name: [virtualNetwork_Client.outputs.virtualNetwork_Name, virtualNetwork_Server.outputs.virtualNetwork_Name]
    privateEndpoints_Blob_Name: 'blob_pe'
    privateEndpoints_File_Name: 'fileshare_pe'
    usingFilePrivateEndpoints: true
    usingBlobPrivateEndpoints: true
    storageAccount_Name: storageAccount_Name
  }
}

// module ilb '../../modules/Microsoft.Network/InternalLoadBalancer.bicep' = {
  //   name: 'ilb'
  //   params: {
  //     internalLoadBalancer_SubnetID: virtualNetwork_Server.outputs.general_SubnetID
  //     location: locationServer
  //     networkInterface_IPConfig_Name: [ServerVM_Linux1.outputs.networkInterface_IPConfig0_Name, ServerVM_Linux2.outputs.networkInterface_IPConfig0_Name ]
  //     networkInterface_Name: [ServerVM_Linux1.outputs.networkInterface_Name, ServerVM_Linux2.outputs.networkInterface_Name]
  //     networkInterface_SubnetID: [virtualNetwork_Server.outputs.general_SubnetID, virtualNetwork_Server.outputs.general_SubnetID]
  //     tcpPort: 5001
  //     enableTcpReset: true
  //   }
  //   dependsOn: [
  //     clientBastion
  //   ]
  // }

module privateLink '../../modules/Microsoft.Network/PrivateLink.bicep' = {
  name: 'privatelink'
  params: {
    acceleratedNetworking: acceleratedNetworking
    internalLoadBalancer_SubnetID: virtualNetwork_Server.outputs.general_SubnetID
    location: locationServer
    networkInterface_IPConfig_Names: [for i in range(0, numberOfServerVMs): ServerVM_Linux[i].outputs.networkInterface_IPConfig0_Name]
    networkInterface_Names: [for i in range(0, numberOfServerVMs): ServerVM_Linux[i].outputs.networkInterface_Name]
    networkInterface_SubnetID: virtualNetwork_Server.outputs.general_SubnetID
    privateEndpoint_SubnetID: virtualNetwork_Client.outputs.privateEndpoint_SubnetID
    privateLink_SubnetID: virtualNetwork_Server.outputs.privateLinkService_SubnetID
    tcpPort: 5001
  }
}



module privateEndpoint_NIC '../../modules/Microsoft.Network/PrivateEndpointNetworkInterface.bicep' = {
  name: 'pe_NIC'
  params: {
    existing_PrivateEndpoint_NetworkInterface_Name: privateLink.outputs.privateEndpoint_NetworkInterface_Name
  }
}

// module filesharePrivateEndpoints '../../modules/Microsoft.Network/PrivateEndpoint.bicep' = {
//   name: 'filesharePE'
//   params: {
//     fqdn: '${last(split(storageAccount_ID, '/'))}.file.core.windows.net'
//     groupID: 'file'
//     location: locationClient
//     privateDNSZone_Name: 'privatelink.file.core.windows.net'
//     privateEndpoint_Name: 'file_pe'
//     privateEndpoint_SubnetID: virtualNetwork_Client.outputs.privateEndpoint_SubnetID
//     privateLinkServiceId: storageAccount_ID
//     virtualNetwork_IDs: [virtualNetwork_Client.outputs.virtualNetwork_ID, virtualNetwork_Server.outputs.virtualNetwork_ID]
//   }
// }

// module blobPrivateEndpoints '../../modules/Microsoft.Network/PrivateEndpoint.bicep' = {
//   name: 'blobPE'
//   params: {
//     fqdn: '${last(split(storageAccount_ID, '/'))}.blob.core.windows.net'
//     groupID: 'blob'
//     location: locationClient
//     privateDNSZone_Name: 'privatelink.blob.core.windows.net'
//     privateEndpoint_Name: 'blob_pe'
//     privateEndpoint_SubnetID: virtualNetwork_Client.outputs.privateEndpoint_SubnetID
//     privateLinkServiceId: storageAccount_ID
//     virtualNetwork_IDs: [virtualNetwork_Client.outputs.virtualNetwork_ID, virtualNetwork_Server.outputs.virtualNetwork_ID]
//   }
// }


