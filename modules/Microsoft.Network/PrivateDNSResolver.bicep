@description('the location for resolver VNET and dns private resolver - Azure DNS Private Resolver available in specific region, refer the documenation to select the supported region for this deployment. For more information https://docs.microsoft.com/azure/dns/dns-private-resolver-overview#regional-availability')
// @allowed([
//   'australiaeast'
//   'uksouth'
//   'northeurope'
//   'southcentralus'
//   'westus3'
//   'eastus'
//   'northcentralus'
//   'westcentralus'
//   'eastus2'
//   'westeurope'
//   'centralus'
//   'canadacentral'
//   'brazilsouth'
//   'francecentral'
//   'swedencentral'
//   'switzerlandnorth'
//   'eastasia'
//   'southeastasia'
//   'japaneast'
//   'koreacentral'
//   'southafricanorth'
//   'centralindia'
//   'westus'
//   'canadaeast'
//   'qatarcentral'
//   'uaenorth'
//   'australiasoutheast'
//   'polandcentral'
// ])
param location string

@description('Resource ID of the Virtual Network to which the DNS Private resolver will be added.')
param virtualNetwork_ID string

@description('Extracts the name of the Virtual Network out of the Resource ID.')
var virtualNetwork_Name = last(split(virtualNetwork_ID, '/'))

@description('Resource ID of the Subnet to which the DNS Private resolver Inbound Endpoint will be added.')
param dnsPrivateResolver_Inbound_SubnetID string

@description('Resource ID of the Subnet to which the DNS Private resolver Outbound Endpoint will be added.')
param dnsPrivateResolver_Outbound_SubnetID string

@description('name of the dns private resolver')
param dnsPrivateResolver_Name string = 'dnsResolver'

@description('name that will be used for the private resolver inbound endpoint')
param inboundEndpoint_Name string = 'endpoint-inbound'

@description('name that will be used for the private resolver outbound endpoint')
param outboundEndpoint_Name string = 'endpoint-outbound'

@description('name of the forwarding ruleset')
param dnsForwardingRuleSet_Name string = 'forwardingRule'

@description('name of the forwarding rule name')
param forwardingRule_Name string

@description('the target domain name for the forwarding ruleset')
param domainName string

@description('''the list of target DNS servers ip address and the port number for conditional forwarding
Format to be used:
{
  ipaddress: '10.0.0.1'
  port: 53
}
{
  ipaddress: '10.0.0.2'
  port: 53
}
''')
param targetDNSServers array

resource dnsPrivateResolver 'Microsoft.Network/dnsResolvers@2022-07-01' = {
  name: dnsPrivateResolver_Name
  location: location
  properties: {
    virtualNetwork: {
      id: virtualNetwork_ID
    }
  }
}

resource inEndpoint 'Microsoft.Network/dnsResolvers/inboundEndpoints@2022-07-01' = {
  parent: dnsPrivateResolver
  name: inboundEndpoint_Name
  location: location
  properties: {
    ipConfigurations: [
      {
        privateIpAllocationMethod: 'Dynamic'
        subnet: {
          id: dnsPrivateResolver_Inbound_SubnetID
        }
      }
    ]
  }
}

resource outEndpoint 'Microsoft.Network/dnsResolvers/outboundEndpoints@2022-07-01' = {
  parent: dnsPrivateResolver
  name: outboundEndpoint_Name
  location: location
  properties: {
    subnet: {
      id: dnsPrivateResolver_Outbound_SubnetID
    }
  }
}

resource dnsForwardingRuleSet 'Microsoft.Network/dnsForwardingRulesets@2022-07-01' = {
  name: dnsForwardingRuleSet_Name
  location: location
  properties: {
    dnsResolverOutboundEndpoints: [
      {
        id: outEndpoint.id
      }
    ]
  }
}

resource resolverLink 'Microsoft.Network/dnsForwardingRulesets/virtualNetworkLinks@2022-07-01' = {
  parent: dnsForwardingRuleSet
  name: '${virtualNetwork_Name}_link'
  properties: {
    virtualNetwork: {
      id: virtualNetwork_ID
    }
  }
}

resource fwRules 'Microsoft.Network/dnsForwardingRulesets/forwardingRules@2022-07-01' = {
  parent: dnsForwardingRuleSet
  name: forwardingRule_Name
  properties: {
    domainName: domainName
    targetDnsServers: targetDNSServers
  }
}
