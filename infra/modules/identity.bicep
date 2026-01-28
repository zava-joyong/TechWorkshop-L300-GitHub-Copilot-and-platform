// User-Assigned Managed Identity module for ZavaStorefront
// Provides RBAC-based authentication for App Service to access ACR and AI Services

@description('The location for the managed identity')
param location string

@description('The name of the managed identity')
param identityName string

@description('Tags to apply to the resource')
param tags object = {}

// User-Assigned Managed Identity
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
  tags: tags
}

// Outputs
@description('The resource ID of the managed identity')
output identityId string = managedIdentity.id

@description('The principal ID of the managed identity')
output principalId string = managedIdentity.properties.principalId

@description('The client ID of the managed identity')
output clientId string = managedIdentity.properties.clientId

@description('The name of the managed identity')
output identityName string = managedIdentity.name
