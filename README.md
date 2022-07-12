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
