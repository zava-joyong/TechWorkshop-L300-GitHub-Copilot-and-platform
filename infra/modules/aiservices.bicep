// Azure AI Services module for ZavaStorefront
// Provides access to GPT-4 and Phi models via Microsoft Foundry

@description('The location for the AI Services resource')
param location string

@description('The name of the AI Services account')
param aiServicesName string

@description('The SKU for AI Services')
@allowed(['S0'])
param sku string = 'S0'

@description('Tags to apply to the resource')
param tags object = {}

// Azure AI Services (Cognitive Services multi-service account)
resource aiServices 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: aiServicesName
  location: location
  tags: tags
  kind: 'AIServices'
  sku: {
    name: sku
  }
  properties: {
    customSubDomainName: aiServicesName
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
    }
    disableLocalAuth: false // Allow key-based auth for dev, but prefer managed identity
  }
  identity: {
    type: 'SystemAssigned'
  }
}

// Outputs
@description('The resource ID of AI Services')
output aiServicesId string = aiServices.id

@description('The endpoint of AI Services')
output endpoint string = aiServices.properties.endpoint

@description('The name of AI Services')
output aiServicesName string = aiServices.name
