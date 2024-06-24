param vnetName string = 'vnet'
param blobStorageAccountName string = 'blob'
param functionAppL1Name1 string = 'functionAppL1-1'
param functionAppL1Name2 string = 'functionAppL1-2'
param functionAppL2Name1 string = 'functionAppL2-1'
param functionAppL2Name2 string = 'functionAppL2-2'

param location string = resourceGroup().location
param resourceToken string = toLower(uniqueString(subscription().id, resourceGroup().id, location))

var functionAppL1Name1Token = toLower('${functionAppL1Name1}-${resourceToken}')
var functionAppL1Name2Token = toLower('${functionAppL1Name2}-${resourceToken}')
var functionAppL2Name1Token = toLower('${functionAppL2Name1}-${resourceToken}')
var functionAppL2Name2Token = toLower('${functionAppL2Name2}-${resourceToken}')

var vnetNameToken = toLower('${vnetName}-${resourceToken}')
var blobStorageAccountNameToken = toLower('${blobStorageAccountName}${resourceToken}')

var vnetCidr = '10.1.0.0/16'

var subnet1name = 'subnet1'
var subnet1cidr = '10.1.1.0/24'

var subnet2name = 'subnet2'
var subnet2cidr = '10.1.2.0/24'

// Virtual network with two subnets, one each for the backend of each L1 function

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vnetNameToken
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetCidr
      ]
    }
  }
}

resource subnet1 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = {
  name: subnet1name
  parent: vnet
  properties: {
    addressPrefix: subnet1cidr
    serviceEndpoints: [
      {
        service: 'Microsoft.Web'
        locations: [
          '*'
        ]
      }
    ]
    delegations: [
      {
        name: '0'
        properties: {
          serviceName: 'Microsoft.Web/serverFarms'
        }
      }
    ]
  }
}

resource subnet2 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = {
  name: subnet2name
  parent: vnet
  properties: {
    addressPrefix: subnet2cidr
    serviceEndpoints: [
      {
        service: 'Microsoft.Web'
        locations: [
          '*'
        ]
      }
    ]
    delegations: [
      {
        name: '0'
        properties: {
          serviceName: 'Microsoft.Web/serverFarms'
        }
      }
    ]
  }
}

// blob storage account

resource blobStorageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: blobStorageAccountNameToken
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
  }
}

// function app L1 1
module functionAppL1_1 './functionApp.bicep' = {
  name: functionAppL1Name1Token
  params: {
    location: location
    blobStorageAccountName: blobStorageAccount.name
    functionAppName: functionAppL1Name1Token
    backendSubnetId: subnet1.id
  }
}

// function app L1 2
module functionAppL1_2 './functionApp.bicep' = {
  name: functionAppL1Name2Token
  params: {
    location: location
    blobStorageAccountName: blobStorageAccount.name
    functionAppName: functionAppL1Name2Token
    backendSubnetId: subnet2.id
  }
}

// function app L2 1
module functionAppL2_1 './functionApp.bicep' = {
  name: functionAppL2Name1Token
  params: {
    location: location
    blobStorageAccountName: blobStorageAccount.name
    functionAppName: functionAppL2Name1Token
    inboundSubnetId: subnet1.id
  }
}

// function app L2 2
module functionAppL2_2 './functionApp.bicep' = {
  name: functionAppL2Name2Token
  params: {
    location: location
    blobStorageAccountName: blobStorageAccount.name
    functionAppName: functionAppL2Name2Token
    inboundSubnetId: subnet2.id
  }
}
