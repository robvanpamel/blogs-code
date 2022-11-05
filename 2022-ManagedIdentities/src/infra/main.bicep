@description('Managed Identies with Storage accounts')

param storageAccountType string = 'Standard_LRS'

@description('Location for the storage account.')
param location string = resourceGroup().location

@description('The name of the Storage Account')
param storageAccountName string = 'store${uniqueString(resourceGroup().id)}'

resource sa 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
  properties: {
  }
}

resource usermanagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  location: location
  name: 'myUserAssigndIdentity'
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

output storageAccountName string = storageAccountName
output storageAccountId string = sa.id
output usermangedIdentityId string = usermanagedIdentity.id
