@description('Department code for the group responsible for the application.')
param department string

@description('The name of the application.')
param appName string

@description('The name of the target environment (Dev/Test/Etc.).')
param environment string

@description('The SQL Server administrator user name.')
param aadAdminName string

@description('The SQL Server administrator Azure AD Object ID.')
param aadAdminObjectId string

@description('The type of Azure AD object assigned to the admin role.')
@allowed(['User', 'Group', 'Application'])
param aadAdminObjectType string = 'Group'

@description('The Tenant ID of the Azure AD instance.')
param aadAuthOnly bool = true

@description('The Tenant ID of the Azure AD instance.')
param aadTenantId string = az.environment().authentication.tenant

@description('The Elastic Pool edition.')
@allowed([
  'Basic'
  'Standard'
  'Premium'
  'GP_Gen5'
  'BC_Gen5'
])
param edition string = 'Standard'

@description('The Elastic Pool DTU or number of vcore.')
param capacity int

@description('The Elastic Pool database capacity min.')
param databaseCapacityMin int = 0

@description('The Elastic Pool database capacity max.')
param databaseCapacityMax int

@description('Comma-delimited list of apps to create databases for.')
param databaseApps string

@description('The SQL Database collation.')
param databaseCollation string = 'SQL_Latin1_General_CP1_CI_AS'

@description('Location for all resources.')
param location string = 'eastus'

@description('The name of the subnet for the private link. Leave blank for no private link.')
param privateEndpointVnetName string = ''

@description('The resource group for the specified private link\'s subnet. Leave blank to use the same resource group as SQL.')
param privateEndpointVnetResourceGroup string = ''

@description('The name of the subnet for the private endpoint.')
param privateEndpointSubnetName string = ''

var serverName = toLower('${department}-${appName}-${environment}-sql')
var elasticPoolName = toLower('${department}-${appName}-${environment}-sqlep')
var databaseNames = [for name in databaseAppNames: toLower('${department}-${name}-${environment}-sqldb')]
var databaseAppNames = split(databaseApps, ',')
var editionToSkuMap = {
  Basic: {
    name: 'BasicPool'
    tier: 'Basic'
  }
  Standard: {
    name: 'StandardPool'
    tier: 'Standard'
  }
  Premium: {
    name: 'PremiumPool'
    tier: 'Premium'
  }
  GP_Gen5: {
    family: 'Gen5'
    name: 'GP_Gen5'
    tier: 'GeneralPurpose'
  }
  BC_Gen5: {
    family: 'Gen5'
    name: 'BC_Gen5'
    tier: 'BusinessCritical'
  }
}
var skuName = editionToSkuMap[edition].name
var skuTier = editionToSkuMap[edition].tier

resource sqlServer 'Microsoft.Sql/servers@2022-11-01-preview' = {
  location: location
  name: serverName
  properties: {
    version: '12.0'
    administrators: {
      login: aadAdminName
      sid :aadAdminObjectId
      tenantId: aadTenantId
      principalType: aadAdminObjectType
      azureADOnlyAuthentication: aadAuthOnly
  }
  }
}

resource elasticPool 'Microsoft.Sql/servers/elasticPools@2022-11-01-preview' = {
  parent: sqlServer
  location: location
  name: elasticPoolName
  sku: {
    name: skuName
    tier: skuTier
    capacity: capacity
  }
  properties: {
    perDatabaseSettings: {
      minCapacity: databaseCapacityMin
      maxCapacity: databaseCapacityMax
    }
  }
}

resource databases 'Microsoft.Sql/servers/databases@2022-11-01-preview' = [for item in databaseNames: {
  parent: sqlServer
  name: item
  location: location
  sku: {
    name: 'ElasticPool'
    tier: skuTier
    capacity: 0
  }
  properties: {
    collation: databaseCollation
    elasticPoolId: elasticPool.id
  }
}]

resource sqlServerAllAllAzureIps 'Microsoft.Sql/servers/firewallRules@2022-11-01-preview' = {
  parent: sqlServer
  name: 'AllowAllWindowsAzureIps'
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
}



resource pLinkVNet 'Microsoft.Network/virtualNetworks@2021-02-01' existing = if(!empty(privateEndpointVnetName)){
  name: privateEndpointVnetName
  scope: resourceGroup(privateEndpointVnetResourceGroup)
}
resource pLinkSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing =  if(!empty(privateEndpointSubnetName)) {
  name : privateEndpointSubnetName
  parent: pLinkVNet
}


resource sqlPrivateEndpoint 'Microsoft.Network/privateEndpoints@2022-11-01' = if(!empty(privateEndpointSubnetName)){
  name: '${serverName}-PE'
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${serverName}-PE'
        properties: {
          privateLinkServiceId: sqlServer.id
          groupIds: [
            'sqlServer'
          ]
          privateLinkServiceConnectionState: {
            status: 'Approved'
            description: 'Auto-approved'
            actionsRequired: 'None'
          }
        }
      }
    ]
    manualPrivateLinkServiceConnections: []
    customNetworkInterfaceName: '${serverName}-PE-nic'
    subnet: {
      id: pLinkSubnet.id
    }
    ipConfigurations: []
    customDnsConfigs: []
  }
}


output sqlServerName string = serverName
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
output elasticPoolName string = elasticPoolName
output databaseNames array = databaseNames
