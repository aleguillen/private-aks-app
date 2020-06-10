# CREATE: Azure Container Registry and Private Endpoints
# ACR and Private Link doc: https://docs.microsoft.com/en-us/azure/container-registry/container-registry-private-link
# ACR must be Premium
resource "azurerm_container_registry" "acr" {
  name                     = local.acr_name
  resource_group_name      = azurerm_resource_group.k8s.name
  location                 = azurerm_resource_group.k8s.location
  sku                      = "Premium"

  tags = merge(
    local.common_tags, 
    {
        display_name = "Azure Container Registry"
    }
  )
}

##
# CREATE: Private Endpoint in ado Subnet to ACR
##
resource "azurerm_private_endpoint" "ado_acr_pe" {
  name                = local.acr_ado_private_link_endpoint_name
  location            = azurerm_resource_group.k8s.location
  resource_group_name = var.pe_rg_name

  subnet_id           = data.azurerm_subnet.ado_pe.id
  
  private_service_connection {
    is_manual_connection = var.pe_is_manual_connection
    request_message = var.pe_is_manual_connection == "true" ? var.pe_request_message : null
    name = local.acr_ado_private_link_endpoint_connection_name
    private_connection_resource_id = azurerm_container_registry.acr.id
    subresource_names = ["registry"]
  }

  depends_on = [
    null_resource.azurerm_subnet_ado_pe
  ]
}

##
# CREATE: Private Endpoint in AKS Subnet to ACR
##
resource "azurerm_private_endpoint" "aks_acr_pe" {
  name                = local.acr_private_link_endpoint_name
  location            = azurerm_resource_group.k8s.location
  resource_group_name = azurerm_resource_group.k8s.name

  subnet_id           = azurerm_subnet.default.id
  
  private_service_connection {
    is_manual_connection = var.pe_is_manual_connection
    request_message = var.pe_is_manual_connection == "true" ? var.pe_request_message : null
    name = local.acr_private_link_endpoint_connection_name
    private_connection_resource_id = azurerm_container_registry.acr.id
    subresource_names = ["registry"]
  }
}

##
# CREATE: Private DNS Zone for ACR in ado VNET
##
resource "azurerm_private_dns_zone" "ado_dns_zone" {
  name                = "privatelink.azurecr.io"  
  resource_group_name = var.pe_rg_name
}

resource "azurerm_private_dns_a_record" "registry_record2" {
  name                = "${azurerm_container_registry.acr.name}.${azurerm_container_registry.acr.location}.data"
  zone_name           = azurerm_private_dns_zone.ado_dns_zone.name
  resource_group_name = var.pe_rg_name
  ttl                 = 3600
  records             = [azurerm_private_endpoint.ado_acr_pe.private_service_connection.0.private_ip_address]
}

# Moving to null_resource, since output of azurerm_private_endpoint does not contain all private ip address created for the PE.
# resource "azurerm_private_dns_a_record" "registry_record" {
#   name                = azurerm_container_registry.acr.name
#   zone_name           = azurerm_private_dns_zone.ado_dns_zone.name
#   resource_group_name = var.pe_rg_name
#   ttl                 = 3600
#   records             = [azurerm_private_endpoint.ado_acr_pe.private_service_connection.1.private_ip_address]
# }

resource "null_resource" "acr_registries_record_ado" {
  triggers = {
    always_run = uuid()
  }

  provisioner "local-exec" {
    command = <<EOT
      az login --service-principal --username $ARM_CLIENT_ID --password $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID
      
      az account set --subscription $ARM_SUBSCRIPTION_ID
      
      networkInterfaceID=$(az network private-endpoint show --ids ${azurerm_private_endpoint.ado_acr_pe.id} --query 'networkInterfaces[0].id' --output tsv)
      
      privateIP=$(az resource show --ids $networkInterfaceID --api-version 2019-04-01 --query 'properties.ipConfigurations[1].properties.privateIPAddress' --output tsv)
            
      if [ "$(az network private-dns record-set a list -g ${var.pe_rg_name} -z ${azurerm_private_dns_zone.ado_dns_zone.name} --query "[?name=='${azurerm_container_registry.acr.name}'].aRecords[0].ipv4Address" -o tsv)" = "" ] 
      then
        az network private-dns record-set a add-record --record-set-name ${azurerm_container_registry.acr.name} --zone-name ${azurerm_private_dns_zone.ado_dns_zone.name} --resource-group ${var.pe_rg_name} --ipv4-address $privateIP
      fi
      
    EOT
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns_vnet_link_acr_ado" {
  name                  = local.acr_ado_private_dns_link_name
  resource_group_name   = var.pe_rg_name
  private_dns_zone_name = azurerm_private_dns_zone.ado_dns_zone.name
  virtual_network_id    = data.azurerm_virtual_network.ado_pe.id
}

##
# CREATE: Private DNS Zone for ACR in AKS VNET
##
resource "azurerm_private_dns_zone" "aks_dns_zone" {
  name                = "privatelink.azurecr.io"  
  resource_group_name = azurerm_resource_group.k8s.name
}

resource "azurerm_private_dns_a_record" "registry_record2_aks" {
  name                = "${azurerm_container_registry.acr.name}.${azurerm_container_registry.acr.location}.data"
  zone_name           = azurerm_private_dns_zone.aks_dns_zone.name
  resource_group_name = azurerm_resource_group.k8s.name
  ttl                 = 3600
  records             = [azurerm_private_endpoint.aks_acr_pe.private_service_connection.0.private_ip_address]
}

# Moving to null_resource, since output of azurerm_private_endpoint does not contain all private ip address created for the PE.
# resource "azurerm_private_dns_a_record" "registry_record_aks" {
#   name                = azurerm_container_registry.acr.name
#   zone_name           = azurerm_private_dns_zone.aks_dns_zone.name
#   resource_group_name = azurerm_resource_group.k8s.name
#   ttl                 = 3600
#   records             = [azurerm_private_endpoint.aks_acr_pe.private_service_connection.1.private_ip_address]
# }

resource "null_resource" "acr_registries_record_aks" {
  triggers = {
    always_run = uuid()
  }
  
  provisioner "local-exec" {
    command = <<EOT
      az login --service-principal --username $ARM_CLIENT_ID --password $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID
      
      az account set --subscription $ARM_SUBSCRIPTION_ID
      
      networkInterfaceID=$(az network private-endpoint show --ids ${azurerm_private_endpoint.aks_acr_pe.id} --query 'networkInterfaces[0].id' --output tsv)
      
      privateIP=$(az resource show --ids $networkInterfaceID --api-version 2019-04-01 --query 'properties.ipConfigurations[1].properties.privateIPAddress' --output tsv)
            
      if [ "$(az network private-dns record-set a list -g ${azurerm_resource_group.k8s.name} -z ${azurerm_private_dns_zone.aks_dns_zone.name} --query "[?name=='${azurerm_container_registry.acr.name}'].aRecords[0].ipv4Address" -o tsv)" = "" ] 
      then
        az network private-dns record-set a add-record --record-set-name ${azurerm_container_registry.acr.name} --zone-name ${azurerm_private_dns_zone.aks_dns_zone.name} --resource-group ${azurerm_resource_group.k8s.name} --ipv4-address $privateIP
      fi
    EOT
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns_vnet_link_acr_aks" {
  name                  = local.acr_private_dns_link_name
  resource_group_name   = azurerm_resource_group.k8s.name
  private_dns_zone_name = azurerm_private_dns_zone.aks_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.k8s.id
}