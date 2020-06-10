# Deploy a Private Azure Kubernetes Service using Azure DevOps

## Overview 
Create a private Azure Kubernetes Service cluster using Terraform and access kubectl commands (Control Plane) through a private endpoint.
Deploy ACR with a private endpoint. Access ingress controller through private endpoint.

## Pre-requisites

* Azure CLI and the Azure CLI AKS Preview extension.
    * See how to install Azure CLI [here](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest).
    ```bash
    # Confirm AZ CLI installation
    az --version

    # Install the aks-preview extension
    az extension add --name aks-preview
    
    # Update the extension to make sure you have the latest version installed
    az extension update --name aks-preview
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
* Azure DevOps Self Hosted Agents.
    * See how to setup your Self Hosted Agents in Azure as shown in the diagram below <a href="https://github.com/aleguillen/azure-devops-self-hosted-agent" target="_blank">here</a>.

## Infrastructure

The purpose of this sample is to create an end to end solution to connect to applications hosted in AKS privately within the network. 

### Architecture 

![](/images/architecture.png)

This is a sample architecture. Let's break it down:

### <a href="https://github.com/aleguillen/azure-devops-self-hosted-agent" target="_blank">Azure DevOps Deployment Overview</a>.

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
    
### [Private AKS Deployment Overview](/infra)

#### Architecture Flow - Deploying Private AKS Cluster with Azure DevOps

![](/images/architecture.gif)

* [Azure Container Registry](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-intro) - managed, private Docker registry service based on Docker Registry 2.0. In this case we will be accesing ACR using Private Endpoint, for more information see [here](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-private-link)
* [Private Azure Kubernetes Service](https://docs.microsoft.com/en-us/azure/aks/private-clusters) - by using a private cluster with internal IP you can ensure that network traffic remains inside the network.
* [Private Link Service](https://docs.microsoft.com/en-us/azure/private-link/private-link-service-overview) -  is the reference to your own service that is running behind Azure Standard Load Balancer so that access to your service can be privately from their own VNets.

## [Application: Azure Voting App](/app)

This sample uses [Azure Voting App](https://github.com/Azure-Samples/azure-voting-app-redis) as our demo application. This application creates a multi-container application in an Azure Kubernetes Service (AKS) cluster. 

To walk through a quick deployment of this application, see the AKS [quick start](https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough?WT.mc_id=none-github-nepeters).
