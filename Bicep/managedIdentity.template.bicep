@description('Department code for the group responsible for the application.')
param department string

@description('The name of the application.')
param appName string

@description('The name of the target environment (Dev/Test/Etc.).')
param environment string

@description('The name of the target resource group.')
param location string = resourceGroup().location


var identityName = '${department}-${appName}-${environment}-id'

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: identityName
  location: location
  tags: {
    Department: department
    AppName: appName
    Environment: environment
  }
}

output identityName string = identityName
output identityPrincipalId string = identity.properties.principalId
output identityClientId string = identity.properties.clientId
