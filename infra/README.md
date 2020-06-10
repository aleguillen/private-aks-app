# Private AKS Cluster

Deploying private access Azure Kubernetes Services (AKS) cluster. On this example we will be using private Azure Container Registry (ACR) with Private Link. You can execute this locally or using Azure Pipelines.

## Azure Pipelines Setup

You can use [Azure DevOps CLI script](/pipelines/azure-pipelines.sh) to configure configure it (recommended) or you can use DevOps portal and perform these steps manually:

* [Login or Sign Up](https://dev.azure.com) into your Azure DevOps Organization.
* Create a new project in Azure DevOps, for information see [here](https://docs.microsoft.com/en-us/azure/devops/organizations/projects/create-project).
    * Sample name: **private-aks-app**
* For the Agent pool, we will be using **Default** Agent Pool. 
    *Alternately you can create a new Agent Pool in your project, for more information see [here](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/pools-queues), if you do update all pipelines files **azure-pipelines.yml** file and variable group value.
        * Example Name: **MyPrivatePool**
        * Keep option **Grant access permission to all pipelines** checked.
* Create a new Azure Service Connection to your Azure Subscription, for more information see [here](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints)
    * Connection type: **Azure Resource Manager**.
    * Authentication Method: **Service Principal (automatic)** - this option will automatically create the Service Principal on your behalf, if you don't have permissions to create a Service Principal please use the manual option. 
    * Scope level: Select the appropiate level, for this project I used **Subscription**.
    * Service connection name: **sc-private-aks-app-azure-subscription**.
    
    **Note: The Service connection name can be customized, just remember to update all azure-pipelines.yml files to use the right Service Connection name in the variables section.**

* Create a Personal Access Token (PAT token), we will use this token to configure the Self Hosted Agent for Azure DevOps. For more information on how to create a PAT token see [here](https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate).
* [Import Git](https://docs.microsoft.com/en-us/azure/devops/repos/git/import-git-repository) repo into your Azure DevOps project.
    * Git source Url: https://github.com/aleguillen/private-aks-app.git
* (Optional) Clone imported repo in your local computer, for more info see [here](https://docs.microsoft.com/en-us/azure/devops/repos/git/clone).
* Create ADO Variable group **aks_dev_vars**. Replace variables with your own preferred values, also check for all **<-replace-me->** values and update them accordingly. 
    * In the left panel, click and expand **Pipelines**.
    * Under Pipelines, click **Library**.
    * Click the **+ Variable group** button.
    * Enter a name for the variable group in the Variable Group Name field.
        * Variable group name: **aks_dev_vars**
        * Description example: **ADO Development Variables**
    * Click the **+ Add** button to create a new variable for the group.
    * Fill in the variable Name and Value. Here is an example

    | Name | Example Value | Is Secret |
    | -- | -- | -- |
    |  |  |  |
    |  |  |  |
    |  |  |  |
    |  |  |  |
    |  |  |  |

## Running with Terraform locally

* Copy and paste file **terraform.tfvars** and name the new file **terraform.auto.tfvars** use this new file to set your local variables values. Terraform will use this file instead for local executions, for more information see [here](https://www.terraform.io/docs/configuration/variables.html#variable-definition-precedence).
* Comment line 'backend "azurerm" {}' inside **terraform.tf**. You can use Azure CLI authentication locally.
* Run the following commands.

    ```bash
    # Set infra directory
    cd ./infra
    # Login into Azure
    az login 

    # Run Terraform commands:
    # Initialize a Terraform working directory
    terraform init
    # Generate and show an execution plan
    terraform plan
    # Builds or changes infrastructure. Using -auto-approve will skip interactive approval of plan before applying. 
    terraform apply -auto-approve
    ```
