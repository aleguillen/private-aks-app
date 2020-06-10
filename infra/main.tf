# CREATE: Resource Group
resource "azurerm_resource_group" "k8s" {
  name      = local.rg_name
  location  = var.location
  tags = merge(
    local.common_tags, 
    {
        display_name = "App AKS Resource Group",
        created = formatdate("DD MMM YYYY hh:mm ZZZ", timestamp())
    }
  )

  lifecycle {
    ignore_changes = [
      tags["created"],
    ]
  }
}

data "azurerm_subnet" "ado_pe" {
  name                 = var.pe_subnet_name
  resource_group_name  = var.pe_rg_name
  virtual_network_name = var.pe_vnet_name
}

data "azurerm_virtual_network" "ado_pe" {
  resource_group_name = var.pe_rg_name
  name = var.pe_vnet_name
}

# Update PE Subnet - setting enforce_private_link_endpoint_network_policies to true
# Using Null resource and local-exec, since resource was created previously and not imported into this state file.
resource "null_resource" "azurerm_subnet_ado_pe" {
  triggers = {
    enforce_private_link_endpoint_network_policies = data.azurerm_subnet.ado_pe.enforce_private_link_endpoint_network_policies
  }

  provisioner "local-exec" {
    command = <<EOT
      az login --service-principal --username $ARM_CLIENT_ID --password $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID
      
      az account set --subscription $ARM_SUBSCRIPTION_ID

      az network vnet subnet update --ids ${data.azurerm_subnet.ado_pe.id} --disable-private-endpoint-network-policies true 
    EOT
  }
}