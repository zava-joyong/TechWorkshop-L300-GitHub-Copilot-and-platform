// App Service Plan and Web App module for ZavaStorefront
// Hosts the containerized .NET 6.0 web application

@description('The location for the App Service resources')
param location string

@description('The name of the App Service Plan')
param appServicePlanName string

@description('The name of the Web App')
param webAppName string

@description('The SKU for the App Service Plan')
param sku string = 'B1'

@description('The resource ID of the user-assigned managed identity')
param managedIdentityId string

@description('The client ID of the user-assigned managed identity')
param managedIdentityClientId string

@description('The ACR login server URL')
param acrLoginServer string

@description('The Application Insights connection string')
param appInsightsConnectionString string

@description('The Azure AI Services endpoint')
param aiServicesEndpoint string

@description('The resource ID of the Log Analytics workspace for diagnostics')
param logAnalyticsWorkspaceId string

@description('Tags to apply to the resources')
param tags object = {}

@description('The azd service name tag for the web app')
param serviceName string = 'web'

// App Service Plan (Linux)
resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  kind: 'linux'
  sku: {
    name: sku
    tier: sku == 'B1' ? 'Basic' : 'Standard'
  }
  properties: {
    reserved: true // Required for Linux
  }
}

// Web App
resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: webAppName
  location: location
  tags: union(tags, {
    'azd-service-name': serviceName
  })
  kind: 'app,linux,container'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|6.0' // Initial runtime, will be overwritten by container
      acrUseManagedIdentityCreds: true
      acrUserManagedIdentityID: managedIdentityClientId
      alwaysOn: false // Dev environment
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      http20Enabled: true
      cors: {
        allowedOrigins: [
          'https://portal.azure.com'
        ]
        supportCredentials: false
      }
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'AZURE_AI_SERVICES_ENDPOINT'
          value: aiServicesEndpoint
        }
        {
          name: 'AZURE_CLIENT_ID'
          value: managedIdentityClientId
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${acrLoginServer}'
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
      ]
    }
  }
}

// Diagnostic Settings for Web App
resource webAppDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${webAppName}-diagnostics'
  scope: webApp
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
      }
      {
        category: 'AppServiceAppLogs'
        enabled: true
      }
      {
        category: 'AppServicePlatformLogs'
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
@description('The resource ID of the App Service Plan')
output appServicePlanId string = appServicePlan.id

@description('The resource ID of the Web App')
output webAppId string = webApp.id

@description('The default hostname of the Web App')
output webAppHostname string = webApp.properties.defaultHostName

@description('The name of the Web App')
output webAppName string = webApp.name

@description('The principal ID of the Web App system-assigned identity')
output webAppPrincipalId string = webApp.identity.userAssignedIdentities[managedIdentityId].principalId
