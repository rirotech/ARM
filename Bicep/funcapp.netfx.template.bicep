@description('Department code for the group responsible for the application.')
param department string

@description('The name of the application.')
param appName string

@description('The name of the target environment (Dev/Test/Etc.).')
param environment string

@description('The name of the existing hosting plan to use. Must exist. If not specified, a new plan will be created.')
param useHostingPlan string = '' 

@description('The name of the App Insights instance to use. Must exist. If not specified, a new instance will be created.')
param useAppInsights string = ''

@description('The name of the storage account to use. Must exist. If not specified, a new instance will be created.')
param useStorageAccount string = ''

@description('The name of the User Managed Identity to use. Must exist. If not specified, a new instance will be created.')
param useManagedIdentity string = ''


@description('Sets always on property.')
param alwaysOn bool = false

@description('Target Worker Count.')
param workerCount int = 0

@description('Comma delimited list of the Slot Names')
param slotList string = ''

@description('The name of the resource group containing the VNet to associate with.')
param vNetResourceGroup string = ''

@description('The name of the VNet to associate with.')
param vNetName string = ''

@description('The name of the subnet on the VNet to associate with.')
param subNetName string = ''

@description('The name of the subnet for the private link. Leave blank for no private link.')
param privateEndpointVnetName string = ''

@description('The resource group for the specified private link\'s subnet.')
param privateEndpointVnetResourceGroup string = ''

@description('The name of the subnet for the private endpoint.')
param privateEndpointSubnetName string = ''


@description('The pricing tier for the hosting plan.')
@allowed([
  'D1'
  'F1'
  'B1'
  'B2'
  'B3'
  'S1'
  'S2'
  'S3'
  'P1'
  'P2'
  'P3'
  'P1V2'
  'P2V2'
  'P3V2'
  'I1'
  'I2'
  'I3'
  'Y1'
])
param sku string = 'S1'

@description('The instance size of the hosting plan (small, medium, or large).')
@allowed([
  '0'
  '1'
  '2'
])
param workerSize string = '0'

@description('Storage Account SKU')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
])
param storageAccountSku string = 'Standard_ZRS'

@description('Location for all resources.')
param location string = resourceGroup().location

@allowed([
  'None'
  'Shared'
  'AppSpecific'
])
param IdentityType string = 'Shared'

@description('Set to false to disable diags')
param enableDiags bool = true

var functionAppName = '${department}-${appName}-${environment}-func'
var functionAppId = functionApp.id
var hostingPlanName =  empty(useHostingPlan) ? '${department}-${appName}-${environment}-asp': useHostingPlan
var hostingPlanId = empty(useHostingPlan) ? newHostingPlan.id : existingHostingPlan.id 

var appInsightsName = empty(useAppInsights) ? '${department}-${appName}-${environment}-appi' : useAppInsights
var appInsightsInstance = empty(useAppInsights) ? appInsightsResource : existingAppInsights 
var workspaceName = '${department}-${appName}-${environment}-log'

var storageAccount = empty(useStorageAccount) ? newStorageAccount : existingStorageAccount
var storageAccountName =  empty(useStorageAccount) ? toLower('${department}${appName}${environment}st') : useStorageAccount 

var identityName = (empty(useManagedIdentity) ? '${department}-${appName}-${environment}-id' : useManagedIdentity)
var identityDefinition = json('{"type":"UserAssigned","userAssignedIdentities" : {"${empty(useManagedIdentity) ? identity.id : existingIdentity.id}":{}}}')
var appIdentity = (empty(useManagedIdentity) ? identity : existingIdentity)

var subnetRef = resourceId(vNetResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', vNetName, subNetName)
var vNetRef = [
  {
    ipAddress: 'Any'
    action: 'Deny'
    priority: 2147483647
    name: 'Deny all'
    description: 'Deny all access'
  }
]
var functionAppSlotNames = ((slotList == '') ? split('emptyList', ',') : split(slotList, ','))

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = if(empty(useManagedIdentity)){
  name: identityName
  location: location
  tags: {
    Department: department
    AppName: appName
    Environment: environment
  }
}

resource existingIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = if(!empty(useManagedIdentity)){
  name: identityName
  }

  resource newHostingPlan 'Microsoft.Web/serverfarms@2022-03-01' = if(empty(useHostingPlan)) {
    name: hostingPlanName
    location: location
    sku: {
      name: sku
      capacity: workerCount
    }
    properties: {
      perSiteScaling: true 
      maximumElasticWorkerCount: workerCount
      zoneRedundant: false 
    }
    tags: {
      Department: department
      AppName: appName
      Environment: environment
    }
  }
  
  resource existingHostingPlan 'Microsoft.Web/serverfarms@2022-03-01' existing = if(!empty(useHostingPlan)) {
    name:useHostingPlan
  }
  
  resource existingAppInsights 'Microsoft.Insights/components@2020-02-02' existing  = if (!empty(useAppInsights)){
    name:useAppInsights
  }
  
  resource appInsightsResource 'Microsoft.Insights/components@2020-02-02'= if (empty(useAppInsights)) {
    name: appInsightsName
    location: location
    kind: 'web'
    tags: {
      Department: department
      AppName: appName
      Environment: environment
    }
    properties: {
      Application_Type: 'web'
      WorkspaceResourceId: workspace.id
    }
    
  }
  
  resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = if (empty(useAppInsights)) {
    name: workspaceName
    location: location
    properties: {}
    tags: {
      Department: department
      AppName: appName
      Environment: environment
    }
  }
  

resource newStorageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = if (empty(useStorageAccount)) {
  name: storageAccountName
  location: location
  tags: {
    Department: department
    AppName: appName
    Environment: environment
  }
  sku: {
    name: storageAccountSku
  }
  kind: 'StorageV2'
  properties: {
    dnsEndpointType: 'Standard'
    defaultToOAuthAuthentication: false
    publicNetworkAccess: 'Enabled'
    allowCrossTenantReplication: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      requireInfrastructureEncryption: false
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}

resource existingStorageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = if(!empty(useStorageAccount)){
  name:useStorageAccount
}


resource storageAccountBlobServices 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = if (empty(useStorageAccount)) {
  parent: newStorageAccount
  name: 'default'
  properties: {
    changeFeed: {
      enabled: false
    }
    restorePolicy: {
      enabled: false
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      allowPermanentDelete: false
      enabled: true
      days: 7
    }
    isVersioningEnabled: false
  }
}


resource functionApp 'Microsoft.Web/sites@2018-11-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  identity: identityDefinition
  properties: {
    serverFarmId: hostingPlanId
    clientAffinityEnabled: false
    httpsOnly: true
    siteConfig: {
      alwaysOn: alwaysOn
      netFrameworkVersion: 'v4.0'
      cors:{
        allowedOrigins:['https://portal.azure.com']
      }
      appSettings:[
        {
          name : 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsInstance.properties.InstrumentationKey
        }
        {
          name : 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsInstance.properties.ConnectionString
        }
        {
          name : 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~2'
        }
        {
          name : 'AzureServicesAuthConnectionString'
          value: 'RunAs=App;AppId=${appIdentity.properties.clientId}'
        }
        {
            name:'AzureWebJobsStorage__accountName'
            value: storageAccountName
        }
        {
          name:'AzureWebJobsStorage__clientId'
          value: appIdentity.properties.clientId
        }
        {
          name:'AzureWebJobsStorage__credential'
          value: 'managedIdentity'
        }
        {
          name:'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet-isolated'
        }
    
      ]
      ipSecurityRestrictions: (false ? vNetRef : null)
      minTlsVersion: '1.2'
    }
  }
  tags: {
    Department: department
    AppName: appName
    Environment: environment
  }
}

resource functionApp_AppInsights 'Microsoft.Web/sites/siteextensions@2022-03-01' = {
  parent: functionApp
  name: 'Microsoft.ApplicationInsights.AzureWebSites'
}

resource functionAppName_virtualNetwork 'Microsoft.Web/sites/networkConfig@2018-11-01' = {
  parent: functionApp
  name: 'virtualNetwork'
  properties: {
    subnetResourceId: subnetRef
  }
}
resource functionApp_Slots 'Microsoft.Web/sites/slots@2022-03-01' = [for item in functionAppSlotNames: if (functionAppSlotNames[0] != 'emptyList') {
  parent: functionApp
  location:location
  name: item
  identity: identityDefinition
  properties: {
    siteConfig: {
      alwaysOn: false
      netFrameworkVersion: 'v4.0'
      appSettings:[
        {
          name : 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsInstance.properties.InstrumentationKey
        }
        {
          name : 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsInstance.properties.ConnectionString
        }
        {
          name : 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~2'
        }
        {
          name : 'AzureServicesAuthConnectionString'
          value: 'RunAs=App;AppId=${appIdentity.properties.clientId}'
        }
        {
            name:'AzureWebJobsStorage__accountName'
            value: storageAccountName
        }
        {
          name:'AzureWebJobsStorage__clientId'
          value: appIdentity.properties.clientId
        }
        {
          name:'AzureWebJobsStorage__credential'
          value: 'managedIdentity'
        }
        {
          name:'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
      ]
  }
}}]
resource webApp_Slots_VNet 'Microsoft.Web/sites/slots/networkConfig@2018-11-01' = [for (item, i) in functionAppSlotNames: if (functionAppSlotNames[0] != 'emptyList'){
  parent: functionApp_Slots[i]
  name: 'virtualNetwork'
  properties: {
    subnetResourceId: subnetRef
    swiftSupported: true
  }
}]

resource webApp_Slots_AppInsights 'Microsoft.Web/sites/slots/siteextensions@2022-03-01' =  [for (item, i) in functionAppSlotNames: if (functionAppSlotNames[0] != 'emptyList'){
  parent: functionApp_Slots[i]
  name: 'Microsoft.ApplicationInsights.AzureWebSites'
}]

resource pLinkVNet 'Microsoft.Network/virtualNetworks@2021-02-01' existing = if(!empty(privateEndpointVnetName)){
  name: privateEndpointVnetName
  scope: resourceGroup(privateEndpointVnetResourceGroup)
}
resource pLinkSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing =  if(!empty(privateEndpointSubnetName)) {
  name : privateEndpointSubnetName
  parent: pLinkVNet
}


resource prodSlotPrivateEndpoint 'Microsoft.Network/privateEndpoints@2022-11-01' = if(!empty(privateEndpointSubnetName)){
  name: '${functionAppName}-PE'
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${functionAppName}-PE'
        properties: {
          privateLinkServiceId: functionApp.id
          groupIds: [
            'sites'
          ]
        }
      }
    ]
    manualPrivateLinkServiceConnections: []
    customNetworkInterfaceName: '${functionAppName}-PE-nic'
    subnet: {
      id: pLinkSubnet.id
    }
    ipConfigurations: []
    customDnsConfigs: []
  }
}

resource slotPrivateEndpoint 'Microsoft.Network/privateEndpoints@2022-11-01' = [for (item, i) in functionAppSlotNames:if(!empty(privateEndpointSubnetName) && functionAppSlotNames[0] != 'emptyList') {
  name: '${functionAppName}-${functionApp_Slots[i].name}-PE'
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${functionAppName}-${functionApp_Slots[i].name}-PE'
        properties: {
          privateLinkServiceId: functionApp.id
          groupIds: [
            'sites-${item}'
          ]
        }
      }
    ]
    manualPrivateLinkServiceConnections: []
    customNetworkInterfaceName: '${functionAppName}-${functionApp_Slots[i].name}-PE-nic'
    subnet: {
      id: pLinkSubnet.id
    }
    ipConfigurations: []
    customDnsConfigs: []
    
  }
}]

output functionAppName string = functionAppName
output hostingPlanName string = hostingPlanName
output storageAccountName string = storageAccountName
output appInsightsName string = appInsightsName
output identityName string = identityName
output identityPrincipalId string = identity.properties.principalId
output identityClientId string = identity.properties.clientId
