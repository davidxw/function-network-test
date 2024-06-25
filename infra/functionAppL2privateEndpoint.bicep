
param blobStorageAccountName string
param functionAppName string
param privateEndpointSubnetId string
param virtualNetworkId string
param location string

var functionAppPlanName = '${functionAppName}-plan'

resource blobStorageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: blobStorageAccountName
}

var blobStorageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${blobStorageAccount.name};AccountKey=${blobStorageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'

// Function App
resource appService 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: functionAppPlanName
  location: location
  sku: {
    name: 'EP1'
    tier: 'ElasticPremium'
  }
  kind: 'elastic'
  properties: {
    maximumElasticWorkerCount: 1
    reserved: true
  }
}

resource functionApp 'Microsoft.Web/sites@2020-06-01' = {
  name: functionAppName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  kind: 'functionapp,linux'
  properties:  {
    httpsOnly: true
    serverFarmId: appService.id
    clientAffinityEnabled: true
    publicNetworkAccess: 'Disabled'
    siteConfig: {
      linuxFxVersion: 'DOTNET-ISOLATED|8.0'
    }
  } 
  resource config 'config@2022-09-01' = {
    name: 'appsettings'
    properties: {
      AzureWebJobsStorage: blobStorageConnectionString
      FUNCTIONS_EXTENSION_VERSION: '~4'
      FUNCTIONS_WORKER_RUNTIME: 'dotnet-isolated'
      WEBSITE_CONTENTSHARE: toLower(functionAppName)
      WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: blobStorageConnectionString
    }
  }
}

resource functionPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: 'pe-${functionAppName}-sites'
  location: location
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'plsc-${functionAppName}-sites'
        properties: {
          privateLinkServiceId: functionApp.id
          groupIds: [
            'sites'
          ]
        }
      }
    ]
  }
}

resource functionPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.azurewebsites.net'
  location: 'global'
}

resource functionPrivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: functionPrivateDnsZone
  name: '${functionPrivateDnsZone.name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetworkId
    }
  }
}

resource functionPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-02-01' = {
  parent: functionPrivateEndpoint
  name: 'functionPrivateDnsZoneGroup'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config'
        properties: {
          privateDnsZoneId: functionPrivateDnsZone.id
        }
      }
    ]
  }
}

