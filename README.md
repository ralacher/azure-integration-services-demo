# Azure Integration Services Demo
[![Cost](https://img.shields.io/static/v1?label=Cost&message=$92%2Fmonth&color=success&style=plastic.svg)](https://azure.com/e/896ec772934f4eb3b12c754281e126cc) ![Time](https://img.shields.io/static/v1?label=Time&message=60%20minutes&color=yellow&style=plastic.svg)

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fralacher%2Fazure-integration-services-demo%2Fmaster%2FInfrastructure%2Fmain.json)

# Prerequisites
- User with Contributor or Owner permissions for a resource group
- The following [resource providers](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/resource-providers-and-types)
  - Microsoft.ApiManagement
  - Microsoft.Insights
  - Microsoft.Logic
  - Microsoft.ServiceBus
  - Microsoft.Storage
  - Microsoft.Web





# Instructions
1. Click on the Deploy to Azure button above
2. Either create a new resource group or select an existing one
3. Enter a name for the application (to be used for resource naming purposes)
4. Leave the `[resourceGroup().location]` block as-is
5. Submit the template for deployment

# Diagram
![Architecture diagram](Images/high-level-design.png)

# References
## API Management 
![Time](https://img.shields.io/static/v1?label=Time&message=40%20minutes&color=success&style=plastic.svg)

Learn how the API Management service functions, how to transform and secure APIs, and how to create a backend API.<br/>
- [AZ-204: Implement API Management](https://docs.microsoft.com/en-us/learn/paths/az-204-implement-api-management/)
- [Reference architectures for Azure API Management](https://docs.microsoft.com/en-us/azure/architecture/reference-architectures/enterprise-integration/basic-enterprise-integration)
- [Azure API Management documentation](https://docs.microsoft.com/en-us/azure/api-management/)

## Service Bus
![Time](https://img.shields.io/static/v1?label=Time&message=60%20minutes&color=warning&style=plastic.svg)

Learn how to build applications with message-based architectures by integrating Azure Service Bus and Azure Queue Storage in to your solution.<br/>
- [AZ-204: Develop message-based solutions](https://docs.microsoft.com/en-us/learn/paths/az-204-develop-message-based-solutions/)
- [Reference architectures for Azure Service Bus](https://docs.microsoft.com/en-us/azure/architecture/reference-architectures/enterprise-integration/queues-events)
- [Azure Service Bus documentation](https://docs.microsoft.com/en-us/azure/service-bus-messaging/)

## App Services
![Time](https://img.shields.io/static/v1?label=Time&message=38%20minutes&color=warning&style=plastic.svg)

Learn how Azure App Service functions and how to create and update an app. Explore App Service authentication and authorization, configuring app settings, scale apps, and how to use deployment slots.<br/>
- [AZ-204: Create Azure App Service web apps](https://docs.microsoft.com/en-us/learn/paths/create-azure-app-service-web-apps/)
- [Reference architectures for Azure App Services](https://docs.microsoft.com/en-us/azure/architecture/guide/web/web-start-here)
- [Azure App Services documentation](https://docs.microsoft.com/en-us/azure/app-service/)
