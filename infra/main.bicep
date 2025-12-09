@description('Location for all resources')
param location string = resourceGroup().location

@description('Name of the Azure Container Registry')
param acrName string

@description('Name of the Log Analytics workspace')
param lawName string = 'go1-logs'

@description('Name of the Container Apps environment')
param envName string = 'go1-env'

/* ACR */
resource acr 'Microsoft.ContainerRegistry/registries@2019-05-01' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    /* bettern not use on production: */
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

/* Container Apps Environment */
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

output acrLoginServer string = acr.properties.loginServer
output envNameOut string = env.name
