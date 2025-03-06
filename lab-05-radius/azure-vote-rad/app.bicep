extension radius

@description('The Radius Application ID. Injected automatically by the rad CLI.')
param application string

resource votefront 'Applications.Core/containers@2023-10-01-preview' = {
  name: 'votefront'
  properties: {
    application: application
    container: {
      image: 'acrrfp000.azurecr.io/azure-vote-front:v3-rad'
      ports: {
        web: {
          containerPort: 80
        }
      }
    }
    connections: {
      redis: {
        source: voteback.id
      }
    }
  }
}

@description('The environment ID of your Radius Application. Set automatically by the rad CLI.')
param environment string

resource voteback 'Applications.Datastores/redisCaches@2023-10-01-preview' = {
  name: 'voteback'
  properties: {
    application: application
    environment: environment
  }
}
