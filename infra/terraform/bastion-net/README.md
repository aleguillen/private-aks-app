# Bastion Deployment

* Connects to on-premises via [Azure ExpressRoute](https://azure.microsoft.com/en-us/services/expressroute/) - this is not required or configured in this sample, however it's meant to show case the availability for access your private application from on-premises due to the ExpressRoute connection.
* JumpServer VM - this server uses [Azure Bastion](https://azure.microsoft.com/en-us/services/azure-bastion/) to fully manage and connect via RDP and/or SSH privately fom the Azure portal.
* ADO Server - this VM is configured as a [Azure Pipeline Self-hosted Agent](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/agents) within the network that can connect privately to Azure Container Registry and AKS cluster.
* Private Endpoints - this allows private and secure connection using [Azure Private Link - Private Endpoints](https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-overview) which provisions a network interface with a private Ip bringing your service into the VNET.
* [Virtual Network Service Endpoint](https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-overview) - allow you to secure Azure service resources to only your VNETs, all traffic from your VNETs to the Azure Service always remains on the Microsoft Azure backbone network. 
* Private DNS Zone - it is responsible for translating a service name to its IP address, you can link a [Private DNS Zone](https://docs.microsoft.com/en-us/azure/dns/private-dns-overview) to a VNET to override and resolve specific domains. Alternatively, for **testing purposes** you can modify your Hosts file (etc/hosts) locally and map hostnames to IP address. For enterprise solutions, that already have a custom DNS server, you can add or modify your records to achive the same.

## Pre-requisites

### Azure CLI 
* To install version 2.0.49 or newer, see [Install the Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli).

```bash
# Confirm AZ CLI installation
az --version

# Install and confirm Azure DevOps extension.
az extension add --name azure-devops
az extension show --name azure-devops
```

### Azure DevOps
* Create a new project in [Azure DevOps](https://docs.microsoft.com/en-us/azure/devops/organizations/projects/create-project)
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
* [Import Git](https://docs.microsoft.com/en-us/azure/devops/repos/git/import-git-repository) repo into your Azure DevOps.
** Git source Url: https://github.com/aleguillen/private-aks-app.git
* Clone imported repo in your local computer, for more info see [here](https://docs.microsoft.com/en-us/azure/devops/repos/git/clone).
* Configure Azure DevOps CLI
```bash
# Make sure your Azure DevOps defaults include the organization and project from the command prompt
az devops configure --defaults organization=https://dev.azure.com/your-organization project=your-project

# Sign in to the Azure CLI
az login
```
* Create Variable group: **bastion_dev_vars**. Replace variables with your own values like: prefix, terraformstorageaccount, ado_pool_name, vm_username.
```bash
# Create Variable group with non-secret variables
az pipelines variable-group create \
--name bastion_dev_vars \
--authorize true \
--variables \
environment='dev' \
location='eastus2' \
prefix='alebastion' \
resource_group='$(prefix)-$(environment)-rg' \
storagekey='PipelineWillGetThisValueRuntime' \
terraformstorageaccount='tfalebastiondevsa' \
terraformstoragerg='tf-$(prefix)-$(environment)-rg' \
vm_username='vmadmin' \
ado_pool_name='UbuntuPrivatePool' \
ado_server_url='$(System.TeamFoundationCollectionUri)' \
ado_pat_token='$(System.AccessToken)'

# Create Variable Secret
VAR_GROUP_ID=$(az pipelines variable-group list --group-name bastion_dev_vars --top 1 --query "[0].id" -o tsv)
az pipelines variable-group variable create \
--group-id $VAR_GROUP_ID \
--secret true \
--name 'vm_password' \
--value 'DevOps!01'
```

* [Create a Pipeline from the CLI](https://docs.microsoft.com/en-us/azure/devops/pipelines/create-first-pipeline-cli)

```bash
# Make sure your Azure DevOps defaults include the organization and project from the command prompt
az devops configure --defaults organization=https://dev.azure.com/your-organization project=your-project

# Sign in to the Azure CLI
az login

# Create Azure Pipeline
az pipelines create --name 'Bastion.CI.CD' --yaml-path '/infra/terraform/bastion-net/azure-pipelines.yml'
```
