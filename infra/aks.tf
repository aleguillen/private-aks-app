
##
# CREATE: AKS Cluster Outbound Public IP
##
resource "azurerm_public_ip" "k8s" {
  name                = "${local.aks_name}-ip"
  resource_group_name = azurerm_resource_group.k8s.name
  location            = azurerm_resource_group.k8s.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

##
# CREATE: AKS Cluster
##
resource "azurerm_kubernetes_cluster" "k8s" {
  name                = local.aks_name
  resource_group_name = azurerm_resource_group.k8s.name
  location            = azurerm_resource_group.k8s.location
  dns_prefix          = local.aks_dns_prefix

  private_cluster_enabled = true
  
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
    
    load_balancer_profile {
      outbound_ip_address_ids = [ "${azurerm_public_ip.k8s.id}" ]
    }

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
# CREATE: Private Endpoint and Private DNS Zone on the ado Deployment for connectivity
##

resource "azurerm_private_endpoint" "ado_aks_pe" {
  name                = local.aks_private_link_endpoint_name
  location            = azurerm_resource_group.k8s.location
  resource_group_name = var.pe_rg_name

  subnet_id           = data.azurerm_subnet.ado_pe.id
  
  private_service_connection {
    is_manual_connection = var.pe_is_manual_connection
    request_message = var.pe_is_manual_connection == "true" ? var.pe_request_message : null
    name = local.aks_private_link_endpoint_connection_name
    private_connection_resource_id = azurerm_kubernetes_cluster.k8s.id
    subresource_names = ["management"]
  }

  tags = merge(
    local.common_tags, 
    {
        display_name = "ADO to AKS Private Endpoint"
    }
  )
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
  records             = [azurerm_private_endpoint.ado_aks_pe.private_service_connection.0.private_ip_address]
}

resource "azurerm_private_dns_zone_virtual_network_link" "example" {
  name                  = local.aks_private_dns_link_name
  resource_group_name   = var.pe_rg_name
  private_dns_zone_name = azurerm_private_dns_zone.privatedns.name
  virtual_network_id    = data.azurerm_virtual_network.ado_pe.id
}
