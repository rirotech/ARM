@description('Department code for the group responsible for the application.')
param department string

@description('The name of the application.')
param appName string

@description('The name of the target environment (Dev/Test/Etc.).')
param environment string

@description('The name of the existing hosting plan to use. Must exist. If not specified, a new plan will be created.')
param useHostingPlan string = '' 

@allowed([
  'v6.0','v7.0','v8.0'
])
param dotNetVersion string = 'v8.0'

@description('The name of the App Insights instance to use. Must exist. If not specified, a new instance will be created.')
param useAppInsights string = ''

@description('The name of the User Managed Identity to use. Must exist. If not specified, a new instance will be created.')
param useManagedIdentity string = ''

@description('Location for all resources.')
param location string = 'eastus'

@description('Sets always on property for production slot only.')
param alwaysOn bool = false
param clientAffinityEnabled bool = false

@description('The pricing tier for the hosting plan.')
param sku string = 'S1'

@description('Target Worker Count.')
param workerCount int = 0

@description('Comma delimited list of the Slot Names')
param webAppSlotList string = ''

@description('The name of the resource group containing the VNet to associate with.')
param vNetResourceGroup string = ''

@description('The name of the VNet to associate with.')
param vNetName string = ''

@description('The name of the subnet on the VNet to associate with.')
param subNetName string = ''

@description('The name of the subnet for the private link. Leave blank for no private link.')
param privateEndpointVnetName string = ''

@description('The resource group for the specified private link\'s subnet. Leave blank to use the same resource group as SQL.')
param privateEndpointVnetResourceGroup string = ''

@description('The name of the subnet for the private endpoint.')
param privateEndpointSubnetName string = ''

@description('Comma separated list of virtual directories/applications to create.')
param virtualDirectories string = ''

var webAppName = '${department}-${appName}-${environment}-app'
var hostingPlanName =  empty(useHostingPlan) ? '${department}-${appName}-${environment}-asp': useHostingPlan
var hostingPlanId = empty(useHostingPlan) ? newHostingPlan.id : existingHostingPlan.id 

var appInsightsName = empty(useAppInsights) ? '${department}-${appName}-${environment}-appi' : useAppInsights
var appInsightsInstance = empty(useAppInsights) ? appInsightsResource : existingAppInsights 

var workspaceName = '${department}-${appName}-${environment}-log'
var identityName = (empty(useManagedIdentity) ? '${department}-${appName}-${environment}-id' : useManagedIdentity)
var identityDefinition = json('{"type":"UserAssigned","userAssignedIdentities" : {"${empty(useManagedIdentity) ? identity.id : existingIdentity.id}":{}}}')
var appIdentity = (empty(useManagedIdentity) ? identity : existingIdentity)
var addvNet = ((!empty(vNetResourceGroup)) && (!empty(vNetName)) && (!empty(subNetName)))
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
var webAppSlotNames = ((webAppSlotList == '') ? split('emptyList', ',') : split(webAppSlotList, ','))

var webAppVDirs = ((empty(trim(virtualDirectories))) ? split('emptyList', ',') : split(trim(virtualDirectories), ','))
var basevDirDefinition = json('[{"virtualPath": "/", "physicalPath": "site\\\\wwwroot", "preloadEnabled": false }]')
var vdirJsonArray = [for dirName in webAppVDirs: {
  virtualPath: '/${dirName}'
  physicalPath: 'site\\wwwroot\${dirName}'
  preloadEnabled: true }]
var appVirtualDirectories = ((empty(virtualDirectories)) ? basevDirDefinition : union(basevDirDefinition, vdirJsonArray))


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


resource webApp 'Microsoft.Web/sites@2022-03-01' = {
  name: webAppName
  location: location
  identity: identityDefinition
  kind: 'app'
  properties: {
    enabled: true
    serverFarmId: hostingPlanId
    clientAffinityEnabled: clientAffinityEnabled
    httpsOnly: true
    siteConfig: {
      alwaysOn: alwaysOn
      netFrameworkVersion: dotNetVersion
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
      ]
      ipSecurityRestrictions: (false ? vNetRef : null)
      minTlsVersion: '1.2'
      virtualApplications : appVirtualDirectories
    }
  }
  tags: {
    Department: department
    AppName: appName
    Environment: environment
  }
}
resource webApp_AppInsights 'Microsoft.Web/sites/siteextensions@2022-03-01' = {
  parent: webApp
  name: 'Microsoft.ApplicationInsights.AzureWebSites'

}
resource webAppName_virtualNetwork 'Microsoft.Web/sites/networkConfig@2018-11-01' = if (addvNet) {
  parent: webApp
  name: 'virtualNetwork'
  properties: {
    subnetResourceId: subnetRef
    swiftSupported: true 
  }
}

resource webApp_Slots 'Microsoft.Web/sites/slots@2022-03-01' = [for item in webAppSlotNames: if (webAppSlotNames[0] != 'emptyList') {
  parent: webApp
  location:location
  name: item
  identity: identityDefinition
  properties: {
    clientAffinityEnabled: clientAffinityEnabled
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
      ]
      minTlsVersion: '1.2'
      virtualApplications : appVirtualDirectories
  }
}}]
resource webApp_Slots_VNet 'Microsoft.Web/sites/slots/networkConfig@2018-11-01' = [for (item, i) in webAppSlotNames: if (addvNet){
  parent: webApp_Slots[i]
  name: 'virtualNetwork'
  properties: {
    subnetResourceId: subnetRef
    swiftSupported: true
  }
}
]

resource webApp_Slots_AppInsights 'Microsoft.Web/sites/slots/siteextensions@2022-03-01' = [for (item, i) in webAppSlotNames: if (webAppSlotNames[0] != 'emptyList'){
  parent: webApp_Slots[i]
  name: 'Microsoft.ApplicationInsights.AzureWebSites'
}
]
resource pLinkVNet 'Microsoft.Network/virtualNetworks@2021-02-01' existing = if(!empty(privateEndpointVnetName)){
  name: privateEndpointVnetName
  scope: resourceGroup(privateEndpointVnetResourceGroup)
}
resource pLinkSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing =  if(!empty(privateEndpointSubnetName)) {
  name : privateEndpointSubnetName
  parent: pLinkVNet
}


resource prodSlotPrivateEndpoint 'Microsoft.Network/privateEndpoints@2022-11-01' = if(!empty(privateEndpointSubnetName)){
  name: '${webAppName}-PE'
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${webAppName}-PE'
        properties: {
          privateLinkServiceId: webApp.id
          groupIds: [
            'sites'
          ]
        }
      }
    ]
    manualPrivateLinkServiceConnections: []
    customNetworkInterfaceName: '${webAppName}-PE-nic'
    subnet: {
      id: pLinkSubnet.id
    }
    ipConfigurations: []
    customDnsConfigs: []
  }
}

resource slotPrivateEndpoint 'Microsoft.Network/privateEndpoints@2022-11-01' = [for (item, i) in webAppSlotNames:if(addvNet) {
  name: '${webAppName}-${webApp_Slots[i].name}-PE'
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${webAppName}-${webApp_Slots[i].name}-PE'
        properties: {
          privateLinkServiceId: webApp.id
          groupIds: [
            'sites-${item}'
          ]
        }
      }
    ]
    manualPrivateLinkServiceConnections: []
    customNetworkInterfaceName: '${webAppName}-${webApp_Slots[i].name}-PE-nic'
    subnet: {
      id: pLinkSubnet.id
    }
    ipConfigurations: []
    customDnsConfigs: []
    
  }
}]


output webAppName string = webAppName
output hostingPlanName string = hostingPlanName
output appInsightsName string = appInsightsName
output webAppUrl string = 'https://${webAppName}.azurewebsites.net'
output identityName string = identityName
output identityPrincipalId string = appIdentity.properties.principalId
output identityClientId string = appIdentity.properties.clientId
