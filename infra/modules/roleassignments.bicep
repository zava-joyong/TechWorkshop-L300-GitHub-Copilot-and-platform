// Role Assignments module for ZavaStorefront
// Assigns RBAC roles for managed identity to access ACR and AI Services

@description('The principal ID of the managed identity')
param principalId string

@description('The resource ID of the Container Registry')
param acrId string

@description('The resource ID of AI Services')
param aiServicesId string

// Built-in role definition IDs
var acrPullRoleId = '7f951dda-4ed3-4680-a7ca-43fe172d538d' // AcrPull
var cognitiveServicesUserRoleId = 'a97b65f3-24c7-4388-baec-2e87135dc908' // Cognitive Services User

// AcrPull role assignment for Container Registry
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acrId, principalId, acrPullRoleId)
  scope: acr
  properties: {
    principalId: principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', acrPullRoleId)
    principalType: 'ServicePrincipal'
  }
}

// Reference to existing ACR
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: last(split(acrId, '/'))
}

// Cognitive Services User role assignment for AI Services
resource cognitiveServicesUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aiServicesId, principalId, cognitiveServicesUserRoleId)
  scope: aiServices
  properties: {
    principalId: principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', cognitiveServicesUserRoleId)
    principalType: 'ServicePrincipal'
  }
}

// Reference to existing AI Services
resource aiServices 'Microsoft.CognitiveServices/accounts@2024-10-01' existing = {
  name: last(split(aiServicesId, '/'))
}

// Outputs
@description('The AcrPull role assignment ID')
output acrPullRoleAssignmentId string = acrPullRoleAssignment.id

@description('The Cognitive Services User role assignment ID')
output cognitiveServicesUserRoleAssignmentId string = cognitiveServicesUserRoleAssignment.id
