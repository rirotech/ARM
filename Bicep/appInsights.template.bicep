@description('Department code for the group responsible for the application.')
param department string

@description('The name of the application.')
param appName string

@description('The name of the target environment (Dev/Test/Etc.).')
param environment string

@description('Location for all resources.')
param location string = 'eastus'

var appInsightsName = '${department}-${appName}-${environment}-appi'
var workspaceName = '${department}-${appName}-${environment}-log'

resource appInsightsResource 'Microsoft.Insights/components@2020-02-02' = {
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
    Flow_Type: 'Redfield'
    WorkspaceResourceId: workspace.id
  }
  
}

resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
  properties: {}
  tags: {
    Department: department
    AppName: appName
    Environment: environment
  }
}
output appInsightsName string = appInsightsName
output logAnalyticsWorkspace string = workspaceName 
