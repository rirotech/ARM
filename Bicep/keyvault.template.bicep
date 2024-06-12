@description('Department code for the group responsible for the application.')
param department string
@description('The name of the application.')
param appName string
@description('The target environment.')
param environment string

@description('(Optional) Location for the resources.')
param location string = resourceGroup().location

@description('The SKU of the vault to be created.')
@allowed([
  'standard'
  'premium'
])
param skuName string = 'standard'

@description('VNets allowed to access this keyvault. Multiple VNets should be separated by commas. Individual subnets should be in the format [VNetName]:[Subnet].')
param allowedSubnets string = ''

@description('Resource Group for the VNets with the subnets that will be allowed access to the KeyVault.')
param allowedSubnetsResourceGroup string = ''


@description('The name of the subnet for the private link. Leave blank for no private link.')
param privateEndpointVnetName string = ''

@description('The resource group for the specified private link\'s subnet. Leave blank to use the same resource group as KeyVault.')
param privateEndpointVnetResourceGroup string = ''

@description('The name of the subnet for the private endpoint.')
param privateEndpointSubnetName string = ''


var allowedSubnetArray = empty(allowedSubnets) ? [] : split(allowedSubnets, ',')
var vaultName = toLower('${department}-${appName}-${environment}-kv')
var subnetAcls = [for i in range(0, length(allowedSubnetArray)): {
  id: resourceId(allowedSubnetsResourceGroup, 'Microsoft.Network/VirtualNetworks/subnets', split(allowedSubnetArray[i], ':')[0], split(allowedSubnetArray[i], ':')[1])
  ignoreMissingVnetServiceEndpoint: true
}
 
]

resource vault 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: vaultName
  location: location
  tags: {
    Department: department
    AppName: appName
    Environment: environment
  }
  properties: {
    accessPolicies:[]
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enabledForDeployment: true
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
    tenantId: subscription().tenantId
    sku: {
      name: skuName
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      virtualNetworkRules: subnetAcls
    }
  }
}

resource pLinkVNet 'Microsoft.Network/virtualNetworks@2021-02-01' existing = if(!empty(privateEndpointSubnetName)){
  name: privateEndpointVnetName
  scope: resourceGroup(privateEndpointVnetResourceGroup)
}
resource pLinkSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing =  if(!empty(privateEndpointSubnetName)) {
  name : privateEndpointSubnetName
  parent: pLinkVNet
}


resource keyVaultPrivateEndpoint 'Microsoft.Network/privateEndpoints@2022-11-01' = if(!empty(privateEndpointSubnetName)){
  name: '${vaultName}-PE'
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${vaultName}-PE'
        properties: {
          privateLinkServiceId: vault.id
          groupIds: [
            'vault'
          ]
        }
      }
    ]
    manualPrivateLinkServiceConnections: []
    customNetworkInterfaceName: '${vaultName}-PE-nic'
    subnet: {
      id: pLinkSubnet.id
    }
    ipConfigurations: []
    customDnsConfigs: []
  }
}




output keyVaultName string = vaultName



