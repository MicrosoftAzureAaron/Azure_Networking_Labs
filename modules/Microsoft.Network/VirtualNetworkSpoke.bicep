@description('Azure Datacenter that the resource is deployed to')
param location string

@description('Name of the Virtual Network')
param virtualNetwork_Name string

// @description('Address Prefix of the Virtual Network')
// param virtualNetwork_AddressPrefix string = '${firstTwoOctetsOfVirtualNetworkPrefix}.0.0/16'

@description('''An Array of Custom DNS Server IP Addresses.  Azure Wireserver will be used if left as an empty array [].
Example:
[10.0.0.4, 10.0.0.5]
''')
param dnsServers array = []

param virtualNetwork_AddressPrefix string

var subnet_AddressRangeCIDRs = [for i in range(0, 255): cidrSubnet(virtualNetwork_AddressPrefix, 24, i) ]

var subnet_Names = [
  'General'
  'PrivateEndpoints'
  'PrivateLinkService'
  'ApplicationGatewaySubnet'
  'AppServiceSubnet'
]

@description('Name of the General Network Security Group')
param networkSecurityGroup_Default_Name string = '${virtualNetwork_Name}_NSG_General'

@description('Name of the General Route Table')
param routeTable_Name string = '${virtualNetwork_Name}_RT_General'

// @description('''First two octects of the Virtual Network address prefix
// Example: for a network address of '10.0.0.0/16' you would enter '10.0' here''')
// param firstTwoOctetsOfVirtualNetworkPrefix string

// // Subnets
// @description('Name of the General Subnet for any other resources')
// param subnet_General_Name string = 'General'

// @description('Address Prefix of the General Subnet')
// param subnet_General_AddressPrefix string = '${firstTwoOctetsOfVirtualNetworkPrefix}.0.0/24'

// @description('Name of the PrivateEndpoint Subnet')
// param subnet_PrivateEndpoints_Name string = 'PrivateEndpoints'

// @description('Address Prefix of the PrivateEndpoint Subnet')
// param subnet_PrivateEndpoints_AddressPrefix string = '${firstTwoOctetsOfVirtualNetworkPrefix}.1.0/24'

// @description('Name of the PrivateEndpoint Subnet')
// param subnet_PrivateLinkService_Name string = 'PrivateLinkService'

// @description('Address Prefix of the PrivateEndpoint Subnet')
// param subnet_PrivateLinkService_AddressPrefix string = '${firstTwoOctetsOfVirtualNetworkPrefix}.2.0/24'

// @description('Name of the ApplicationGateway Subnet')
// param subnet_ApplicationGatewaySubnet_Name string = 'ApplicationGatewaySubnet'

// @description('Address Prefix of the ApplicationGateway Subnet')
// // Any changes to this value need to be replicated to the output applicationGatewayPrivateIP
// param subnet_ApplicationGatewaySubnet_AddressPrefix string = '${firstTwoOctetsOfVirtualNetworkPrefix}.3.0/24'

// @description('Name of the AppService Subnet')
// param subnet_AppServiceSubnet_Name string = 'AppServiceSubnet'

// @description('Address Prefix of the AppService Subnet')
// param subnet_AppServiceSubnet_AddressPrefix string = '${firstTwoOctetsOfVirtualNetworkPrefix}.4.0/24'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-09-01' = {
  name: virtualNetwork_Name
  location: location
  properties: {
    dhcpOptions: {
      dnsServers: dnsServers
    }
    addressSpace: {
      addressPrefixes: [
        virtualNetwork_AddressPrefix
      ]
    }
    subnets: [
      {
        name: subnet_Names[0]
        properties: {
          addressPrefix: subnet_AddressRangeCIDRs[0]
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
          routeTable: {
            id: routeTable.id
          }
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: subnet_Names[1]
        properties: {
          addressPrefix: subnet_AddressRangeCIDRs[1]
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
          routeTable: {
            id: routeTable.id
          }
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: subnet_Names[2]
        properties: {
          addressPrefix: subnet_AddressRangeCIDRs[2]
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
          routeTable: {
            id: routeTable.id
          }
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled' // This has to be disabled for Private Link Service to be used in the subnet
        }
      }
      {
        name: subnet_Names[3]
        properties: {
          addressPrefix: subnet_AddressRangeCIDRs[3]
          networkSecurityGroup: {
            id: networkSecurityGroup_ApplicationGateway.id
          }
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: subnet_Names[4]
        properties: {
          addressPrefix: subnet_AddressRangeCIDRs[4]
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
          delegations: [
            {
              name: 'delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverfarms'
              }
              type: 'Microsoft.Network/virtualNetworks/subnets/delegations'
            }
          ]
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
    enableDdosProtection: false
  }
}

resource routeTable 'Microsoft.Network/routeTables@2023-02-01' = {
  name: routeTable_Name
  location: location
  properties: {
    disableBgpRoutePropagation: false
  }
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-09-01' = {
  name: networkSecurityGroup_Default_Name
  location: location
  properties: {}
}

resource networkSecurityGroup_ApplicationGateway 'Microsoft.Network/networkSecurityGroups@2022-11-01' = {
  name: '${virtualNetwork_Name}_networkSecurityGroup_ApplicationGateway'
  location: location
  properties: {
    securityRules: []
  }
}

resource networkSecurityGroup_ApplicationGateway_AppGWSpecificRule 'Microsoft.Network/networkSecurityGroups/securityRules@2022-11-01' = {
  parent: networkSecurityGroup_ApplicationGateway
  name: 'AllowGatewayManager'
  properties: {
    description: 'Allow GatewayManager'
    protocol: '*'
    sourcePortRange: '*'
    destinationPortRange: '65200-65535'
    sourceAddressPrefix: 'GatewayManager'
    destinationAddressPrefix: '*'
    access: 'Allow'
    priority: 1000
    direction: 'Inbound'
    sourcePortRanges: []
    destinationPortRanges: []
    sourceAddressPrefixes: []
    destinationAddressPrefixes: []
  }
}

// resource networkSecurityGroupRule 'Microsoft.Network/networkSecurityGroups/securityRules@2022-09-01' = {
//   parent: networkSecurityGroup
//   name: networkSecurityGroup_Default_RuleName
//   properties: {
//     description: 'test'
//     protocol: '*'
//     sourcePortRange: '*'
//     destinationPortRange: '8080'
//     sourceAddressPrefix: '10.0.0.1/32'
//     destinationAddressPrefix: '*'
//     access: 'Allow'
//     priority: int(networkSecurityGroup_Default_RulePriority)
//     direction: 'Inbound'
//     sourcePortRanges: []
//     destinationPortRanges: []
//     sourceAddressPrefixes: []
//     destinationAddressPrefixes: []
//   }
// }

output general_SubnetID string = virtualNetwork.properties.subnets[0].id
output privateEndpoint_SubnetID string = virtualNetwork.properties.subnets[1].id
output privateLinkService_SubnetID string = virtualNetwork.properties.subnets[2].id
output applicationGateway_SubnetID string = virtualNetwork.properties.subnets[3].id
output appService_SubnetID string = virtualNetwork.properties.subnets[4].id

// Should be one of the last IPs in the subnet range.  This is for the appgw frontend private ip.
<<<<<<< HEAD
output applicationGateway_PrivateIP string = '${firstTwoOctetsOfVirtualNetworkPrefix}.3.254'
=======
// output applicationGateway_PrivateIP string = '${firstTwoOctetsOfVirtualNetworkPrefix}.3.254'
output applicationGateway_PrivateIP string = cidrHost(subnet_AddressRangeCIDRs[3], 250)
>>>>>>> a0d753352a1da0ad4a3cdfd85f3902b00c9d51cf

output virtualNetwork_Name string = virtualNetwork.name
output virtualNetwork_ID string = virtualNetwork.id

output routeTable_Name string = routeTable.name

output virtualNetwork_AddressPrefix string = virtualNetwork.properties.addressSpace.addressPrefixes[0]
