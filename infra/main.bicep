// Main Bicep template for ZavaStorefront Azure Infrastructure
// Deploys all resources for the dev environment using AZD

targetScope = 'resourceGroup'

// ============================================================================
// Parameters
// ============================================================================

@description('The environment name (e.g., dev, staging, prod)')
param environmentName string

@description('The Azure region for resource deployment')
param location string

@description('Tags to apply to all resources')
param tags object = {}

// ============================================================================
// Variables
// ============================================================================

// Generate unique resource token based on subscription, resource group, location, and environment
var resourceToken = uniqueString(subscription().id, resourceGroup().id, location, environmentName)

// Resource naming convention: az{prefix}{resourceToken}
var identityName = 'azid${resourceToken}'
var acrName = 'azacr${resourceToken}'
var logAnalyticsName = 'azlog${resourceToken}'
var appInsightsName = 'azai${resourceToken}'
var aiServicesName = 'azais${resourceToken}'
var appServicePlanName = 'azasp${resourceToken}'
var webAppName = 'azapp${resourceToken}'

// Merge default tags with provided tags
var defaultTags = {
  'azd-env-name': environmentName
  environment: environmentName
  application: 'ZavaStorefront'
}
var allTags = union(defaultTags, tags)

// ============================================================================
// Modules
// ============================================================================

// User-Assigned Managed Identity
module identity 'modules/identity.bicep' = {
  name: 'identity-deployment'
  params: {
    location: location
    identityName: identityName
    tags: allTags
  }
}

// Azure Container Registry
module acr 'modules/acr.bicep' = {
  name: 'acr-deployment'
  params: {
    location: location
    registryName: acrName
    sku: 'Basic'
    tags: allTags
  }
}

// Application Insights and Log Analytics
module monitoring 'modules/appinsights.bicep' = {
  name: 'monitoring-deployment'
  params: {
    location: location
    logAnalyticsName: logAnalyticsName
    appInsightsName: appInsightsName
    tags: allTags
  }
}

// Azure AI Services
module aiServices 'modules/aiservices.bicep' = {
  name: 'aiservices-deployment'
  params: {
    location: location
    aiServicesName: aiServicesName
    sku: 'S0'
    tags: allTags
  }
}

// App Service (Web App)
module appService 'modules/appservice.bicep' = {
  name: 'appservice-deployment'
  params: {
    location: location
    appServicePlanName: appServicePlanName
    webAppName: webAppName
    sku: 'B1'
    managedIdentityId: identity.outputs.identityId
    managedIdentityClientId: identity.outputs.clientId
    acrLoginServer: acr.outputs.loginServer
    appInsightsConnectionString: monitoring.outputs.connectionString
    aiServicesEndpoint: aiServices.outputs.endpoint
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsId
    tags: allTags
    serviceName: 'web'
  }
}

// Role Assignments
module roleAssignments 'modules/roleassignments.bicep' = {
  name: 'roleassignments-deployment'
  params: {
    principalId: identity.outputs.principalId
    acrId: acr.outputs.registryId
    aiServicesId: aiServices.outputs.aiServicesId
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('The resource group ID')
output RESOURCE_GROUP_ID string = resourceGroup().id

@description('The name of the resource group')
output RESOURCE_GROUP_NAME string = resourceGroup().name

@description('The Azure region')
output AZURE_LOCATION string = location

@description('The managed identity resource ID')
output MANAGED_IDENTITY_ID string = identity.outputs.identityId

@description('The managed identity client ID')
output MANAGED_IDENTITY_CLIENT_ID string = identity.outputs.clientId

@description('The ACR login server')
output ACR_LOGIN_SERVER string = acr.outputs.loginServer

@description('The ACR name')
output ACR_NAME string = acr.outputs.registryName

@description('The Application Insights connection string')
output APPLICATIONINSIGHTS_CONNECTION_STRING string = monitoring.outputs.connectionString

@description('The AI Services endpoint')
output AZURE_AI_SERVICES_ENDPOINT string = aiServices.outputs.endpoint

@description('The Web App hostname')
output WEB_APP_HOSTNAME string = appService.outputs.webAppHostname

@description('The Web App name')
output WEB_APP_NAME string = appService.outputs.webAppName

@description('The Web App URL')
output WEB_APP_URL string = 'https://${appService.outputs.webAppHostname}'
