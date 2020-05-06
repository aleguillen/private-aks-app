# Deploy a Private Azure Kubernetes Service using Azure DevOps

## Overview 
Create a private Azure Kubernetes Service cluster using Terraform and access kubectl commands (Control Plane) through a private endpoint.
Deploy ACR with a private endpoint. Access ingress controller through private endpoint.

## Pre-requisites

* Azure CLI version 2.0.77 or later, and the Azure CLI AKS Preview extension version 0.4.18.
    * See how to install Azure CLI [here](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest).
    ```bash
    # Confirm AZ CLI installation
    az --version

    # Install the aks-preview extension
    az extension add --name aks-preview
    
    # Update the extension to make sure you have the latest version installed
    az extension update --name aks-preview

    # Install and confirm Azure DevOps extension.
    az extension add --name azure-devops
    az extension show --name azure-devops
    ```
* Terraform version 0.12.24 or later.
    * See how to install Terraform [here](https://learn.hashicorp.com/terraform/azure/install_az).
* Install Azure DevOps Extension.
    ```bash
    # Confirm AZ CLI installation
    az --version

    # Install and confirm Azure DevOps extension.
    az extension add --name azure-devops
    az extension show --name azure-devops
    ```
* Git to manage your repository locally.
    *  See how to install [here](https://git-scm.com/downloads).

## Infrastructure

The purpose of this sample is to create an end to end solution to connect to applications hosted in AKS privately within the network. 

### Architecture 

![](/images/Private-Cluster-Architecture.PNG)

This is a sample architecture. Let's break it down:

### [Azure DevOps Deployment Overview](/infra/ado-agent)

* Connects to on-premises via [Azure ExpressRoute](https://azure.microsoft.com/en-us/services/expressroute/) - this is not required or configured in this sample, however it's meant to show case the availability for access your private application from on-premises due to the ExpressRoute connection.
* ADO Server - this VM is configured as a [Azure Pipeline Self-hosted Agent](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/agents) within the network that can connect privately to Azure Container Registry and AKS cluster.
* Private Endpoints - this allows private and secure connection using [Azure Private Link - Private Endpoints](https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-overview) which provisions a network interface with a private Ip bringing your service into the VNET.
* Private DNS Zone - it is responsible for translating a service name to its IP address, you can link a [Private DNS Zone](https://docs.microsoft.com/en-us/azure/dns/private-dns-overview) to a VNET to override and resolve specific domains. For enterprise solutions, that already have a custom DNS server, you can add or modify your records to achive the same. Alternatively, for **testing purposes** you can modify your Hosts file (etc/hosts) locally and map hostnames to IP address. 
    * Modify /etc/hosts in Linux
        ```bash
        sudo echo "127.0.0.1    localhost" | sudo tee -a /etc/hosts
        ```
    * Modify /etc/hosts in Windows - Open PowerShell in Admin mode and execute:
        ```powershell
        # Go to hosts file directory location
        cd C:\Windows\System32\drivers\etc

        # Add new IP / FQDN mapping 
        "127.0.0.1  localhost" | Add-Content hosts
        
        # Get updated hosts content
        Get-Content hosts 
        ```
    
### [Private AKS Deployment Overview](/infra/private-aks)

#### Architecture Flow - Deploying Private AKS Cluster with Azure DevOps

![](/images/Private-Cluster-Architecture-Flow.gif)

* [Azure Container Registry](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-intro) - managed, private Docker registry service based on Docker Registry 2.0. In this case we will be accesing ACR using Private Endpoint, for more information see [here](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-private-link)
* [Private Azure Kubernetes Service](https://docs.microsoft.com/en-us/azure/aks/private-clusters) - by using a private cluster with internal IP you can ensure that network traffic remains inside the network.
* [Private Link Service](https://docs.microsoft.com/en-us/azure/private-link/private-link-service-overview) -  is the reference to your own service that is running behind Azure Standard Load Balancer so that access to your service can be privately from their own VNets.

## Application: Azure Voting App - [/app](/app)

This sample uses [Azure Voting App](https://github.com/Azure-Samples/azure-voting-app-redis) as our demo application. This application creates a multi-container application in an Azure Kubernetes Service (AKS) cluster. 

To walk through a quick deployment of this application, see the AKS [quick start](https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough?WT.mc_id=none-github-nepeters).


## Azure DevOps Configuration 

### General setup
* [Login or Sign Up](https://dev.azure.com) into your Azure DevOps Organization.
* Create a new project in Azure DevOps, for information see [here](https://docs.microsoft.com/en-us/azure/devops/organizations/projects/create-project).
    * Sample name: **private-aks-app**
* We will be using **Default** Agent Pool. 
    *Alternately you can create a new Agent Pool in your project, for more information see [here](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/pools-queues), if you do update all pipelines files **azure-pipelines.yml** file and variable group value.
        * Example Name: **UbuntuPrivatePool**
        * Keep option **Grant access permission to all pipelines** checked.
* Create a new Azure Service Connection to your Azure Subscription, for more information see [here](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints)
    * Azure CLI script:
        ```bash
        # Login and select Azure Subscription context
        az login
        az account set --subscription <my-subscription-id-or-name>
        
        # Retrieve Account and Subscription details
        TENANT_ID=$(az account show --query tenantId -o tsv)
        SUBSCRIPTION_ID=$(az account show --query id -o tsv)
        SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
        APP_NAME="ado-sp-private-aks-app-${SUBSCRIPTION_ID}"
        
        # Create Service Principal and get Password created
        APP_PWD=$(az ad sp create-for-rbac --name $APP_NAME --role Owner --scopes "subscriptions/${SUBSCRIPTION_ID}" --query "password" -o tsv)
        
        # Get other Service Principal details
        APP_ID=$(az ad app list --display-name $APP_NAME --query [].appId -o tsv)
        SP_ID=$(az ad sp list --display-name $APP_NAME --query "objectId" -o tsv)
        
        # Create Service Connection in Azure DevOps to Azure RM.
        az devops service-endpoint azurerm create --azure-rm-service-principal-id $SP_ID --azure-rm-subscription-id $SUBSCRIPTION_ID --azure-rm-subscription-name $SUBSCRIPTION_NAME --azure-rm-tenant-id $TENANT_ID --name "Azure Subscription"
        ```
    * Azure DevOps Portal:
        * Connection type: **Azure Resource Manager**.
        * Authentication Method: **Service Principal (automatic)** - this option will automatically create the Service Principal on your behalf, if you don't have permissions to create a Service Principal please use the manual option. This demo requires to set RBAC for the Private Cluster, this Service Principal requires to have 
        * Scope level: Select the appropiate level, for this demo I used **Subscription**.
        * Service connection name: **Azure Subscription**.

    **Note: The Service connection name can be customized, just remember to update all azure-pipelines.yml files to use the right Service Connection name in the variables section.**

* Create a Personal Access Token (PAT token), we will use this token to configure the Self Hosted Agent for Azure DevOps. For more information on how to create a PAT token see [here](https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate).
* [Import Git](https://docs.microsoft.com/en-us/azure/devops/repos/git/import-git-repository) repo into your Azure DevOps project.
    * Git source Url: https://github.com/aleguillen/private-aks-app.git
* (Optional) Clone imported repo in your local computer, for more info see [here](https://docs.microsoft.com/en-us/azure/devops/repos/git/clone).
* Configure Azure DevOps CLI
    ```bash
    # Make sure your Azure DevOps defaults include the organization and project from the command prompt
    az devops configure --defaults organization=https://dev.azure.com/<your-organization> project=<your-project>

    # Sign in to the Azure CLI
    az login
    ```
