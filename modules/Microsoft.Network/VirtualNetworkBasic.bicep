@description('Azure Datacenter that the resource is deployed to')
param location string

@description('Name of the Virtual Network')
param virtualNetwork_Name string

@description('Address Prefix of the Virtual Network')
param virtualNetwork_AddressPrefix string = '${firstTwoOctetsOfVirtualNetworkPrefix}.0.0/16'

@description('''First two octects of the Virtual Network address prefix
Example: for a network address of '10.0.0.0/16' you would enter '10.0' here''')
param firstTwoOctetsOfVirtualNetworkPrefix string

// Subnets
@description('Name of the General Subnet for any other resources')
param subnet_General_Name string = 'General'

@description('Address Prefix of the General Subnet')
param subnet_General_AddressPrefix string = '${firstTwoOctetsOfVirtualNetworkPrefix}.0.0/24'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-09-01' = {
  name: virtualNetwork_Name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetwork_AddressPrefix
      ]
    }
    subnets: [
      {
        name: subnet_General_Name
        properties: {
          addressPrefix: subnet_General_AddressPrefix
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
    enableDdosProtection: false
  }
}

output general_SubnetID string = virtualNetwork.properties.subnets[0].id

output virtualNetwork_Name string = virtualNetwork.name
output virtualNetwork_ID string = virtualNetwork.id

output virtualNetwork_AddressPrefix string = virtualNetwork.properties.addressSpace.addressPrefixes[0]
