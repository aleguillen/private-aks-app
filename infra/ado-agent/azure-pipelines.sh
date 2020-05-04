#!/bin/bash

# Adding Azure DevOps Extension
az extension add --name azure-devops

#################################################
################# Variables #####################
#################################################

ORG_URL='https://dev.azure.com/<your-organization-name>'
PROJECT_NAME='<your-project-name>'

# Environment Name: Most common examples: DEV, ACC, PRD, QA (Abbreviate if possible)
environment='dev'

# Azure region / location. Modify as needed.
location='eastus2' 

# Prefix for all your resources. Use alphanumeric characters only. Avoid special characters. Ex. ado001
# Ex. For resource group: <prefix>-<environment>-rg
prefix='ado001'

# Virtual Machine Credentials
vm_username='adoadmin' 
vm_password='<replace-me>'

# Azure DevOps PAT token to configure Self-Hosted Agent
ado_pat_token='<replace-me>'

# Agent Pool Nanme
ado_pool_name='Default'

# ADO variable group name - if you change this name you will need to change azure-pipelines.yml file.
ado_var_group_name='ado_dev_vars'

# ADO Pipeline Name
ado_pipeline_name='ADO.Infra.CI.CD'

# Pipeline Yaml file path location
ado_pipeline_yml_path='/infra/ado-agent/azure-pipelines.yml'

# Azure Repo name for pipeline.
ado_repo='private-aks-app'
ado_repo_branch='master'

#################################################
################### Setup #######################
#################################################

# Make sure your Azure DevOps defaults include the organization and project from the command prompt
az devops configure --defaults organization=$ORG_URL project=$PROJECT_NAME

# Sign in to the Azure CLI
az login

# Create ADO Variable group with non-secret variables
az pipelines variable-group create \
--name $ado_var_group_name \
--authorize true \
--variables \
environment=$environment \
location=$location \
prefix=$prefix \
vm_username=$vm_username \
ado_pool_name=$ado_pool_name \
resource_group='$(prefix)-$(environment)-rg' \
storagekey='PipelineWillGetThisValueRuntime' \
terraformstorageaccount='tf$(prefix)$(environment)sa' \
terraformstoragerg='tf-$(prefix)-$(environment)-rg' \
ado_server_url='$(System.TeamFoundationCollectionUri)'

# Create Variable Secrets
VAR_GROUP_ID=$(az pipelines variable-group list --group-name $ado_var_group_name --top 1 --query "[0].id" -o tsv)
az pipelines variable-group variable create \
--group-id $VAR_GROUP_ID \
--secret true \
--name 'vm_password' \
--value $vm_password

az pipelines variable-group variable create \
--group-id $VAR_GROUP_ID \
--secret true \
--name 'ado_pat_token' \
--value $ado_pat_token

# Create Pipeline
az pipelines create --name $ado_pipeline_name --yaml-path $ado_pipeline_yml_path --repository $ado_repo --repository-type tfsgit --branch $ado_repo_branch
