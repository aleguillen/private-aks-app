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

# Environment Name: Most common examples: DEV, ACC, PRD, QA (Abbreviate if possible)
environment='dev'

# Azure region / location. Modify as needed.
location='eastus2' 

# Prefix for all your resources. Use alphanumeric characters only. Avoid special characters. Ex. ado001
prefix='aks001'

# Azure Common tags. These tags will be apply to all created resources.
# You can add/remove tags as needed. Example: 
common_tags='{
    org_name    = "<replace-me>",
    cost_center = "<replace-me>",
    project     = "<replace-me>",
    project_id  = "<replace-me>",
    created_by  = "<replace-me>",
}'

# AKS Version
aks_version='1.15.7'

# AKS Service Principal Client ID (AppId)
aks_service_principal_client_id='<replace-me>'

# AKS Service Principal Object ID
aks_service_principal_id='<replace-me>'

# AKS Service Principal Client Secret
aks_service_principal_client_secret='<replace-me>'

# Resource Group Name for ADO Self-Hosted Agent for Private Endpoint
pe_rg_name='<replace-me>'

# Virtual Network Name for ADO Self-Hosted Agent for Private Endpoint
pe_vnet_name='<replace-me>'

# Subnet name for ADO Self-Hosted Agent for Private Endpoint
pe_subnet_name='<replace-me>'

# Private Endpoint Request
pe_is_manual_connection=false
pe_request_message=''

# Terraform Storage Account Details - Storage Account created for ADO Self-Hosted Agent
terraformstorageaccount='<replace-me>'
terraformstoragerg='<replace-me>'
terraformstoragecontainer='terraform'

# ADO variable group name - if you change this name you will need to change azure-pipelines.yml file.
ado_var_group_name='aks_dev_vars'

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

# Create ADO Variable group with non-secret variables
az pipelines variable-group create \
--name $ado_var_group_name \
--authorize true \
--variables \
environment=$environment \
location=$location \
prefix=$prefix \
common_tags="$common_tags" \
aks_version=$aks_version \
aks_service_principal_client_id=$aks_service_principal_client_id \
aks_service_principal_id=$aks_service_principal_id \
pe_rg_name=$pe_rg_name \
pe_vnet_name=$pe_vnet_name \
pe_subnet_name=$pe_subnet_name \
pe_is_manual_connection=$pe_is_manual_connection \
pe_request_message=$pe_request_message \
aks_name='aks-$(prefix)-$(environment)' \
resource_group='rg-$(prefix)-$(environment)' \
vnet_name='vnet-$(prefix)-$(environment)' \
acr_name='acr$(prefix)$(environment)' \
acr='$(acr_name).azurecr.io' \
storagekey='PipelineWillGetThisValueRuntime' \
terraformstorageaccount=$terraformstorageaccount \
terraformstoragerg=$terraformstoragerg \
terraformstoragecontainer=$terraformstoragecontainer \
terraformstorageblobname='$(prefix)/$(environment)/terraform.tfstate' \
build_id='$(Build.BuildId)'

# Create Variable Secrets
VAR_GROUP_ID=$(az pipelines variable-group list --group-name aks_dev_vars --top 1 --query "[0].id" -o tsv)
az pipelines variable-group variable create \
--group-id $VAR_GROUP_ID \
--secret true \
--name 'aks_service_principal_client_secret' \
--value $aks_service_principal_client_secret

# Create Infra Pipeline
az pipelines create --name 'Private.AKS.Infra.CI.CD' --yaml-path '/pipelines/infra/azure-pipelines.yml' --repository $ado_repo --repository-type tfsgit --branch $ado_repo_branch

# Create Application Pipeline
az pipelines create --name 'Private.AKS.App.CI.CD' --yaml-path '/pipelines/app/azure-pipelines.yml' --repository $ado_repo --repository-type tfsgit --branch $ado_repo_branch

