# Bastion Deployment

* Connects to on-premises via [Azure ExpressRoute](https://azure.microsoft.com/en-us/services/expressroute/) - this is not required or configured in this sample, however it's meant to show case the availability for access your private application from on-premises due to the ExpressRoute connection.
* JumpServer VM - this server uses [Azure Bastion](https://azure.microsoft.com/en-us/services/azure-bastion/) to fully manage and connect via RDP and/or SSH privately fom the Azure portal.
* ADO Server - this VM is configured as a [Azure Pipeline Self-hosted Agent](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/agents) within the network that can connect privately to Azure Container Registry and AKS cluster.
* Private Endpoints - this allows private and secure connection using [Azure Private Link - Private Endpoints](https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-overview) which provisions a network interface with a private Ip bringing your service into the VNET.
* [Virtual Network Service Endpoint](https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-overview) - allow you to secure Azure service resources to only your VNETs, all traffic from your VNETs to the Azure Service always remains on the Microsoft Azure backbone network. 
* Private DNS Zone - it is responsible for translating a service name to its IP address, you can link a [Private DNS Zone](https://docs.microsoft.com/en-us/azure/dns/private-dns-overview) to a VNET to override and resolve specific domains. Alternatively, for **testing purposes** you can modify your Hosts file (etc/hosts) locally and map hostnames to IP address. For enterprise solutions, that already have a custom DNS server, you can add or modify your records to achive the same.

## Pre-requisites

### Azure DevOps Configuration
* Create a new project in [Azure DevOps](https://dev.azure.com/)
* Create a new [Agent Pool](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/pools-queues)
** Name: **UbuntuPrivatePool**
** Keep option **Grant access permission to all pipelines** checked.
* Create a new Azure Service Connection to your Azure Subscription for more information see [here](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints)
** Connection type: **Azure Resource Manager**
** Authentication Method: **Service Principal (automatic)** - thisoption will automatically create the Service Principal on your behalf, if you don't have permissions to create a Service Principal please use the manual option.
** Scope level: Select the appropiate level, for this demo I used **Subscription**.
*** Service connection name: **Azure Subscription** 
```
Note: The Service connection name can be customized, just remember to update all azure-pipelines.yml files to use the right Service Connection name in the variables section.
```

## How to run your Pipeline
* [Clone/Import Git](https://docs.microsoft.com/en-us/azure/devops/repos/git/import-git-repository) repo into your Azure DevOps.
* Customize variables *.azure-pipelines.yml file
** Use the right agent pool: **ado_agent_pool: 'Azure Pipelines'**
** Use the right Service Connection: **ado_service_connection_name: 'Azure Subscription'**
** Set your Azure resources prefix: **prefix: alebastion**
** Set a globally unique name to your Terraform State Storage Account: **terraformstorageaccount: tfalebastiondevsa**
** Set VMs username: **vm_username: vmadmin**
* Replace secret variables manually, look for: **ThisValueWillBeSetManually**. For more information on how to set secret variables see [here](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/variables?view=azure-devops&tabs=yaml%2Cbatch#secret-variables).
* Run your pipeline


