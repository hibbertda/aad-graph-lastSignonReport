#Requires -Modules {AzureAD}

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)][string]$TenantID,          # Azure Active Directory TenantID
    [Parameter(Mandatory=$true)][string]$MSIDisplayName     # Matches the resource name
)

# Microsoft Graph App ID (DON'T CHANGE)
$GraphAppId = "00000003-0000-0000-c000-000000000000"

$requiredPermissions = @(
    'Domain.Read.All',
    'AuditLog.Read.All',
    'User.Read.All'
)

Connect-AzureAD -TenantId $TenantID

$MSI = (Get-AzureADServicePrincipal -Filter "displayName eq '$MSIDisplayName'")

$GraphServicePrincipal = Get-AzureADServicePrincipal -Filter "appId eq '$GraphAppId'"

$AppRole = @()

$requiredPermissions | ForEach-Object {
    $permissionName = $_
    $temp = $GraphServicePrincipal.AppRoles | `
        Where-Object {$_.Value -eq $permissionName -and $_.AllowedMemberTypes -contains "Application"}

    $AppRole += $temp
}

#Assign permissions to Managed Identity
# NOTE: This will throw and error if the permission is already applied. 
$AppRole | ForEach-Object {
    New-AzureAdServiceAppRoleAssignment -ObjectId $MSI.ObjectId `
        -PrincipalId $MSI.ObjectId `
        -ResourceId $GraphServicePrincipal.ObjectId `
        -Id $_.Id
}
