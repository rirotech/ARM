# Bicep Templates

## appInsights.template.bicep

Template to deploy a single App Insights instance.

### Input Parameters
|Name|Data Type|Default Value|Description|
|----|----|----|----|
|department|string|  |Department code for the group responsible for the application.|
|appName|string|  |The name of the application.|
|environment|string|  |The name of the target environment (Dev/Test/Etc.).|
|location|string| 'eastus' |Location for all resources.|

### Output Parameters
|Name|Data Type|Source Variable|Description|
|----|----|----|----|
|appInsightsName|string| appInsightsName | |
|logAnalyticsWorkspace|string| workspaceName | |


## appserviceplan.template.bicep

Template to deploy a standalone App Service Plan (to be reused for additional Web Apps).

### Input Parameters
|Name|Data Type|Default Value|Description|
|----|----|----|----|
|department|string|  |Department code for the group responsible for the application.|
|appName|string|  |The name of the application.|
|environment|string|  |The name of the target environment (Dev/Test/Etc.).|
|sku|string| 'S1' |The pricing tier for the hosting plan. Default is S1.|
|workerCount|int| 0 |Target Worker Count.|
|zoneRedundant|bool| false |TRUE if zone redundant. Only applicable for Premium SKUs.|
|location|string| resourceGroup().location |Location for all resources. Defaults to Resource Group location.|

### Output Parameters
|Name|Data Type|Source Variable|Description|
|----|----|----|----|
|hostingPlanName|string| hostingPlanName | |
|hostingPlanId|string| hostingPlan.id | |

## funcapp.netfx.template.bicep
Template to deploy a Function app that runs with .NET Framework 4.8. The function app will run in [Isolated Mode](https://learn.microsoft.com/en-us/azure/azure-functions/dotnet-isolated-process-guide?tabs=windows).

|Name|Data Type|Default Value|Description|
|----|----|----|----|
|department|string|  |Department code for the group responsible for the application.|
|appName|string|  |The name of the application.|
|environment|string|  |The name of the target environment (Dev/Test/Etc.).|
|useHostingPlan|string| '' |The name of the existing hosting plan to use. Must exist. If not specified, a new plan will be created.|
|useAppInsights|string| '' |The name of the App Insights instance to use. Must exist. If not specified, a new instance will be created.|
|useStorageAccount|string| '' |The name of the storage account to use. Must exist. If not specified, a new instance will be created.|
|useManagedIdentity|string| '' |The name of the User Managed Identity to use. Must exist. If not specified, a new instance will be created.|
|alwaysOn|bool| false |Sets always on property.|
|workerCount|int| 0 |Target Worker Count.|
|slotList|string| '' |Comma delimited list of the Slot Names|
|vNetResourceGroup|string| '' |The name of the resource group containing the VNet to associate with.|
|vNetName|string| '' |The name of the VNet to associate with.|
|subNetName|string| '' |The name of the subnet on the VNet to associate with.|
|privateEndpointVnetName|string| '' |The name of the subnet for the private link. Leave blank for no private link.|
|privateEndpointSubnetName|string| '' |The name of the subnet for the private endpoint.|
|location|string| resourceGroup().location |Location for all resources.|
|enableDiags|bool| true |Set to false to disable diags|

### Output Parameters
|Name|Data Type|Source Variable|Description|
|----|----|----|----|
|functionAppName|string| functionAppName | |
|hostingPlanName|string| hostingPlanName | |
|storageAccountName|string| storageAccountName | |
|appInsightsName|string| appInsightsName | |
|identityName|string| identityName | |
|identityPrincipalId|string| identity.properties.principalId | |
|identityClientId|string| identity.properties.clientId | |


## keyvault.template.bicep

Template to deploy a Key Vault.

### Input Parameters
|Name|Data Type|Default Value|Description|
|----|----|----|----|
|department|string|  |Department code for the group responsible for the application.|
|appName|string|  |The name of the application.|
|environment|string|  |The target environment.|
|location|string| resourceGroup().location |(Optional) Location for the resources.|
|allowedSubnets|string| '' |VNets allowed to access this keyvault. Multiple VNets should be separated by commas. Individual subnets should be in the format [VNetName]:[Subnet].|
|allowedSubnetsResourceGroup|string| '' |Resource Group for the VNets with the subnets that will be allowed access to the KeyVault.|
|privateEndpointVnetName|string| '' |The name of the subnet for the private link. Leave blank for no private link.|
|privateEndpointSubnetName|string| '' |The name of the subnet for the private endpoint.|

### Output Parameters
|Name|Data Type|Source Variable|Description|
|----|----|----|----|
|keyVaultName|string| vaultName | |

## managedIdentity.template.bicep

Template for a single managed identity.

### Input Parameters
|Name|Data Type|Default Value|Description|
|----|----|----|----|
|department|string|  |Department code for the group responsible for the application.|
|appName|string|  |The name of the application.|
|environment|string|  |The name of the target environment (Dev/Test/Etc.).|
|location|string| resourceGroup().location |The name of the target resource group.|

### Output Parameters
|Name|Data Type|Source Variable|Description|
|----|----|----|----|
|identityName|string| identityName | |
|identityPrincipalId|string| identity.properties.principalId | |
|identityClientId|string| identity.properties.clientId | |

## sqlserver.elasticdb.bicep

Deploys one or more elastic DBs to an elastic db pool.

|Name|Data Type|Default Value|Description|
|----|----|----|----|
|department|string|  |Department code for the group responsible for the application.|
|environment|string|  |The name of the target environment (Dev/Test/Etc.).|
|sqlServerName|string|  |The name of the target SQL Server.|
|elasticPoolName|string|  |The name of the target elastic pool.|
|databaseApp|string|  |Comma-delimited list of apps to create databases for.|
|databaseCollation|string| 'SQL_Latin1_General_CP1_CI_AS' |The SQL Database collation.|
|location|string| 'eastus' |Location for all resources.|

### Output Parameters
|Name|Data Type|Source Variable|Description|
|----|----|----|----|
|sqlServerName|string| sqlServer.name | |
|sqlServerFqdn|string| sqlServer.properties.fullyQualifiedDomainName | |
|elasticPoolName|string| elasticPoolName | |
|databaseName|string| databaseName | |

## sqlserver.elasticpool.bicep

Template to deploy Sql Server with Elastic Pool (see [Manage multiple databases with elastic pools - Azure SQL Database | Microsoft Learn](https://learn.microsoft.com/en-us/azure/azure-sql/database/elastic-pool-overview?view=azuresql-db)). Individual databases can also be specified in the parameters for creation. This template also supports specifying an Azure AD account as administrator and enabling AD-only authentication to the database (see [Configure Azure Active Directory authentication - Azure SQL Database &amp; SQL Managed Instance &amp; Azure Synapse Analytics | Microsoft Learn](https://learn.microsoft.com/en-us/azure/azure-sql/database/authentication-aad-configure?view=azuresql-db&tabs=azure-powershell)).

### Input Parameters
|Name|Data Type|Default Value|Description|
|----|----|----|----|
|department|string|  |Department code for the group responsible for the application.|
|appName|string|  |The name of the application.|
|environment|string|  |The name of the target environment (Dev/Test/Etc.).|
|aadAdminName|string|  |The SQL Server administrator user name.|
|aadAdminObjectId|string|  |The SQL Server administrator Azure AD Object ID.|
|aadAuthOnly|bool| true |The Tenant ID of the Azure AD instance.|
|aadTenantId|string| az.environment().authentication.tenant |The Tenant ID of the Azure AD instance.|
|capacity|int|  |The Elastic Pool DTU or number of vcore.|
|databaseCapacityMin|int| 0 |The Elastic Pool database capacity min.|
|databaseCapacityMax|int|  |The Elastic Pool database capacity max.|
|databaseApps|string|  |Comma-delimited list of apps to create databases for.|
|databaseCollation|string| 'SQL_Latin1_General_CP1_CI_AS' |The SQL Database collation.|
|location|string| 'eastus' |Location for all resources.|
|privateEndpointVnetName|string| '' |The name of the subnet for the private link. Leave blank for no private link.|
|privateEndpointSubnetName|string| '' |The name of the subnet for the private endpoint.|

### Output Parameters
|Name|Data Type|Source Variable|Description|
|----|----|----|----|
|sqlServerName|string| serverName | |
|sqlServerFqdn|string| sqlServer.properties.fullyQualifiedDomainName | |
|elasticPoolName|string| elasticPoolName | |
|databaseNames|array| databaseNames | |

## storage.template.bicep

Template to deploy Azure storage.

### Input Parameters
|Name|Data Type|Default Value|Description|
|----|----|----|----|
|department|string|  |Department code for the group responsible for the application.|
|appName|string|  |The name of the application.|
|environment|string|  |The target environment.|
|location|string| 'eastus' |(Optional) Location for the resources.|
|sku|string| 'Standard_ZRS' |(Optional) Azure Storage SKU to provision. Default is Standard_ZRS.|
|fileShares|string| '' |(Optional) Comma-separate list of Azure Storage File Shares to provision. If not supplied or empty, Azure File Shares will not be provisioned.|
|sharesAuthProtocol|string| 'SMB' |(Optional) Authentication protocol for File Shares. May be SMB or NFS (default).|

### Output Parameters
|Name|Data Type|Source Variable|Description|
|----|----|----|----|
|storageAccountName|string| storageAccountName | |
## webapi.netfx.template.bicep

### Input Parameters
|Name|Data Type|Default Value|Description|
|----|----|----|----|
|department|string|  |Department code for the group responsible for the application.|
|appName|string|  |The name of the application.|
|environment|string|  |The name of the target environment (Dev/Test/Etc.).|
|useHostingPlan|string| '' |The name of the existing hosting plan to use. Must exist. If not specified, a new plan will be created.|
|useAppInsights|string| '' |The name of the App Insights instance to use. Must exist. If not specified, a new instance will be created.|
|useManagedIdentity|string| '' |The name of the User Managed Identity to use. Must exist. If not specified, a new instance will be created.|
|location|string| 'eastus' |Location for all resources.|
|alwaysOn|bool| false |Sets always on property for production slot only.|
|clientAffinityEnabled|bool| false |Sets client affinity on the api site (TRUE if in-process sessions are used).|
|sku|string| 'S1' |The pricing tier for the hosting plan.|
|workerCount|int| 0 |Target Worker Count.|
|webAppSlotList|string| '' |Comma delimited list of the Slot Names|
|vNetResourceGroup|string| '' |The name of the resource group containing the VNet to associate with.|
|vNetName|string| '' |The name of the VNet to associate with.|
|subNetName|string| '' |The name of the subnet on the VNet to associate with.|
|privateEndpointVnetName|string| '' |The name of the subnet for the private link. Leave blank for no private link.|
|privateEndpointSubnetName|string| '' |The name of the subnet for the private endpoint.|
|virtualDirectories|string| '' |Comma separate list of virtual directories/applications to create. If blank, only the root will be created.|

### Output Parameters
|Name|Data Type|Source Variable|Description|
|----|----|----|----|
|webAppName|string| webAppName | |
|hostingPlanName|string| hostingPlanName | |
|appInsightsName|string| appInsightsName | |
|webAppUrl|string| 'https://${webAppName}.azurewebsites.net' | |
|identityName|string| identityName | |
|identityPrincipalId|string| appIdentity.properties.principalId | |
|identityClientId|string| appIdentity.properties.clientId | |

## webapp.netcore.template.bicep

Template to deploy a web application targeting .NET Core.

This template to deploy a web application with App Insights and an App Service Plan created. Existing instances of App Insights
and App Service Plan can be specified in the template parameters. If not specified, new resources will be created based on template parameters.

Sites can optionally be deployed with slots. Using slots enables for production deployment with little or no downtime to end users. See [Set up staging environments - Azure App Service | Microsoft Learn](https://learn.microsoft.com/en-us/azure/app-service/deploy-staging-slots?tabs=portal) for details on the use of slots and swapping instances.

### Input Parameters
|Name|Data Type|Default Value|Description|
|----|----|----|----|
|department|string|  |Department code for the group responsible for the application.|
|appName|string|  |The name of the application.|
|environment|string|  |The name of the target environment (Dev/Test/Etc.).|
|useHostingPlan|string| '' |The name of the existing hosting plan to use. Must exist. If not specified, a new plan will be created.|
|useAppInsights|string| '' |The name of the App Insights instance to use. Must exist. If not specified, a new instance will be created.|
|useManagedIdentity|string| '' |The name of the User Managed Identity to use. Must exist. If not specified, a new instance will be created.|
|location|string| 'eastus' |Location for all resources.|
|alwaysOn|bool| false |Sets always on property for production slot only.|
|sku|string| 'S1' |The pricing tier for the hosting plan.|
|workerCount|int| 0 |Target Worker Count.|
|webAppSlotList|string| '' |Comma delimited list of the Slot Names|
|vNetResourceGroup|string| '' |The name of the resource group containing the VNet to associate with.|
|vNetName|string| '' |The name of the VNet to associate with.|
|subNetName|string| '' |The name of the subnet on the VNet to associate with.|
|privateEndpointVnetName|string| '' |The name of the subnet for the private link. Leave blank for no private link.|
|privateEndpointSubnetName|string| '' |The name of the subnet for the private endpoint.|
|virtualDirectories|string| '' |Comma separate list of virtual directories/applications to create. If blank, only the root will be created.|

### Output Parameters
|Name|Data Type|Source Variable|Description|
|----|----|----|----|
|webAppName|string| webAppName | |
|hostingPlanName|string| hostingPlanName | |
|appInsightsName|string| appInsightsName | |
|webAppUrl|string| 'https://${webAppName}.azurewebsites.net' | |
|identityName|string| identityName | |
|identityPrincipalId|string| appIdentity.properties.principalId | |
|identityClientId|string| appIdentity.properties.clientId | |

## webapp.netfx.template.bicep

Template to deploy a web application targeting .NET Framework 4.8.

This template to deploy a web application with App Insights and an App Service Plan created. Existing instances of App Insights
and App Service Plan can be specified in the template parameters. If not specified, new resources will be created based on template parameters.

Sites can optionally be deployed with slots. Using slots enables for production deployment with little or no downtime to end users. See [Set up staging environments - Azure App Service | Microsoft Learn](https://learn.microsoft.com/en-us/azure/app-service/deploy-staging-slots?tabs=portal) for details on the use of slots and swapping instances.
### Input Parameters
|Name|Data Type|Default Value|Description|
|----|----|----|----|
|department|string|  |Department code for the group responsible for the application.|
|appName|string|  |The name of the application.|
|environment|string|  |The name of the target environment (Dev/Test/Etc.).|
|useHostingPlan|string| '' |The name of the existing hosting plan to use. Must exist. If not specified, a new plan will be created.|
|useAppInsights|string| '' |The name of the App Insights instance to use. Must exist. If not specified, a new instance will be created.|
|useManagedIdentity|string| '' |The name of the User Managed Identity to use. Must exist. If not specified, a new instance will be created.|
|location|string| 'eastus' |Location for all resources.|
|alwaysOn|bool| false |Sets always on property for production slot only.|
|sku|string| 'S1' |The pricing tier for the hosting plan.|
|workerCount|int| 0 |Target Worker Count.|
|webAppSlotList|string| '' |Comma delimited list of the Slot Names|
|vNetResourceGroup|string| '' |The name of the resource group containing the VNet to associate with.|
|vNetName|string| '' |The name of the VNet to associate with.|
|subNetName|string| '' |The name of the subnet on the VNet to associate with.|
|privateEndpointVnetName|string| '' |The name of the subnet for the private link. Leave blank for no private link.|
|privateEndpointSubnetName|string| '' |The name of the subnet for the private endpoint.|
|virtualDirectories|string| '' |Comma separate list of virtual directories/applications to create. If blank, only the root will be created.|

### Output Parameters
|Name|Data Type|Source Variable|Description|
|----|----|----|----|
|webAppName|string| webAppName | |
|hostingPlanName|string| hostingPlanName | |
|appInsightsName|string| appInsightsName | |
|webAppUrl|string| 'https://${webAppName}.azurewebsites.net' | |
|identityName|string| identityName | |
|identityPrincipalId|string| appIdentity.properties.principalId | |
|identityClientId|string| appIdentity.properties.clientId | |