#!/bin/bash

###############
## VARIABLES ##
###############
PREFIX=alecliaks
ENVIRONMENT=dev
AKS_RG_NAME="$PREFIX-$ENVIRONMENT-rg"
LOCATION=eastus2       # For private cluster use eastus2 or westus2
AKS_NAME="$PREFIX-$ENVIRONMENT-aks"
AKS_VNET_NAME="$PREFIX-$ENVIRONMENT-vnet"

#######################################
## Install the aks-preview extension ##
#######################################

az extension add --name aks-preview

# Update the extension to make sure you have the latest version installed

az extension update --name aks-preview

az feature register --name AKSPrivateLinkPreview --namespace Microsoft.ContainerService
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/AKSPrivateLinkPreview')].{Name:name,State:properties.state}"

az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.Network

##################################
## Create a private AKS cluster ##
##################################

az login
echo "Type the Azure Subscription you want to select, followed by [ENTER]"
read AZ_SUBSCRIPTION
az account set --subscription "$AZ_SUBSCRIPTION"

# Create Resource Group
az group create --name $AKS_RG_NAME --location $LOCATION

# Get latest kubernetes version 
version=$(az aks get-versions -l $LOCATION --query 'orchestrators[-1].orchestratorVersion' -o tsv)

# Create a zone redundant Private Cluster
az aks create -n $AKS_NAME -g $AKS_RG_NAME --load-balancer-sku standard --enable-private-cluster --enable-addons monitoring --kubernetes-version $version --generate-ssh-keys --location $LOCATION --node-zones {1,2,3}