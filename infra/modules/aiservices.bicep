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

@description('The resource ID of the Log Analytics workspace for diagnostics')
param logAnalyticsWorkspaceId string

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
    disableLocalAuth: true // Enforce managed identity only - no API keys
  }
  identity: {
    type: 'SystemAssigned'
  }
}

// Phi-4 Model Deployment
resource phi4Deployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: aiServices
  name: 'Phi-4'
  sku: {
    name: 'GlobalStandard'
    capacity: 1
  }
  properties: {
    model: {
      format: 'Microsoft'
      name: 'Phi-4'
      version: '7'
    }
    raiPolicyName: 'Microsoft.DefaultV2'
  }
}

// Diagnostic Settings for AI Services - sends all logs to Log Analytics
resource aiServicesDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${aiServicesName}-diagnostics'
  scope: aiServices
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'Audit'
        enabled: true
      }
      {
        category: 'RequestResponse'
        enabled: true
      }
      {
        category: 'Trace'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// Outputs
@description('The resource ID of AI Services')
output aiServicesId string = aiServices.id

@description('The endpoint of AI Services')
output endpoint string = aiServices.properties.endpoint

@description('The name of AI Services')
output aiServicesName string = aiServices.name
