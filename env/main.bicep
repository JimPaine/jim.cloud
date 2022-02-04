targetScope = 'resourceGroup'

var suffix = '${toLower(uniqueString(subscription().id, resourceGroup().id))}'
var location = resourceGroup().location

resource cdn 'Microsoft.Cdn/profiles@2020-09-01' = {
  name: 'cdn${suffix}'
  location: 'Global'
  sku: {
    name: 'Standard_Microsoft'
  }
  properties: {}
}

resource storage 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: 'blob${suffix}'
  location: location
  kind: 'BlobStorage'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    accessTier: 'Hot'
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
}

resource blob 'Microsoft.Storage/storageAccounts/blobServices@2021-06-01' = {
  parent: storage

  name: 'default'
  properties: {}
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-06-01' = {
  parent: blob

  name: 'jimcloud'
  properties: {
    publicAccess: 'None'
  }
}

resource endpoint 'Microsoft.Cdn/profiles/endpoints@2020-09-01' = {
  parent: cdn

  name: 'jimcloud${suffix}'
  location: 'Global'
  properties: {
    originPath: '/${container.name}'
    origins: [
      {
        name: storage.name
        properties: {
          hostName: '${replace(replace(storage.properties.primaryEndpoints.blob, 'https://', ''), '/', '')}'
        }
      }
    ]
    deliveryPolicy: {
      rules: [
        {
          name: 'httpsOnly'
          order: 1
          actions: [
            {
              name: 'UrlRedirect'
              parameters: {
                '@odata.type': '#Microsoft.Azure.Cdn.Models.DeliveryRuleUrlRedirectActionParameters'
                redirectType: 'PermanentRedirect'
                destinationProtocol: 'Https'
              }
            }
          ]
          conditions: [
            {
              name: 'RequestScheme'
              parameters: {
                operator: 'Equal'
                negateCondition: false
                '@odata.type': '#Microsoft.Azure.Cdn.Models.DeliveryRuleRequestSchemeConditionParameters'
                matchValues: [
                  'HTTP'
                ]
              }
            }
          ]
        }
      ]
    }
  }
}
