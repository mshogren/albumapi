param rgName string = resourceGroup().name
param location string = resourceGroup().location
var appName = 'album-api-${rgName}'
var dbAccountName = 'db-${rgName}'
var dbName = 'main'
var dbContainerName = 'albums'
var envName = 'env-${rgName}'
var logWorkspaceName = 'workspace-${rgName}'
var connectorName = 'linker-${dbAccountName}-${dbName}'

resource logWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logWorkspaceName 
  location: location
}

resource dbaccount 'Microsoft.DocumentDB/databaseAccounts@2024-05-15' = {
  name: dbAccountName
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    enableFreeTier: true
    locations: [
      { 
        locationName: location
      }
    ]
  }
}

resource db 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2024-05-15' = {
  name: dbName
  parent: dbaccount
  properties: {
    resource: {
      id: dbName
    }
  }
}

resource dbcontainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-05-15' = {
  name: dbContainerName
  parent: db
  properties: {
    resource: {
      id: dbContainerName
      partitionKey: {
        paths: [
          '/id'
        ]
      }
    }
  }
}

resource containerappenv 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: envName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logWorkspace.properties.customerId
        sharedKey: logWorkspace.listKeys().primarySharedKey
      }
    }
  }
}

resource containerapp 'Microsoft.App/containerApps@2024-03-01' = {
  name: appName
  location: location
  properties: {
    environmentId: containerappenv.id
    configuration: {
      ingress: {
        external: true
        targetPort: 8080
      }
    }
    template: {
      containers: [
        {
          name: appName
          image: 'ghcr.io/mshogren/albumapi:main'
        }
      ]
    }
  }
}

resource serviceConnector 'Microsoft.ServiceLinker/linkers@2024-07-01-preview' = {
  name: connectorName
  scope: containerapp
  properties: {
    clientType: 'dotnet'
    scope: appName
    targetService: {
      type:'AzureResource'
      id: db.id
    }
    authInfo: {
      authType: 'systemAssignedIdentity'
    }
  }
}
