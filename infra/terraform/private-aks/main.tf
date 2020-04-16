# Create Resource Group
resource "azurerm_resource_group" "k8s" {
  name      = local.rg_name
  location  = var.location
  tags = merge(
    local.common_tags, 
    {
        display_name = "App AKS Resource Group"
    }
    )
}

resource "azurerm_virtual_network" "k8s" {
  name                = local.vnet_name
  location            = azurerm_resource_group.k8s.location
  resource_group_name = azurerm_resource_group.k8s.name
  address_space       = ["192.168.0.0/16"]

  tags = merge(
    local.common_tags, 
    {
        display_name = "AKS Virtual Network"
    }
  )
}

resource "azurerm_subnet" "proxy" {
  name                 = "proxy-subnet"
  resource_group_name  = azurerm_resource_group.k8s.name
  virtual_network_name = azurerm_virtual_network.k8s.name
  address_prefix       = "192.168.0.0/24"

  enforce_private_link_service_network_policies = true
}

resource "azurerm_subnet" "default" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.k8s.name
  virtual_network_name = azurerm_virtual_network.k8s.name
  address_prefix       = "192.168.1.0/24"

  enforce_private_link_endpoint_network_policies = true
  
  service_endpoints = []
}

resource "random_id" "log_analytics_workspace_name_suffix" {
    byte_length = 8
}

resource "azurerm_log_analytics_workspace" "monitor" {
  # The WorkSpace name has to be unique across the whole of azure, not just the current subscription/tenant.
  name                = "${local.log_analytics_workspace_name}-${random_id.log_analytics_workspace_name_suffix.dec}"
  location            = azurerm_resource_group.k8s.location
  resource_group_name = azurerm_resource_group.k8s.name
  sku                 = local.log_analytics_workspace_sku

  tags = merge(
    local.common_tags, 
    {
        display_name = "Log Analitics Workspace for Container Insights"
    }
  )
}

resource "azurerm_log_analytics_solution" "monitor" {
  solution_name         = "ContainerInsights"
  location              = azurerm_log_analytics_workspace.monitor.location
  resource_group_name   = azurerm_resource_group.k8s.name
  workspace_resource_id = azurerm_log_analytics_workspace.monitor.id
  workspace_name        = azurerm_log_analytics_workspace.monitor.name

  plan {
      publisher = "Microsoft"
      product   = "OMSGallery/ContainerInsights"
  }
}

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
# CREATE: Private Endpoint in Bastion Subnet to ACR
##

data "azurerm_subnet" "bastion_pe" {
  name                 = var.pe_subnet_name
  resource_group_name  = var.pe_rg_name
  virtual_network_name = var.pe_vnet_name
}

data "azurerm_virtual_network" "bastion_pe" {
  resource_group_name = var.pe_rg_name
  name = var.pe_vnet_name
}

# Update PE Subnet - setting enforce_private_link_endpoint_network_policies to true
# Moved to Pipeline Azure CLI previous execution
# resource "azurerm_subnet" "bastion_pe" {
#   name                                                     = data.azurerm_subnet.bastion_pe.name
#   resource_group_name                                      = data.azurerm_subnet.bastion_pe.resource_group_name
#   virtual_network_name                                     = data.azurerm_subnet.bastion_pe.virtual_network_name
#   address_prefix                                           = data.azurerm_subnet.bastion_pe.address_prefix
#   service_endpoints                                        = data.azurerm_subnet.bastion_pe.service_endpoints
#   enforce_private_link_service_network_policies            = data.azurerm_subnet.bastion_pe.enforce_private_link_service_network_policies 

#   enforce_private_link_endpoint_network_policies = true
# }

resource "azurerm_private_endpoint" "bastion_acr_pe" {
  name                = local.acr_bastion_private_link_endpoint_name
  location            = azurerm_resource_group.k8s.location
  resource_group_name = var.pe_rg_name

  subnet_id           = data.azurerm_subnet.bastion_pe.id
  
  private_service_connection {
    is_manual_connection = var.pe_is_manual_connection
    request_message = var.pe_is_manual_connection == "true" ? var.pe_request_message : null
    name = local.acr_bastion_private_link_endpoint_connection_name
    private_connection_resource_id = azurerm_container_registry.acr.id
    subresource_names = ["registry"]
  }
}

data "azurerm_private_endpoint_connection" "bastion_acr_pe" {
  name                = local.acr_bastion_private_link_endpoint_name
  resource_group_name = var.pe_rg_name

  depends_on = [
    azurerm_private_endpoint.bastion_acr_pe
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

data "azurerm_private_endpoint_connection" "aks_acr_pe" {
  name                = local.acr_private_link_endpoint_name
  resource_group_name = azurerm_resource_group.k8s.name

  depends_on = [
    azurerm_private_endpoint.aks_acr_pe
  ]
}

##
# CREATE: Private DNS Zone for ACR in Bastion VNET
##
resource "azurerm_private_dns_zone" "bastion_dns_zone" {
  name                = "privatelink.azurecr.io"  
  resource_group_name = var.pe_rg_name
}

# resource "azurerm_private_dns_a_record" "registry_record" {
#   name                = azurerm_container_registry.acr.name
#   zone_name           = azurerm_private_dns_zone.bastion_dns_zone.name
#   resource_group_name = var.pe_rg_name
#   ttl                 = 3600
#   records             = [data.azurerm_private_endpoint_connection.bastion_acr_pe.private_service_connection.0.private_ip_address]
# }

# resource "azurerm_private_dns_a_record" "registry_record2" {
#   name                = "${azurerm_container_registry.acr.name}.${azurerm_container_registry.acr.location}.data"
#   zone_name           = azurerm_private_dns_zone.bastion_dns_zone.name
#   resource_group_name = var.pe_rg_name
#   ttl                 = 3600
#   records             = [data.azurerm_private_endpoint_connection.bastion_acr_pe.private_service_connection.0.private_ip_address]
# }


resource "null_resource" "acr_registries_record_bastion" {
  
  provisioner "local-exec" {
    # Azure Login
    command = "az login --service-principal --username $clientId --password $secret --tenant $tenantId"
  }
  
  provisioner "local-exec" {
    # Azure set Subscription Id
    command = "az account set --subscription $subscription"
  }
  
  provisioner "local-exec" {
    # Get Private Endpoint Network Interface
    command = "networkInterfaceID=$(az network private-endpoint show --ids ${data.azurerm_private_endpoint_connection.bastion_acr_pe.id} --query 'networkInterfaces[0].id' --output tsv)"
  }

  provisioner "local-exec" {
    # Get Ip Configuration - ACR IP Address
    command = "privateIP=$(az resource show --ids $networkInterfaceID --api-version 2019-04-01 --query 'properties.ipConfigurations[1].properties.privateIPAddress' --output tsv)"
  }

  provisioner "local-exec" {
    # Get Ip Configuration - ACR Data Endpoint IP Address
    command = "dataEndpointPrivateIP=$(az resource show --ids $networkInterfaceID --api-version 2019-04-01 --query 'properties.ipConfigurations[0].properties.privateIPAddress' --output tsv)"
  }

  provisioner "local-exec" {
    # Create DNS record for ACR
    command = "az network private-dns record-set a add-record --record-set-name ${azurerm_container_registry.acr.name} --zone-name ${azurerm_private_dns_zone.bastion_dns_zone.name} --resource-group ${var.pe_rg_name} --ipv4-address $privateIP"
  }
  
  provisioner "local-exec" {
    # Create DNS record for ACR Data Endpoint
    command = "az network private-dns record-set a add-record --record-set-name ${azurerm_container_registry.acr.name}.${azurerm_container_registry.acr.location}.data --zone-name ${azurerm_private_dns_zone.bastion_dns_zone.name} --resource-group ${var.pe_rg_name} --ipv4-address $dataEndpointPrivateIP"
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns_vnet_link_acr_bastion" {
  name                  = local.acr_bastion_private_dns_link_name
  resource_group_name   = var.pe_rg_name
  private_dns_zone_name = azurerm_private_dns_zone.bastion_dns_zone.name
  virtual_network_id    = data.azurerm_virtual_network.bastion_pe.id
}

##
# CREATE: Private DNS Zone for ACR in AKS VNET
##
resource "azurerm_private_dns_zone" "aks_dns_zone" {
  name                = "privatelink.azurecr.io"  
  resource_group_name = azurerm_resource_group.k8s.name
}

# resource "azurerm_private_dns_a_record" "registry_record_aks" {
#   name                = azurerm_container_registry.acr.name
#   zone_name           = azurerm_private_dns_zone.aks_dns_zone.name
#   resource_group_name = azurerm_resource_group.k8s.name
#   ttl                 = 3600
#   records             = [data.azurerm_private_endpoint_connection.aks_acr_pe.private_service_connection.0.private_ip_address]
# }

# resource "azurerm_private_dns_a_record" "registry_record2_aks" {
#   name                = "${azurerm_container_registry.acr.name}.${azurerm_container_registry.acr.location}.data"
#   zone_name           = azurerm_private_dns_zone.aks_dns_zone.name
#   resource_group_name = azurerm_resource_group.k8s.name
#   ttl                 = 3600
#   records             = [data.azurerm_private_endpoint_connection.aks_acr_pe.private_service_connection.0.private_ip_address]
# }

resource "null_resource" "acr_registries_record_aks" {

  provisioner "local-exec" {
    # Azure Login
    command = "az login --service-principal --username $clientId --password $secret --tenant $tenantId"
  }
  
  provisioner "local-exec" {
    # Azure set Subscription Id
    command = "az account set --subscription $subscription"
  }
  
  provisioner "local-exec" {
    # Get Private Endpoint Network Interface
    command = "networkInterfaceID=$(az network private-endpoint show --ids ${data.azurerm_private_endpoint_connection.aks_acr_pe.id} --query 'networkInterfaces[0].id' --output tsv)"
  }

  provisioner "local-exec" {
    # Get Ip Configuration - ACR IP Address
    command = "privateIP=$(az resource show --ids $networkInterfaceID --api-version 2019-04-01 --query 'properties.ipConfigurations[1].properties.privateIPAddress' --output tsv)"
  }

  provisioner "local-exec" {
    # Get Ip Configuration - ACR Data Endpoint IP Address
    command = "dataEndpointPrivateIP=$(az resource show --ids $networkInterfaceID --api-version 2019-04-01 --query 'properties.ipConfigurations[0].properties.privateIPAddress' --output tsv)"
  }

  provisioner "local-exec" {
    # Create DNS record for ACR
    command = "az network private-dns record-set a add-record --record-set-name ${azurerm_container_registry.acr.name} --zone-name ${azurerm_private_dns_zone.aks_dns_zone.name} --resource-group ${azurerm_resource_group.k8s.name} --ipv4-address $privateIP"
  }
  
  provisioner "local-exec" {
    # Create DNS record for ACR Data Endpoint
    command = "az network private-dns record-set a add-record --record-set-name ${azurerm_container_registry.acr.name}.${azurerm_container_registry.acr.location}.data --zone-name ${azurerm_private_dns_zone.aks_dns_zone.name} --resource-group ${azurerm_resource_group.k8s.name} --ipv4-address $dataEndpointPrivateIP"
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns_vnet_link_acr_aks" {
  name                  = local.acr_private_dns_link_name
  resource_group_name   = azurerm_resource_group.k8s.name
  private_dns_zone_name = azurerm_private_dns_zone.aks_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.k8s.id
}

##
# CREATE: AKS Cluster
##
resource "azurerm_kubernetes_cluster" "k8s" {
  name                = local.aks_name
  resource_group_name = azurerm_resource_group.k8s.name
  location            = azurerm_resource_group.k8s.location
  dns_prefix          = local.aks_dns_prefix

  private_link_enabled = true
  
  kubernetes_version = var.aks_version

  default_node_pool {
    name       = "default"
    node_count = local.aks_node_count
    vm_size    = "Standard_D2_v3"
    availability_zones = [1, 2, 3]

    vnet_subnet_id = azurerm_subnet.default.id
  }

  service_principal {
    client_id     = var.aks_service_principal_client_id
    client_secret = var.aks_service_principal_client_secret
  }

  network_profile {
    network_plugin = "kubenet"
    load_balancer_sku = "standard"

    docker_bridge_cidr = "172.17.0.1/16"
    pod_cidr = "10.244.0.0/16"
    service_cidr = "10.0.0.0/16"
    dns_service_ip = "10.0.0.10"
  }

  addon_profile {
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.monitor.id
    }

    kube_dashboard {
      enabled = true
    }
  }

  tags = merge(
    local.common_tags, 
    {
        display_name = "AKS Cluster"
    }
  )
}

# Add Subnet role assigment for Ingress Internal LB to be created. 
# This required ADO service connection to have Owner rights over current subscription (Contributor will not work)
resource "azurerm_role_assignment" "subnet_role_assignment" {
  scope                = azurerm_subnet.default.id
  role_definition_name = "Owner"
  principal_id         = var.aks_service_principal_id
}

##
# CREATE: Private Endpoint and Private DNS Zone on the Bastion Deployment for connectivity
##

resource "azurerm_private_endpoint" "bastion_aks_pe" {
  name                = local.aks_private_link_endpoint_name
  location            = azurerm_resource_group.k8s.location
  resource_group_name = var.pe_rg_name

  subnet_id           = data.azurerm_subnet.bastion_pe.id
  
  private_service_connection {
    is_manual_connection = var.pe_is_manual_connection
    request_message = var.pe_is_manual_connection == "true" ? var.pe_request_message : null
    name = local.aks_private_link_endpoint_connection_name
    private_connection_resource_id = azurerm_kubernetes_cluster.k8s.id
    subresource_names = ["management"]
  }
}

data "azurerm_private_endpoint_connection" "bastion_aks_pe" {
  name                = local.aks_private_link_endpoint_name
  resource_group_name = var.pe_rg_name

  depends_on = [
    azurerm_private_endpoint.bastion_aks_pe
  ]
}

resource "azurerm_private_dns_zone" "privatedns" {
  name                = join(".", slice(split(".",azurerm_kubernetes_cluster.k8s.private_fqdn),1,length(split(".",azurerm_kubernetes_cluster.k8s.private_fqdn))))  
  resource_group_name = var.pe_rg_name
}

resource "azurerm_private_dns_a_record" "record" {
  name                = split(".",azurerm_kubernetes_cluster.k8s.private_fqdn)[0]
  zone_name           = azurerm_private_dns_zone.privatedns.name
  resource_group_name = var.pe_rg_name
  ttl                 = 3600
  records             = [data.azurerm_private_endpoint_connection.bastion_aks_pe.private_service_connection.0.private_ip_address]
}

resource "azurerm_private_dns_zone_virtual_network_link" "example" {
  name                  = local.aks_private_dns_link_name
  resource_group_name   = var.pe_rg_name
  private_dns_zone_name = azurerm_private_dns_zone.privatedns.name
  virtual_network_id    = data.azurerm_virtual_network.bastion_pe.id
}
