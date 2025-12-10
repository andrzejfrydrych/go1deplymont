@description('Location for all resources')
param location string = resourceGroup().location

@description('Name of the Azure Container Registry')
param acrName string

@description('Name of the Log Analytics workspace')
param lawName string = 'go1-logs'

@description('Name of the Container Apps environment')
param envName string = 'go1-env'

@description('Name of the Container App')
param appName string = 'go1-app'

@description('Container image name (without registry)')
param imageRepo string = 'go1deplymont'

@description('Container image tag')
param imageTag string = 'latest'

/* ACR */
resource acr 'Microsoft.ContainerRegistry/registries@2019-05-01' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
}

/* Log Analytics */
resource law 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: lawName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

/* Container Apps Env */
resource env 'Microsoft.App/managedEnvironments@2022-03-01' = {
  name: envName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: law.properties.customerId
        sharedKey: law.listKeys().primarySharedKey
      }
    }
  }
}

/* Container App */
resource app 'Microsoft.App/containerApps@2022-03-01' = {
  name: appName
  location: location
  properties: {
    managedEnvironmentId: env.id
    configuration: {
      ingress: {
        external: true
        targetPort: 8080   // tu port z Dockerfile / aplikacji
      }
      registries: [
        {
          server: acr.properties.loginServer
          username: acr.listCredentials().username
          passwordSecretRef: 'acr-pwd'
        }
      ]
      secrets: [
        {
          name: 'acr-pwd'
          value: acr.listCredentials().passwords[0].value
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'go1-container'
          image: '${acr.properties.loginServer}/${imageRepo}:${imageTag}'
        }
      ]
    }
  }
}

output fqdn string = app.properties.configuration.ingress.fqdn
output acrLoginServer string = acr.properties.loginServer
