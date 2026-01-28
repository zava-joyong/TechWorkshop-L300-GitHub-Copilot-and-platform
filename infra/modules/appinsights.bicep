// Application Insights and Log Analytics module for ZavaStorefront
// Provides monitoring, logging, and APM capabilities

@description('The location for the resources')
param location string

@description('The name of the Log Analytics workspace')
param logAnalyticsName string

@description('The name of the Application Insights resource')
param appInsightsName string

@description('Tags to apply to the resources')
param tags object = {}

// Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      searchVersion: 1
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: 1 // Dev environment cap
    }
  }
}

// Application Insights
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Outputs
@description('The resource ID of the Log Analytics workspace')
output logAnalyticsId string = logAnalyticsWorkspace.id

@description('The workspace ID of the Log Analytics workspace')
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.properties.customerId

@description('The resource ID of Application Insights')
output appInsightsId string = applicationInsights.id

@description('The instrumentation key of Application Insights')
output instrumentationKey string = applicationInsights.properties.InstrumentationKey

@description('The connection string of Application Insights')
output connectionString string = applicationInsights.properties.ConnectionString

@description('The name of Application Insights')
output appInsightsName string = applicationInsights.name
