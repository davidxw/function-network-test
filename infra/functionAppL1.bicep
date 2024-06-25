
param blobStorageAccountName string
param functionAppName string
param backendSubnetId string
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
  properties: {
    httpsOnly: true
    serverFarmId: appService.id
    virtualNetworkSubnetId: backendSubnetId
    vnetRouteAllEnabled: true
    clientAffinityEnabled: true
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
      DOWNSTREAM: ''
    }
  }
}

