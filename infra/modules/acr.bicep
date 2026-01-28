// Azure Container Registry module for ZavaStorefront
// Stores Docker images for App Service deployment

@description('The location for the container registry')
param location string

@description('The name of the container registry')
param registryName string

@description('The SKU for the container registry')
@allowed(['Basic', 'Standard', 'Premium'])
param sku string = 'Basic'

@description('Tags to apply to the resource')
param tags object = {}

// Azure Container Registry
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: registryName
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: false // Use Azure RBAC instead of admin credentials
    publicNetworkAccess: 'Enabled'
    policies: {
      quarantinePolicy: {
        status: 'disabled'
      }
      trustPolicy: {
        type: 'Notary'
        status: 'disabled'
      }
      retentionPolicy: {
        days: 7
        status: 'disabled'
      }
    }
  }
}

// Outputs
@description('The resource ID of the container registry')
output registryId string = containerRegistry.id

@description('The login server of the container registry')
output loginServer string = containerRegistry.properties.loginServer

@description('The name of the container registry')
output registryName string = containerRegistry.name
