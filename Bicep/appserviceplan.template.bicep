@description('Department code for the group responsible for the application.')
param department string

@description('The name of the application.')
param appName string

@description('The name of the target environment (Dev/Test/Etc.).')
param environment string

@description('The pricing tier for the hosting plan. Default is S1.')
param sku string = 'S1'

@description('Target Worker Count.')
param workerCount int = 0

@description('TRUE if zone redundant. Only applicable for Premium SKUs.')
param zoneRedundant bool = false 


@description('Location for all resources. Defaults to Resource Group location.')
param location string = resourceGroup().location

var hostingPlanName = '${department}-${appName}-${environment}-asp'

resource hostingPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: hostingPlanName
  location: location
  sku: {
    name: sku
    capacity: workerCount
  }
  properties: {
    perSiteScaling: true 
    maximumElasticWorkerCount: workerCount
    zoneRedundant: zoneRedundant
  }
  tags: {
    Department: department
    AppName: appName
    Environment: environment
  }
  
}
output hostingPlanName string = hostingPlanName 
output hostingPlanId string = hostingPlan.id 
