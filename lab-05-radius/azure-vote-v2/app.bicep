extension radius

@description('The Radius Application ID. Injected automatically by the rad CLI.')
param application string

resource demo 'Applications.Core/containers@2023-10-01-preview' = {
  name: 'demo'
  properties: {
    application: application
    container: {
      image: 'acrrfp000.azurecr.io/azure-vote-front:v1'
      ports: {
        web: {
          containerPort: 80
        }
      }
    }
    connections: {
      redis: {
        source: db.id
      }
    }
  }
}

@description('The environment ID of your Radius Application. Set automatically by the rad CLI.')
param environment string

resource db 'Applications.Datastores/redisCaches@2023-10-01-preview' = {
  name: 'db'
  properties: {
    application: application
    environment: environment
  }
}
