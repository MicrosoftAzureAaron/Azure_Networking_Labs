@description('Azure Datacenter location for the Hub and Spoke A resources')
param locationA string = resourceGroup().location

@description('''
Azure Datacenter location for the Spoke B resources.  
Use the same region as locationA if you do not want to test multi-region
''')
param locationB string = locationA

@description('Azure Datacenter location for the "OnPrem" resources')
param locationOnPrem string = locationA

@description('Username for the admin account of the Virtual Machines')
param virtualMachine_AdminUsername string

@description('Password for the admin account of the Virtual Machines')
@secure()
param virtualMachine_AdminPassword string

@description('Password for the Virtual Machine Admin User')
param virtualMachine_Size string = 'Standard_B2ms' // 'Standard_D2s_v3' // 'Standard_D16lds_v5'

param virtualMachine_ScriptFileLocation string = 'https://raw.githubusercontent.com/jimgodden/Azure_Networking_Labs/PrivateLinkDNSTesting/scripts/'

@description('''True enables Accelerated Networking and False disabled it.  
Not all VM sizes support Accel Net (i.e. Standard_B2ms).  
I'd recommend Standard_D2s_v3 for a cheap VM that supports Accel Net.
''')
param acceleratedNetworking bool = false

@description('''
Storage account name restrictions:
- Storage account names must be between 3 and 24 characters in length and may contain numbers and lowercase letters only.
- Your storage account name must be unique within Azure. No two storage accounts can have the same name.
''')
@minLength(3)
@maxLength(24)
param storageAccount_Name string = 'storagepl${uniqueString(resourceGroup().id)}'

@description('Set this to true if you want to use an Azure Firewall in the Hub Virtual Network.')
param usingAzureFirewall bool = true

@description('VPN Shared Key used for authenticating VPN connections')
@secure()
param vpn_SharedKey string

@description('''DNS Zone to be hosted On Prem and with a forwarding rule on the DNS Private Resolver.
Must end with a period (.)
Example:
contoso.com.''')
param onpremResolvableDomainName string = 'contoso.com.'


module virtualNetwork_Hub '../../modules/Microsoft.Network/VirtualNetworkHub.bicep' = {
  name: 'hubVNet'
  params: {
    firstTwoOctetsOfVirtualNetworkPrefix: '10.0' // changing this can break commandToExecute on OnPremVM_WinDNS
    dnsServers: [for i in range(0, 2): OnPremVM_WinDNS[i].outputs.networkInterface_PrivateIPAddress]
    location: locationA
    virtualNetwork_Name: 'vnet_hub'
  }
}

module virtualNetwork_Spoke_A '../../modules/Microsoft.Network/VirtualNetworkSpoke.bicep' = {
  name: 'spokeAVNet'
  params: {
    firstTwoOctetsOfVirtualNetworkPrefix: '10.1'
    dnsServers: [for i in range(0, 2): OnPremVM_WinDNS[i].outputs.networkInterface_PrivateIPAddress]
    location: locationA
    virtualNetwork_Name: 'vnet_SpokeA'
  }
}

module hubToSpokeAPeering '../../modules/Microsoft.Network/VirtualNetworkPeering.bicep' = {
  name: 'hubToSpokeAPeering'
  params: {
    virtualNetwork_Source_Name: virtualNetwork_Hub.outputs.virtualNetwork_Name
    virtualNetwork_Destination_Name: virtualNetwork_Spoke_A.outputs.virtualNetwork_Name
  }
}

module virtualNetwork_Spoke_B '../../modules/Microsoft.Network/VirtualNetworkSpoke.bicep' = {
  name: 'spokeBVNet'
  params: {
    firstTwoOctetsOfVirtualNetworkPrefix: '10.2'
    dnsServers: [for i in range(0, 2): OnPremVM_WinDNS[i].outputs.networkInterface_PrivateIPAddress]
    location: locationB
    virtualNetwork_Name: 'VNet_SpokeB'
  }
}
module hubToSpokeBPeering '../../modules/Microsoft.Network/VirtualNetworkPeering.bicep' = {
  name: 'hubToSpokeBPeering'
  params: {
    virtualNetwork_Source_Name: virtualNetwork_Hub.outputs.virtualNetwork_Name
    virtualNetwork_Destination_Name: virtualNetwork_Spoke_B.outputs.virtualNetwork_Name
  }
}

module hubVM_Windows '../../modules/Microsoft.Compute/WindowsServer2022/VirtualMachine.bicep' = {
  name: 'hubVM_Windows'
  params: {
    acceleratedNetworking: acceleratedNetworking
    location: locationA
    subnet_ID: virtualNetwork_Hub.outputs.general_SubnetID
    virtualMachine_AdminPassword: virtualMachine_AdminPassword
    virtualMachine_AdminUsername: virtualMachine_AdminUsername
    virtualMachine_Name: 'hubVM-Windows'
    virtualMachine_Size: virtualMachine_Size
    virtualMachine_ScriptFileLocation: virtualMachine_ScriptFileLocation
    virtualMachine_ScriptFileName: 'WinServ2022_General_InitScript.ps1'
  }
  dependsOn: [
    Hub_to_OnPrem_conn
    OnPrem_to_Hub_conn
  ]
}

module spokeAVM_Windows '../../modules/Microsoft.Compute/WindowsServer2022/VirtualMachine.bicep' = {
  name: 'spokeAVM_Windows'
  params: {
    acceleratedNetworking: acceleratedNetworking
    location: locationA
    subnet_ID: virtualNetwork_Spoke_A.outputs.general_SubnetID
    virtualMachine_AdminPassword: virtualMachine_AdminPassword
    virtualMachine_AdminUsername: virtualMachine_AdminUsername
    virtualMachine_Name: 'spokeA-WinVM'
    virtualMachine_Size: virtualMachine_Size
    virtualMachine_ScriptFileLocation: virtualMachine_ScriptFileLocation
    virtualMachine_ScriptFileName: 'WinServ2022_General_InitScript.ps1'
  }
  dependsOn: [
    Hub_to_OnPrem_conn
    OnPrem_to_Hub_conn
  ]
}

module spokeBVM_Windows '../../modules/Microsoft.Compute/WindowsServer2022/VirtualMachine.bicep' = {
  name: 'spokeBVM_Windows'
  params: {
    acceleratedNetworking: acceleratedNetworking
    location: locationB
    subnet_ID: virtualNetwork_Spoke_B.outputs.general_SubnetID
    virtualMachine_AdminPassword: virtualMachine_AdminPassword
    virtualMachine_AdminUsername: virtualMachine_AdminUsername
    virtualMachine_Name: 'spokeB-WinVM'
    virtualMachine_Size: virtualMachine_Size
    virtualMachine_ScriptFileLocation: virtualMachine_ScriptFileLocation
    virtualMachine_ScriptFileName: 'WinServ2022_WebServer_InitScript.ps1'
  }
  dependsOn: [
    Hub_to_OnPrem_conn
    OnPrem_to_Hub_conn
  ]
}

module privateLink '../../modules/Microsoft.Network/PrivateLink.bicep' = {
  name: 'privateLink'
  params: {
    acceleratedNetworking: acceleratedNetworking
    internalLoadBalancer_SubnetID: virtualNetwork_Spoke_B.outputs.general_SubnetID
    location: locationB
    networkInterface_IPConfig_Names: [spokeBVM_Windows.outputs.networkInterface_IPConfig0_Name]
    networkInterface_Names: [spokeBVM_Windows.outputs.networkInterface_Name]
    networkInterface_SubnetID: virtualNetwork_Spoke_B.outputs.general_SubnetID
    privateEndpoint_SubnetID: virtualNetwork_Spoke_B.outputs.privateEndpoint_SubnetID
    privateLink_SubnetID: virtualNetwork_Spoke_B.outputs.privateLinkService_SubnetID
  }
}

module storageAccount '../../modules/Microsoft.Storage/StorageAccount.bicep' = {
  name: 'storageAccount'
  params: {
    location: locationB
    privateEndpoints_File_Name: '${storageAccount_Name}_file_pe'
    privateEndpoints_Blob_Name: '${storageAccount_Name}_blob_pe'
    storageAccount_Name: storageAccount_Name
    privateEndpoint_SubnetID: [virtualNetwork_Spoke_A.outputs.privateEndpoint_SubnetID]
    privateDNSZoneLinkedVnetIDList: [virtualNetwork_Hub.outputs.virtualNetwork_ID, virtualNetwork_Spoke_A.outputs.virtualNetwork_ID, virtualNetwork_Spoke_B.outputs.virtualNetwork_ID]
    privateDNSZoneLinkedVnetNamesList: [virtualNetwork_Hub.outputs.virtualNetwork_Name, virtualNetwork_Spoke_A.outputs.virtualNetwork_Name, virtualNetwork_Spoke_B.outputs.virtualNetwork_Name]
    privateEndpoint_VirtualNetwork_Name: [virtualNetwork_Spoke_A.outputs.virtualNetwork_Name]
  }
  // Added this dependancy so that the VMs can reach out to my other Storage Account to download a file
  // Since my other Storage Account has a private endpoint, the connectivity fails because I don't have an
  //  entry in my Private DNS Zone for the other Storage Account.
  dependsOn: [
    hubVM_Windows
    spokeAVM_Windows
    spokeBVM_Windows
  ]
}

module azureFirewall '../../modules/Microsoft.Network/AzureFirewall.bicep' = if (usingAzureFirewall) {
  name: 'hubAzureFirewall'
  params: {
    azureFirewall_ManagementSubnet_ID: virtualNetwork_Hub.outputs.azureFirewallManagement_SubnetID
    azureFirewall_Name: 'hubAzFW'
    azureFirewall_SKU: 'Basic'
    azureFirewall_Subnet_ID: virtualNetwork_Hub.outputs.azureFirewall_SubnetID
    azureFirewallPolicy_Name: 'hubAzFW_Policy'
    location: locationA
  }
  dependsOn: [
    Hub_to_OnPrem_conn
    OnPrem_to_Hub_conn
  ]
}

module hubBastion '../../modules/Microsoft.Network/Bastion.bicep' = {
  name: 'hubBastion'
  params: {
    bastion_SubnetID: virtualNetwork_Hub.outputs.bastion_SubnetID
    location: locationA
  }
}

module virtualNetwork_OnPremHub '../../modules/Microsoft.Network/VirtualNetworkHub.bicep' = {
  name: 'OnPremVNET'
  params: {
    firstTwoOctetsOfVirtualNetworkPrefix: '10.100'
    location: locationOnPrem
    virtualNetwork_Name: 'vnet_OnPrem'
  }
}

module OnPremVM_WinDNS '../../modules/Microsoft.Compute/WindowsServer2022/VirtualMachine.bicep' = [for i in range(0, 2) : {
  name: 'OnPremWinDNS${i}'
  params: {
    acceleratedNetworking: acceleratedNetworking
    location: locationOnPrem
    subnet_ID: virtualNetwork_OnPremHub.outputs.general_SubnetID
    virtualMachine_AdminPassword: virtualMachine_AdminPassword
    virtualMachine_AdminUsername: virtualMachine_AdminUsername
    virtualMachine_Name: 'OnPremWinDNS${i}'
    virtualMachine_Size: virtualMachine_Size
    virtualMachine_ScriptFileLocation: virtualMachine_ScriptFileLocation
    virtualMachine_ScriptFileName: 'WinServ2022_DNS_InitScript.ps1'
    // The command below has two parameters that are unavoidably hardcoded.  The Private DNS Zone is for blob storage and the IP Address is for the inbound endpoint of the private dns resolver.
    commandToExecute: 'powershell.exe -ExecutionPolicy Unrestricted -File WinServ2022_DNS_InitScript.ps1 -SampleDNSZoneName ${onpremResolvableDomainName} -SampleHostName "a" -SampleARecord "172.16.0.1" -PrivateDNSZone "privatelink.blob.core.windows.net" -ConditionalForwarderIPAddress "10.0.9.4"'
  }
} ]

module virtualNetworkGateway_OnPrem '../../modules/Microsoft.Network/VirtualNetworkGateway.bicep' = {
  name: 'OnPremVirtualNetworkGateway'
  params: {
    location: locationOnPrem
    virtualNetworkGateway_ASN: 65000
    virtualNetworkGateway_Name: 'OnPremVNG'
    virtualNetworkGateway_Subnet_ResourceID: virtualNetwork_OnPremHub.outputs.gateway_SubnetID
  }
}

module OnPrem_to_Hub_conn '../../modules/Microsoft.Network/Connection_and_LocalNetworkGateway.bicep' = {
  name: 'OnPrem_to_Hub_conn'
  params: {
    location: locationOnPrem
    virtualNetworkGateway_ID: virtualNetworkGateway_OnPrem.outputs.virtualNetworkGateway_ResourceID
    vpn_Destination_ASN: virtualNetworkGateway_Hub.outputs.virtualNetworkGateway_ASN
    vpn_Destination_BGPIPAddress: virtualNetworkGateway_Hub.outputs.virtualNetworkGateway_BGPAddress
    vpn_Destination_Name: virtualNetworkGateway_Hub.outputs.virtualNetworkGateway_Name
    vpn_Destination_PublicIPAddress: virtualNetworkGateway_Hub.outputs.virtualNetworkGateway_PublicIPAddress
    vpn_SharedKey: vpn_SharedKey
  }
}

module virtualNetworkGateway_Hub '../../modules/Microsoft.Network/VirtualNetworkGateway.bicep' = {
  name: 'HubVirtualNetworkGateway'
  params: {
    location: locationA
    virtualNetworkGateway_ASN: 65001
    virtualNetworkGateway_Name: 'HubVNG'
    virtualNetworkGateway_Subnet_ResourceID: virtualNetwork_Hub.outputs.gateway_SubnetID
  }
}

module Hub_to_OnPrem_conn '../../modules/Microsoft.Network/Connection_and_LocalNetworkGateway.bicep' = {
  name: 'Hub_to_OnPrem_conn'
  params: {
    location: locationOnPrem
    virtualNetworkGateway_ID: virtualNetworkGateway_Hub.outputs.virtualNetworkGateway_ResourceID
    vpn_Destination_ASN: virtualNetworkGateway_OnPrem.outputs.virtualNetworkGateway_ASN
    vpn_Destination_BGPIPAddress: virtualNetworkGateway_OnPrem.outputs.virtualNetworkGateway_BGPAddress
    vpn_Destination_Name: virtualNetworkGateway_OnPrem.outputs.virtualNetworkGateway_Name
    vpn_Destination_PublicIPAddress: virtualNetworkGateway_OnPrem.outputs.virtualNetworkGateway_PublicIPAddress
    vpn_SharedKey: vpn_SharedKey
  }
}

module dnsPrivateResolver '../../modules/Microsoft.Network/PrivateDNSResolver.bicep' = {
  name: 'dnsPrivateResolver'
  params: {
    dnsPrivateResolver_Inbound_SubnetID: virtualNetwork_Hub.outputs.privateResolver_Inbound_SubnetID
    dnsPrivateResolver_Outbound_SubnetID: virtualNetwork_Hub.outputs.privateResolver_Outbound_SubnetID
    domainName: onpremResolvableDomainName
    forwardingRule_Name: '${join(split(onpremResolvableDomainName, '.'), '')}_ForwardingRule' // Removes the periods from the domain name.
    location: locationA
    targetDNSServers: [for i in range(0, 2): {
      port: 53
      ipaddress: OnPremVM_WinDNS[i].outputs.networkInterface_PrivateIPAddress
    }]
    virtualNetwork_ID: virtualNetwork_Hub.outputs.virtualNetwork_ID
  }
}
