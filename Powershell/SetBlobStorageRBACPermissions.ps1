param (
    [Parameter(Mandatory=$true, HelpMessage='The name of the resource group containing the storage account')]
    [string]
    $resourceGroup,

    [Parameter(Mandatory=$true, HelpMessage='The name of the storage account add permissions to.')]
    [string]
    $storageAccountName,

    [Parameter(Mandatory=$true, HelpMessage='The Entra ID for the identity. ')]
    [string]
    $identityPrincipalId, 

    [Parameter(Mandatory = $false, HelpMessage='Switch to set standard read permissions to Blob Storage')]
    [bool]
    $setRead = $true, 

    [Parameter(Mandatory = $false, HelpMessage='Switch to set standard write permissions to Blob Storage')]
    [bool]
    $setWrite = $false,

    [Parameter(Mandatory = $false, HelpMessage='Switch to set standard permissions required for function apps.')]
    [bool]
    $functionAppPerms = $false,

    [Parameter(Mandatory = $false, HelpMessage='An array of strings with additional/other roles that may be required.')]
    [string[]]
    $additionalRoles = @()
)
#Example Usage: 
# .\SetBlobStorageRBACPermissions.ps1 -resourceGroup "acg-dts-enterpriseappservices-rg" -storageAccountName "dtspropertysearchdevst" -identityPrincipalId "842e6324-f96c-4ee2-8db6-6050db461259"
# Principal ID should be the *objectid* not the AppId. 
$ctx = Get-AzContext
$subscriptionId = $ctx.Subscription.Id 

if($setRead){
    New-AzRoleAssignment -RoleDefinitionName 'Storage Blob Data Reader' -ObjectId $identityPrincipalId -Scope "/subscriptions/$subscriptionId/resourcegroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageAccountName"
}
if($setWrite){
    New-AzRoleAssignment -RoleDefinitionName 'Storage Blob Data Contributor' -ObjectId $identityPrincipalId -Scope "/subscriptions/$subscriptionId/resourcegroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageAccountName"
}
if($functionAppPerms){
    New-AzRoleAssignment -RoleDefinitionName 'Storage Account Contributor' -ObjectId $identityPrincipalId -Scope "/subscriptions/$subscriptionId/resourcegroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageAccountName"
}
foreach ($role in $additionalRoles){
    Write-Host "Adding $role"
    New-AzRoleAssignment -RoleDefinitionName $role -ObjectId $identityPrincipalId -Scope "/subscriptions/$subscriptionId/resourcegroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageAccountName"
}
