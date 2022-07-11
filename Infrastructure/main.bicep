param appName string
param location string = resourceGroup().location

/*  App Insights and Log Analytics */
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: '${appName}-logs'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${appName}-insights'
  location: location
  kind: 'web'
  properties: {
    WorkspaceResourceId: logAnalytics.id
    Application_Type: 'web'
  }
}

/*  
  API Management 
  Creates an API Management service, App Insights logger, APIs, and API Policies  
*/
resource apiManagementService 'Microsoft.ApiManagement/service@2021-08-01' = {
  name: '${appName}-api'
  location: location
  sku: {
    name: 'Developer'
    capacity: 1
  }
  properties: {
    publisherEmail: 'example@example.org'
    publisherName: 'Example Exampleston'
  }
}

// App Insights logger
resource apiManagementLogger 'Microsoft.ApiManagement/service/loggers@2021-12-01-preview' = {
  name: '${appName}logger'
  parent: apiManagementService
  properties: {
    credentials: {
      instrumentationKey: applicationInsights.properties.InstrumentationKey
    }
    loggerType: 'applicationInsights'
    resourceId: applicationInsights.id
  }
}

// Show Me Vax API definition and API policies
resource showMeVaxApi 'Microsoft.ApiManagement/service/apis@2021-12-01-preview' = {
  name: 'ShowMeVax'
  parent: apiManagementService
  properties: {
    path: 'smv'
    displayName: 'Show Me Vax'
    subscriptionRequired: false
    protocols: [
      'https'
    ]
  }
}

// Get Required Vaccinations operation
resource showMeVaxRequiredOperation 'Microsoft.ApiManagement/service/apis/operations@2021-12-01-preview' = {
  name: 'GetRequiredVaccinations'
  parent: showMeVaxApi
  properties: {
    displayName: 'GetRequiredVaccinations'
    method: 'GET'
    request: {
      description: 'string'
    }
    urlTemplate: '/'
  }
}

resource showMeVaxRequiredPolicy 'Microsoft.ApiManagement/service/apis/operations/policies@2021-12-01-preview' = {
  name: 'policy'
  parent: showMeVaxRequiredOperation
  properties: {
    format: 'xml'
    value: loadTextContent('api-management-policy/showMeVax-get-required.xml')
  }
}

// Refresh operation
resource showMeVaxRefreshOperation 'Microsoft.ApiManagement/service/apis/operations@2021-12-01-preview' = {
  name: 'Refresh'
  parent: showMeVaxApi
  properties: {
    displayName: 'Refresh'
    method: 'GET'
    request: {
      description: 'string'
    }
    urlTemplate: '/invoke'
  }
}

resource showMeVaxRefreshPolicy 'Microsoft.ApiManagement/service/apis/operations/policies@2021-12-01-preview' = {
  name: 'policy'
  parent: showMeVaxRefreshOperation
  properties: {
    format: 'xml'
    value: loadTextContent('api-management-policy/showMeVax-refresh.xml')
  }
}

// Medicaid API definition and API policies
resource medicaidApi 'Microsoft.ApiManagement/service/apis@2021-12-01-preview' = {
  name: 'Medicaid'
  parent: apiManagementService
  properties: {
    path: 'medicaid'
    format: 'openapi+json'
    subscriptionRequired: false
    value: loadTextContent('api-management-openapi-definitions/medicaid.json')
  }
}

resource medicaidPolicy 'Microsoft.ApiManagement/service/apis/policies@2021-12-01-preview' = {
  name: 'policy'
  parent: medicaidApi
  properties: {
    format: 'rawxml'
    value: loadTextContent('api-management-policy/medicaid-policy.xml')
  }
}

/*  Azure App Service configurations
    Deploys a Standard S1 plan and website
*/
resource appServicePlan 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: appName
  location: location
  sku: {
    name: 'S1'
    capacity: 1
  }
  properties: {
    reserved: true
  }
  kind: 'linux'
}

resource webApplication 'Microsoft.Web/sites@2018-11-01' = {
  name: '${appName}-web'
  location: location
  tags: {
    'hidden-related:${resourceGroup().id}/providers/Microsoft.Web/serverfarms/appServicePlan': 'Resource'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|6.0'
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights.properties.InstrumentationKey 
        }
        {
          name: 'ROOT_URL'
          value: apiManagementService.properties.gatewayUrl 
        }
      ]
    }
  }
}

resource webApplicationSource 'Microsoft.Web/sites/sourcecontrols@2021-01-01' = {
  name: '${webApplication.name}/web'
  properties: {
    repoUrl: 'https://github.com/ralacher/azure-integration-services-demo'
    branch: 'master'
    isManualIntegration: true
  }
}

resource logicAppPutMessage 'Microsoft.Logic/workflows@2019-05-01' = {
  name: '${appName}-logic-put-message'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      triggers: {
        manual: {
          type: 'Request'
          kind: 'Http'
        }
      }
      actions: {
        Response: {
          inputs: {
            body: {
              missing: ['DTaP', 'MMR']
            }
            statusCode: 200
          }
          kind: 'http'
          runAfter: {
            Send_message: ['Succeeded']
          }
          type: 'Response'
        }
        Send_message: {
          inputs: {
            body: {
              ContentData: '@{base64(triggerBody())}'
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'servicebus\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: '/@{encodeURIComponent(encodeURIComponent(\'\'))}/messages'
            queries: {
              systemProperties: 'None'
            }
          }
          runAfter: {}
          type: 'ApiConnection'
        }
      }
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
    }
    parameters: {
      '$connections': {
        value: {
          servicebus: {
            id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'servicebus')
            connectionId: resourceId('Microsoft.Web/connections', 'service-bus-connection')
          }
        }
      }
    }
  }
}

// Logic App backend definitions
resource putMessageBackend 'Microsoft.ApiManagement/service/backends@2021-12-01-preview' = {
  name: 'put-message'
  parent: apiManagementService
  properties: {
    protocol: 'http'
    resourceId: listCallBackUrl('${logicAppPutMessage.id}/triggers/manual', logicAppPutMessage.apiVersion).basePath
    url: listCallBackUrl('${logicAppPutMessage.id}/triggers/manual', logicAppPutMessage.apiVersion).basePath
  }
}

resource putMessageSecret 'Microsoft.ApiManagement/service/namedValues@2021-12-01-preview' = {
  name: 'put-message'
  parent: apiManagementService
  properties: {
    displayName: 'put-message-auth-token'
    secret: true
    value: listCallBackUrl('${logicAppPutMessage.id}/triggers/manual', logicAppPutMessage.apiVersion).queries.sig
  }
}


resource logicAppProcessMessage 'Microsoft.Logic/workflows@2019-05-01' = {
  name: '${appName}-logic-process-message'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      actions: {
        Complete_the_message_in_a_queue: {
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'servicebus\'][\'connectionId\']'
              }
            }
            method: 'delete'
            path: '/@{encodeURIComponent(encodeURIComponent(\'${serviceBusQueue.name}\'))}/messages/complete'
            queries: {
              lockToken: '@triggerBody()?[\'LockToken\']'
              queueType: 'Main'
              sessionId: ''
            }
          }
          runAfter: {}
          type: 'ApiConnection'
        }
      }
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        'When_a_message_is_received_in_a_queue_(peek-lock)': {
          evaluatedRecurrence: {
            frequency: 'Minute'
            interval: 1
          }
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'servicebus\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/@{encodeURIComponent(encodeURIComponent(\'${serviceBusQueue.name}\'))}/messages/head/peek'
            queries: {
              queueType: 'Main'
              sessionId: 'None'
            }
          }
          recurrence: {
            frequency: 'Minute'
            interval: 1
          }
          type: 'ApiConnection'
        }
      }
    }
    parameters: {
      '$connections': {
        value: {
          servicebus: {
            id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'servicebus')
            connectionId: resourceId('Microsoft.Web/connections', 'service-bus-connection')
          }
        }
      }
    }
  }
}

// Logic App to send HTTP response with missing vaccinations
resource logicAppSendResponse 'Microsoft.Logic/workflows@2019-05-01' = {
  name: '${appName}-logic-send-http-response'
  location: location
  properties: {
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      triggers: {
        manual: {
          inputs: {
            method: 'GET'
          }
          type: 'Request'
          kind: 'Http'
        }
      }
      actions: {
        Response: {
          inputs: {
            body: {
              missing: ['DTaP', 'MMR']
            }
            statusCode: 200
          }
          kind: 'http'
          runAfter: {}
          type: 'Response'
        }
      }
    }
  }
}

// Logic App backend definitions
resource sendHttpReponseBackend 'Microsoft.ApiManagement/service/backends@2021-12-01-preview' = {
  name: 'send-http-response'
  parent: apiManagementService
  properties: {
    protocol: 'http'
    resourceId: listCallBackUrl('${logicAppSendResponse.id}/triggers/manual', logicAppSendResponse.apiVersion).basePath
    url: listCallBackUrl('${logicAppSendResponse.id}/triggers/manual', logicAppSendResponse.apiVersion).basePath
  }
}

resource sendHttpResponseSecret 'Microsoft.ApiManagement/service/namedValues@2021-12-01-preview' = {
  name: 'send-http-response'
  parent: apiManagementService
  properties: {
    displayName: 'send-response-auth-token'
    secret: true
    value: listCallBackUrl('${logicAppSendResponse.id}/triggers/manual', logicAppSendResponse.apiVersion).queries.sig
  }
}


/*
    Service Bus configurations
*/
resource serviceBusConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: 'service-bus-connection'
  location: location
  properties: {
    api: {
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'servicebus')
    }
    displayName: 'servicebus'
    parameterValues: {
      connectionString: serviceBusNamespace.properties.serviceBusEndpoint
    }
  }
}

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2022-01-01-preview' = {
  name: '${appName}-namespace'
  location: location
  sku: {
    capacity: 1
    name: 'Standard'
    tier: 'Standard'
  }
}

resource serviceBusQueue 'Microsoft.ServiceBus/namespaces/queues@2022-01-01-preview' = {
  name: '${appName}-queue'
  parent: serviceBusNamespace
  properties: {
  }
}

/*
    Role assignments for Logic Apps to authenticate to Service Bus via Managed Identities
*/
resource serviceBusRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: '090c5cfd-751d-490a-894a-3ce6f1109419'
}

resource putMessageLogicAppAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(subscription().id, logicAppPutMessage.id)
  properties: {
    roleDefinitionId: serviceBusRoleDefinition.id
    principalId: logicAppPutMessage.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource processMessageLogicAppAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(subscription().id, logicAppProcessMessage.id)
  properties: {
    roleDefinitionId: serviceBusRoleDefinition.id
    principalId: logicAppProcessMessage.identity.principalId
    principalType: 'ServicePrincipal'
  }
}
