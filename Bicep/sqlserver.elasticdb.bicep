@description('Department code for the group responsible for the application.')
param department string

@description('The name of the target environment (Dev/Test/Etc.).')
param environment string

@description('The name of the target SQL Server.')
param sqlServerName string  

@description('The name of the target elastic pool.')
param elasticPoolName string  

@description('Comma-delimited list of apps to create databases for.')
param databaseApp string

@description('The Elastic Pool edition.')
@allowed([
  'Basic'
  'Standard'
  'Premium'
  'GP_Gen5'
  'BC_Gen5'
])
param edition string = 'Standard'

@description('The SQL Database collation.')
param databaseCollation string = 'SQL_Latin1_General_CP1_CI_AS'

@description('Location for all resources.')
param location string = 'eastus'

var databaseName = toLower('${department}-${databaseApp}-${environment}-sqldb')
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
var skuTier = editionToSkuMap[edition].tier

resource sqlServer 'Microsoft.Sql/servers@2022-11-01-preview' existing = {
  name: sqlServerName
}

resource elasticPool 'Microsoft.Sql/servers/elasticPools@2022-11-01-preview' existing =  {
  name: elasticPoolName
}

resource databases 'Microsoft.Sql/servers/databases@2022-11-01-preview' =  {
  parent: sqlServer
  name: databaseName
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
}


output sqlServerName string = sqlServer.name
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
output elasticPoolName string = elasticPoolName
output databaseName string = databaseName
