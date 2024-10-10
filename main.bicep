param appName string = 'album-api-test'
param dbName string = 'album-db-test'
param envName string = 'env-album-containerapps-test'
param logWorkspaceName string = 'workspace-albumcontainerapps-test'
param location string = resourceGroup().location

resource logWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logWorkspaceName 
  location: location
}

resource dbaccount 'Microsoft.DocumentDB/databaseAccounts@2024-05-15' = {
  name: dbName
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
  name: 'main'
  parent: dbaccount
  properties: {
    resource: {
      id: 'main'
    }
  }
}

resource dbcontainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-05-15' = {
  name: 'albums'
  parent: db
  properties: {
    resource: {
      id: 'albums'
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
  name: 'appdb'
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
