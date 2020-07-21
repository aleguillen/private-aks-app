#!/bin/bash

# Sign in to the Azure CLI and Set Subscription
az login
az account set --subscription <your-subscription-id-or-name>

# Adding Azure DevOps Extension
az extension add --name azure-devops

#################################################
################# Variables #####################
#################################################

ORG_NAME=<your-organization-name>
PROJECT_NAME='private-aks-app'

ORG_URL="https://dev.azure.com/$ORG_NAME"

# Azure Repo name for pipeline.
ado_repo=$PROJECT_NAME
ado_repo_branch='master'

#################################################
################### Setup #######################
#################################################

# Set Azure DevOps defaults - organization name
az devops configure --defaults organization=$ORG_URL

# Create Project
az devops project create --name $PROJECT_NAME

# Set Azure DevOps defaults - organization name and project name
az devops configure --defaults organization=$ORG_URL project=$PROJECT_NAME

# Create Azure RM Service Connection
# Retrieve Account and Subscription details
TENANT_ID=$(az account show --query tenantId -o tsv)
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
APP_NAME="sp-ado-${PROJECT_NAME}-${SUBSCRIPTION_ID}"
SERVICE_CONNECTION_NAME="sc-${PROJECT_NAME}-azure-subscription"

# Create Service Principal and get Password created. Set value to environment variable.
APP_PWD=$(az ad sp create-for-rbac --name $APP_NAME --role Owner --scopes "/subscriptions/${SUBSCRIPTION_ID}" --query "password" -o tsv)
export AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY="${APP_PWD}"

# Get other Service Principal details
APP_ID=$(az ad app list --display-name $APP_NAME --query [].appId -o tsv)

# Create Service Connection in Azure DevOps to Azure RM.
az devops service-endpoint azurerm create --azure-rm-service-principal-id $APP_ID --azure-rm-subscription-id $SUBSCRIPTION_ID --azure-rm-subscription-name "${SUBSCRIPTION_NAME}" --azure-rm-tenant-id $TENANT_ID --name $SERVICE_CONNECTION_NAME

# Grant permission access to all Pipelines 
serv_end_id=$(az devops service-endpoint list --query "[?name == '${SERVICE_CONNECTION_NAME}'].id" -o tsv)
az devops service-endpoint update --id $serv_end_id --enable-for-all true

# Import Git Repository to Azure Repos
az repos import create --git-source-url https://github.com/aleguillen/private-aks-app.git --repository $ado_repo

# Create Infra Pipeline
az pipelines create --name 'Private.AKS.Infra.CI.CD' --yaml-path '/pipelines/infra/azure-pipelines.yml' --repository $ado_repo --repository-type tfsgit --branch $ado_repo_branch

# Create Application Pipeline
az pipelines create --name 'Private.AKS.App.CI.CD' --yaml-path '/pipelines/app/azure-pipelines.yml' --repository $ado_repo --repository-type tfsgit --branch $ado_repo_branch