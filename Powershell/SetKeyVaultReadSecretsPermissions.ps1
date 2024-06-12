param (
    [Parameter(Mandatory=$true)]
    [string]
    $resourceGroup,
    [Parameter(Mandatory=$true)]
    [string]
    $keyVaultName,
    [Parameter(Mandatory=$true)]
    [string]
    $identityPrincipalId
)
# Example Usage: 
# .\SetKeyVaultReadSecretsPermissions.ps1 -resourceGroup 'ACG-DTS-EnterpriseAppServices-RG' -keyVaultName 'dts-apps-dev-kv' -identityPrincipalId "842e6324-f96c-4ee2-8db6-6050db461259" 
# Principal ID should be the *objectid* not the AppId. 
$ctx = Get-AzContext
$subscriptionId = $ctx.Subscription.Id 

New-AzRoleAssignment -RoleDefinitionName 'Key Vault Reader' -ObjectId $identityPrincipalId -Scope "/subscriptions/$subscriptionId/resourcegroups/$resourceGroup/providers/Microsoft.KeyVault/vaults/$keyVaultName"

New-AzRoleAssignment -RoleDefinitionName 'Key Vault Secrets User' -ObjectId $identityPrincipalId -Scope "/subscriptions/$subscriptionId/resourcegroups/$resourceGroup/providers/Microsoft.KeyVault/vaults/$keyVaultName"