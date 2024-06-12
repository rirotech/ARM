@description('Department code for the group responsible for the application.')
param department string

@description('The name of the application.')
param appName string

@description('The name of the target environment (Dev/Test/Etc.).')
param environment string

param location string = resourceGroup().location
param maxScaleOut int = 10 


var appPlanName = '${department}-${appName}-${environment}-asp'

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' existing = {
  name: appPlanName
}

resource scaleOutRule 'Microsoft.Insights/autoscalesettings@2022-10-01' = {
  name: appServicePlan.name
  location: location
  properties: {
    enabled: true
    profiles: [
      {
        name: 'Scale out condition'
        capacity: {
          maximum: string(maxScaleOut)
          default: '1'
          minimum: '1'
        }
        rules: [
          {
            scaleAction: {
              type: 'ChangeCount'
              direction: 'Increase'
              cooldown: 'PT5M'
              value: '1'
            }
            metricTrigger: {
              metricName: 'CpuPercentage'
              operator: 'GreaterThan'
              timeAggregation: 'Average'
              threshold: 70
              metricResourceUri: appServicePlan.id
              timeWindow: 'PT5M'
              timeGrain: 'PT1M'
              statistic: 'Average'
            }
          }
          {
            scaleAction: {
              type: 'ChangeCount'
              direction: 'Decrease'
              cooldown: 'PT5M'
              value: '1'
            }
            metricTrigger: {
              metricName: 'CpuPercentage'
              operator: 'LessThan'
              timeAggregation: 'Average'
              threshold: 60
              metricResourceUri: appServicePlan.id
              timeWindow: 'PT10M'
              timeGrain: 'PT1M'
              statistic: 'Average'
            }
          }
        ]
      }
    ]
    targetResourceUri: appServicePlan.id
  }
}
