//  RUN WITH 
// az deployment group create --resource-group rg-blog-managed-identities-storage --template-file main.bicep

@description('Managed Identies with Storage accounts')

param storageAccountType string = 'Standard_LRS'

@description('Location for the storage account.')
param location string = resourceGroup().location

@description('The name of the Storage Account')
param storageAccountName string = 'safct${uniqueString(resourceGroup().id)}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
  properties: {
  }
  tags:{
    blog: 'blog-managed-identities-storage'
  }
}

resource usermanagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  location: location
  name: 'uai-blobcontributer'
  tags: {
    blog: 'blog-managed-identities-storage'
  }
}

@description('This is the built-in Storage Blob Data Contributor role. See https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#contributor')
resource contributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, usermanagedIdentity.id, contributorRoleDefinition.id)
  properties:{ 
    principalId: usermanagedIdentity.properties.principalId 
    roleDefinitionId: contributorRoleDefinition.id
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  location: location
  name: 'asp-blog-managed-identities'
  kind: 'linux'
  sku:{
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties:{
    reserved: true
  }
  tags:{
    blog: 'blog-managed-identities-storage'
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'ai-fct-blobwriter'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
  }
}

resource functionApp 'Microsoft.Web/sites@2022-03-01'={
  name: 'fct-blobwriter'
  location: location
  kind: 'functionapp'
  identity: {
     type: 'UserAssigned'
     userAssignedIdentities: {
      '${usermanagedIdentity.id}': {}
     }
  }
  properties:{
    serverFarmId: appServicePlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights.properties.InstrumentationKey
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet-isolated'
        }
        {
          name: 'AZURE_CLIENT_ID'
          value: usermanagedIdentity.properties.clientId 
        }
      ]
      minTlsVersion: '1.2'
    }
    httpsOnly: true
  }
}

output storageAccountName string = storageAccountName
output storageAccountId string = storageAccount.id
output usermangedIdentityId string = usermanagedIdentity.id
