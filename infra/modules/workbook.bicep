// Azure Workbook module for AI Services Observability
// Visualizes request volume, latency percentiles, and operation breakdown

@description('The location for the workbook resource')
param location string

@description('The name of the workbook')
param workbookName string

@description('The resource ID of the Log Analytics workspace')
param logAnalyticsWorkspaceId string

@description('Tags to apply to the resource')
param tags object = {}

// Load workbook content from external JSON file
var workbookContent = loadTextContent('workbook-ai-observability.json')

// Azure Workbook resource
resource workbook 'Microsoft.Insights/workbooks@2023-06-01' = {
  name: guid(resourceGroup().id, workbookName)
  location: location
  tags: union(tags, {
    'hidden-title': workbookName
  })
  kind: 'shared'
  properties: {
    displayName: workbookName
    category: 'workbook'
    sourceId: logAnalyticsWorkspaceId
    serializedData: workbookContent
  }
}

// Outputs
@description('The resource ID of the workbook')
output workbookId string = workbook.id

@description('The name of the workbook')
output workbookName string = workbook.properties.displayName
