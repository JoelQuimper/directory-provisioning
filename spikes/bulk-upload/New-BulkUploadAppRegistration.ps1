[CmdletBinding()]
param(
    [string] $DisplayName = 'Directory Provisioning - Bulk Upload Spike'
)

$ErrorActionPreference = 'Stop'

$application = az ad app create `
    --display-name $DisplayName `
    --sign-in-audience AzureADMyOrg `
    --output json |
    ConvertFrom-Json

$servicePrincipal = az ad sp create `
    --id $application.appId `
    --output json |
    ConvertFrom-Json

$graphApplicationId = '00000003-0000-0000-c000-000000000000'

$uploadPermissionId = az ad sp show `
    --id $graphApplicationId `
    --query "appRoles[?value=='SynchronizationData-User.Upload'].id | [0]" `
    --output tsv

$provisioningLogPermissionId = az ad sp show `
    --id $graphApplicationId `
    --query "appRoles[?value=='ProvisioningLog.Read.All'].id | [0]" `
    --output tsv

az ad app permission add `
    --id $application.appId `
    --api $graphApplicationId `
    --api-permissions `
        "$uploadPermissionId=Role" `
        "$provisioningLogPermissionId=Role"

az ad app permission admin-consent `
    --id $application.appId

$credential = az ad app credential reset `
    --id $application.appId `
    --append `
    --display-name bulk-upload-spike `
    --years 1 `
    --output json |
    ConvertFrom-Json

$tenantId = az account show `
    --query tenantId `
    --output tsv

[pscustomobject]@{
    TenantId           = $tenantId
    ClientId           = $application.appId
    ClientSecret       = $credential.password
    ApplicationId      = $application.id
    ServicePrincipalId = $servicePrincipal.id
    Scope              = 'https://graph.microsoft.com/.default'
    Permissions        = @(
        'SynchronizationData-User.Upload'
        'ProvisioningLog.Read.All'
    )
}
