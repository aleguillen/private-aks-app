# Deploy a Private Azure Kubernetes Service using Azure DevOps

## Overview 
Create a private Azure Kubernetes Service cluster using Terraform and access kubectl commands (Control Plane) through a private endpoint.
Deploy ACR with a service endpoint. Access ingress controller through private endpoint.

## Pre-requisites

* Azure CLI version 2.0.77 or later, and the Azure CLI AKS Preview extension version 0.4.18
* Terraform version 0.12 or later, and AzureRM Provider 1.39 or later.
* Azure DevOps project and Git repo.

## Infrastructure

The purpose of this sample is to create an end to end solution to connect to applications hosted in AKS privately within the network. 

### Architecture 

![alt text](https://github.com/aleguillen/private-aks-app/images/Private-Cluster-Architecture.PNG)

This is a sample architecture. Let's break it down:

#### Bastion Deployment
  [/infra/terraform/bastion-net](https://github.com/aleguillen/private-aks-app/infra/terraform/bastion-net)

* Connects to on-premises via [Azure ExpressRoute](https://azure.microsoft.com/en-us/services/expressroute/) - this is not required or configured in this sample, however it's meant to show case the availability for access your private application from on-premises due to the ExpressRoute connection.
* JumpServer VM - this server uses [Azure Bastion](https://azure.microsoft.com/en-us/services/azure-bastion/) to fully manage and connect via RDP and/or SSH privately fom the Azure portal.
* ADO Server - this VM is configured as a [Azure Pipeline Self-hosted Agent](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/agents) within the network that can connect privately to Azure Container Registry and AKS cluster.
* Private Endpoints - this allows private and secure connection using [Azure Private Link - Private Endpoints](https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-overview) which provisions a network interface with a private Ip bringing your service into the VNET.
* [Virtual Network Service Endpoint](https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-overview) - allow you to secure Azure service resources to only your VNETs, all traffic from your VNETs to the Azure Service always remains on the Microsoft Azure backbone network. 
* Private DNS Zone - it is responsible for translating a service name to its IP address, you can link a [Private DNS Zone](https://docs.microsoft.com/en-us/azure/dns/private-dns-overview) to a VNET to override and resolve specific domains. Alternatively, for **testing purposes** you can modify your Hosts file (etc/hosts) locally and map hostnames to IP address. For enterprise solutions, that already have a custom DNS server, you can add or modify your records to achive the same.

### Private AKS Deployment
  [/infra/terraform/bastion-net](https://github.com/aleguillen/private-aks-app\infra\terraform\private-aks)

* [Azure Container Registry](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-intro) - managed, private Docker registry service based on Docker Registry 2.0. In this case we will be restricting access to ACR using virtual network firewall rules and service endpoints, for more information see [here](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-vnet)
* [Private Azure Kubernetes Service](https://docs.microsoft.com/en-us/azure/aks/private-clusters) - by using a private cluster with internal IP you can ensure that network traffic remains inside the network
* [Private Link Service](https://docs.microsoft.com/en-us/azure/private-link/private-link-service-overview) - 


## Application: [Azure Voting App](https://github.com/Azure-Samples/azure-voting-app-redis)
  
  [/app](https://github.com/aleguillen/private-aks-app/app)

This sample uses [Azure Voting App](https://github.com/Azure-Samples/azure-voting-app-redis) as our demo application. This application creates a multi-container application in an Azure Kubernetes Service (AKS) cluster. 

To walk through a quick deployment of this application, see the AKS [quick start](https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough?WT.mc_id=none-github-nepeters).

