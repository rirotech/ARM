@description('Department code for the group responsible for the application.')
param department string
@description('The name of the application.')
param appName string
@description('The target environment.')
param environment string
@description('(Optional) Location for the resources.')
param location string = 'eastus'
@description('(Optional) Azure Storage SKU to provision. Default is Standard_ZRS.')
param sku string = 'Standard_ZRS'
@description('(Optional) Comma-separate list of Azure Storage File Shares to provision. If not supplied or empty, Azure File Shares will not be provisioned.')
param fileShares string = ''
@description('(Optional) Authentication protocol for File Shares. May be SMB or NFS (default).')
param sharesAuthProtocol string = 'SMB'

var storageAccountName = toLower('${department}${appName}${environment}st')
var shareList = ((!empty(fileShares)) ? split(fileShares, ',') : [])

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  tags: {
    Department: department
    AppName: appName
    Environment: environment
  }
  sku: {
    name: sku
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

resource storageAccountBlobServices 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = {
  parent: storageAccount
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
resource storageAccountFileServices 'Microsoft.Storage/storageAccounts/fileServices@2021-09-01' = if (!empty(shareList)){
  name: 'default'
  parent:storageAccount

}

resource symbolicname 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-09-01' = [for share in shareList:{
  name: share
  parent: storageAccountFileServices
  properties: {
    accessTier: 'Hot'
    enabledProtocols: sharesAuthProtocol
  }
}]

resource storageAccountTableServices 'Microsoft.Storage/storageAccounts/tableServices@2022-09-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
  }
  
}

output storageAccountName string = storageAccountName
