@description('Region that the resources are deployed to')
param location string

@description('Name of the App Service Plan')
param appServicePlan_Name string

@description('''Name of the App Service.
App names only allow alphanumeric characters and hyphens, cannot start or end in a hyphen, and must be less than 60 chars.''')
param site_Name string

@description('Name of the link between App Service Enviornment and Virtual Network')
var appService_to_VirtualNetwork_Link_Name = '${site_Name}_to_${virtualNetwork_Name}'

@description('Name of the Virtual Network for both the Application Gateway and App Service Environment')
param virtualNetwork_Name string

@description('Subnet ID of the Subnet that the App Service will be vnet injected into')
param appServiceSubnet_ID string

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: appServicePlan_Name
  location: location
  sku: {
    name: 'S1'
    tier: 'Standard'
    size: 'S1'
    family: 'S'
    capacity: 1
  }
  kind: 'app'
  properties: {
    perSiteScaling: false
    elasticScaleEnabled: false
    maximumElasticWorkerCount: 1
    isSpot: false
    reserved: false
    isXenon: false
    hyperV: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
    zoneRedundant: false
  }
}


resource site_ftp_cred 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2022-09-01' = {
  parent: site
  name: 'ftp'
  properties: {
    allow: true // was false and I couldn't connect to github
  }
}

resource site_scm_cred 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2022-09-01' = {
  parent: site
  name: 'scm'
  properties: {
    allow: true // was false and I couldn't connect to github
  }
}

resource site_config 'Microsoft.Web/sites/config@2022-09-01' = {
  parent: site
  name: 'web'
  properties: {
    numberOfWorkers: 1
    defaultDocuments: [
      'Default.htm'
      'Default.html'
      'Default.asp'
      'index.htm'
      'index.html'
      'iisstart.htm'
      'default.aspx'
      'index.php'
      'hostingstart.html'
    ]
    netFrameworkVersion: 'v7.0'
    requestTracingEnabled: false
    remoteDebuggingEnabled: false
    httpLoggingEnabled: false
    acrUseManagedIdentityCreds: false
    logsDirectorySizeLimit: 35
    detailedErrorLoggingEnabled: false
    publishingUsername: '$jamesgbicepwebsite'
    scmType: 'GitHubAction'
    use32BitWorkerProcess: true
    webSocketsEnabled: false
    alwaysOn: true
    managedPipelineMode: 'Integrated'
    virtualApplications: [
      {
        virtualPath: '/'
        physicalPath: 'site\\wwwroot'
        preloadEnabled: true
      }
    ]
    loadBalancing: 'LeastRequests'
    experiments: {
      rampUpRules: []
    }
    autoHealEnabled: false
    vnetName: appService_to_VirtualNetwork_Link_Name
    vnetRouteAllEnabled: true
    vnetPrivatePortsCount: 0
    publicNetworkAccess: 'Enabled'
    localMySqlEnabled: false
    ipSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 2147483647
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    ipSecurityRestrictionsDefaultAction: 'Allow'
    scmIpSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 2147483647
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictionsDefaultAction: 'Allow'
    scmIpSecurityRestrictionsUseMain: false
    http20Enabled: false
    minTlsVersion: '1.2'
    scmMinTlsVersion: '1.2'
    ftpsState: 'FtpsOnly'
    preWarmedInstanceCount: 0
    elasticWebAppScaleLimit: 0
    functionsRuntimeScaleMonitoringEnabled: false
    minimumElasticInstanceCount: 0
    azureStorageAccounts: {}
  }
}

resource site_hostnameBinding 'Microsoft.Web/sites/hostNameBindings@2022-09-01' = {
  parent: site
  name: '${site_Name}.azurewebsites.net'
  // location: location
  properties: {
    siteName: 'jamesgbicepwebsite'
    hostNameType: 'Verified'
  }
}


resource site 'Microsoft.Web/sites@2022-09-01' = {
  name: site_Name
  location: location
  kind: 'app'
  properties: {
    enabled: true
    hostNameSslStates: [
      {
        name: '${site_Name}.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: '${site_Name}.scm.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Repository'
      }
    ]
    serverFarmId: appServicePlan.id
    reserved: false
    isXenon: false
    hyperV: false
    vnetRouteAllEnabled: true
    vnetImagePullEnabled: false
    vnetContentShareEnabled: false
    siteConfig: {
      numberOfWorkers: 1
      acrUseManagedIdentityCreds: false
      alwaysOn: true
      http20Enabled: false
      functionAppScaleLimit: 0
      minimumElasticInstanceCount: 0
    }
    scmSiteAlsoStopped: false
    clientAffinityEnabled: true
    clientCertEnabled: false
    clientCertMode: 'Required'
    hostNamesDisabled: false
    customDomainVerificationId: '3090E394E60D6B59248A348EFCDF9229D62149FBCB879BDCD211F73F69D00FFC'
    containerSize: 0
    dailyMemoryTimeQuota: 0
    httpsOnly: false
    redundancyMode: 'None'
    publicNetworkAccess: 'Enabled'
    storageAccountRequired: false
    virtualNetworkSubnetId: appServiceSubnet_ID // might not need this one since
    keyVaultReferenceIdentity: 'SystemAssigned'
  }
}

resource appServiceEnvironment_Subnet_Link 'Microsoft.Web/sites/virtualNetworkConnections@2022-09-01' = {
  parent: site
  name: appService_to_VirtualNetwork_Link_Name
  properties: {
    vnetResourceId: appServiceSubnet_ID
    isSwift: true
  }
}

output website_FQDN string = site_hostnameBinding.name
