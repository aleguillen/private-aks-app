# Deploy a Private Azure Kubernetes Service using Azure DevOps

## Overview 
Create a private Azure Kubernetes Service cluster using Terraform and access kubectl commands (Control Plane) through a private endpoint.
Deploy ACR with a service endpoint. Access ingress controller through private endpoint.

## Pre-requisites

* Azure CLI version 2.0.77 or later, and the Azure CLI AKS Preview extension version 0.4.18
* Terraform version 0.12 or later, and AzureRM Provider 1.39 or later.
* Azure DevOps project and Git repo.
* (Optional) Install Azure DevOps Extension.
```bash
# Confirm AZ CLI installation
az --version

# Install and confirm Azure DevOps extension.
az extension add --name azure-devops
az extension show --name azure-devops
```

## Infrastructure

The purpose of this sample is to create an end to end solution to connect to applications hosted in AKS privately within the network. 

### Architecture 

![alt text](/images/Private-Cluster-Architecture.PNG)

This is a sample architecture. Let's break it down:

### Bastion Deployment - [/infra/terraform/bastion-net](/infra/terraform/bastion-net)

* Connects to on-premises via [Azure ExpressRoute](https://azure.microsoft.com/en-us/services/expressroute/) - this is not required or configured in this sample, however it's meant to show case the availability for access your private application from on-premises due to the ExpressRoute connection.
* JumpServer VM - this server uses [Azure Bastion](https://azure.microsoft.com/en-us/services/azure-bastion/) to fully manage and connect via RDP and/or SSH privately fom the Azure portal.
* ADO Server - this VM is configured as a [Azure Pipeline Self-hosted Agent](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/agents) within the network that can connect privately to Azure Container Registry and AKS cluster.
* Private Endpoints - this allows private and secure connection using [Azure Private Link - Private Endpoints](https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-overview) which provisions a network interface with a private Ip bringing your service into the VNET.
* [Virtual Network Service Endpoint](https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-overview) - allow you to secure Azure service resources to only your VNETs, all traffic from your VNETs to the Azure Service always remains on the Microsoft Azure backbone network. 
* Private DNS Zone - it is responsible for translating a service name to its IP address, you can link a [Private DNS Zone](https://docs.microsoft.com/en-us/azure/dns/private-dns-overview) to a VNET to override and resolve specific domains. Alternatively, for **testing purposes** you can modify your Hosts file (etc/hosts) locally and map hostnames to IP address. For enterprise solutions, that already have a custom DNS server, you can add or modify your records to achive the same.

### Private AKS Deployment - [/infra/terraform/bastion-net](/infra/terraform/private-aks)

* [Azure Container Registry](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-intro) - managed, private Docker registry service based on Docker Registry 2.0. In this case we will be restricting access to ACR using virtual network firewall rules and service endpoints, for more information see [here](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-vnet)
* [Private Azure Kubernetes Service](https://docs.microsoft.com/en-us/azure/aks/private-clusters) - by using a private cluster with internal IP you can ensure that network traffic remains inside the network
* [Private Link Service](https://docs.microsoft.com/en-us/azure/private-link/private-link-service-overview) - 


## Application: Azure Voting App - [/app](/app)

This sample uses [Azure Voting App](https://github.com/Azure-Samples/azure-voting-app-redis) as our demo application. This application creates a multi-container application in an Azure Kubernetes Service (AKS) cluster. 

To walk through a quick deployment of this application, see the AKS [quick start](https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough?WT.mc_id=none-github-nepeters).


## Azure DevOps Configuration 
* [Login](https://dev.azure.com) into your Azure DevOps Organization.
* Create a new project in Azure DevOps, for information see [here](https://docs.microsoft.com/en-us/azure/devops/organizations/projects/create-project).
    * Sample name: **private-aks-app**
* Create a new Agent Pool in your project, for more information see [here](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/pools-queues)
    * Name: **UbuntuPrivatePool**
    * Keep option **Grant access permission to all pipelines** checked.
* Create a new Azure Service Connection to your Azure Subscription, for more information see [here](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints)
    * Connection type: **Azure Resource Manager**.
    * Authentication Method: **Service Principal (automatic)** - thisoption will automatically create the Service Principal on your behalf, if you don't have permissions to create a Service Principal please use the manual option.
    * Scope level: Select the appropiate level, for this demo I used **Subscription**.
    * Service connection name: **Azure Subscription**.

**Note: The Service connection name can be customized, just remember to update all azure-pipelines.yml files to use the right Service Connection name in the variables section.**

* Create a Personal Access Token (PAT token), we will use this token to configure the Self Hosted Agent for Azure DevOps. For more information on how to create a PAT token see [here](https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate)
* [Import Git](https://docs.microsoft.com/en-us/azure/devops/repos/git/import-git-repository) repo into your Azure DevOps project.
    * Git source Url: https://github.com/aleguillen/private-aks-app.git
* (Optional) Clone imported repo in your local computer, for more info see [here](https://docs.microsoft.com/en-us/azure/devops/repos/git/clone).
* Configure Azure DevOps CLI
```bash
# Make sure your Azure DevOps defaults include the organization and project from the command prompt
az devops configure --defaults organization=https://dev.azure.com/your-organization project=your-project

# Sign in to the Azure CLI
az login
```
* Create Variable groups. Replace variables with your own preferred values, also check for all **<replace-me>** values and update them accordingly. Bastion Variables: **bastion_dev_vars**. AKS Variables: **aks_dev_vars**
```bash
# Create Bastion Variable group with non-secret variables
az pipelines variable-group create \
--name bastion_dev_vars \
--authorize true \
--variables \
environment='dev' \
location='eastus2' \
prefix='samplebastion' \
resource_group='$(prefix)-$(environment)-rg' \
storagekey='PipelineWillGetThisValueRuntime' \
terraformstorageaccount='tf$(prefix)$(environment)sa' \
terraformstoragerg='tf-$(prefix)-$(environment)-rg' \
vm_username='vmadmin' \
ado_pool_name='UbuntuPrivatePool' \
ado_server_url='$(System.TeamFoundationCollectionUri)'

# Create Variable Secret
VAR_GROUP_ID=$(az pipelines variable-group list --group-name bastion_dev_vars --top 1 --query "[0].id" -o tsv)
az pipelines variable-group variable create \
--group-id $VAR_GROUP_ID \
--secret true \
--name 'vm_password' \
--value '<replace-me>'

az pipelines variable-group variable create \
--group-id $VAR_GROUP_ID \
--secret true \
--name 'ado_pat_token' \
--value '<replace-me>'
```

```bash
# Create AKS Variable group with non-secret variables
az pipelines variable-group create \
--name aks_dev_vars \
--authorize true \
--variables \
environment='dev' \
location='eastus2' \
prefix='samplepvtaks' \
resource_group='$(prefix)-$(environment)-rg' \
vnet_name='$(prefix)-$(environment)-vnet' \
storagekey='PipelineWillGetThisValueRuntime' \
terraformstorageaccount='tf$(prefix)$(environment)sa' \
terraformstoragerg='tf-$(prefix)-$(environment)-rg' \
acr_name='$(prefix)$(environment)acr' \
acr='$(acr_name).azurecr.io' \
aks_name='$(prefix)-$(environment)-aks' \
aks_service_principal_client_id='<replace-me>' \
ado_subnet_id='<replace-me>' \
pe_rg_name='<replace-me>' \
pe_vnet_name='<replace-me>' \
pe_subnet_name='<replace-me>'


# Create Variable Secret
VAR_GROUP_ID=$(az pipelines variable-group list --group-name aks_dev_vars --top 1 --query "[0].id" -o tsv)
az pipelines variable-group variable create \
--group-id $VAR_GROUP_ID \
--secret true \
--name 'aks_service_principal_client_secret' \
--value '<replace-me>'

```
* Create Bastion Infra Pipeline [from the CLI](https://docs.microsoft.com/en-us/azure/devops/pipelines/create-first-pipeline-cli).
```bash
az pipelines create --name 'Bastion.Infra.CI.CD' --yaml-path '/infra/terraform/bastion-net/bastion-infra-azure-pipelines.yml' --repository private-aks-app --repository-type tfsgit --branch master
```
* Create AKS Infra Pipeline [from the CLI](https://docs.microsoft.com/en-us/azure/devops/pipelines/create-first-pipeline-cli).
```bash
az pipelines create --name 'Private.AKS.Infra.CI.CD' --yaml-path '/infra/terraform/private-aks/aks-infra-azure-pipelines.yml' --repository private-aks-app --repository-type tfsgit --branch master
```
* Create AKS App Pipeline [from the CLI](https://docs.microsoft.com/en-us/azure/devops/pipelines/create-first-pipeline-cli).
```bash
az pipelines create --name 'Private.AKS.App.CI.CD' --yaml-path '/app/aks-app-azure-pipelines.yml' --repository private-aks-app --repository-type tfsgit --branch master
```