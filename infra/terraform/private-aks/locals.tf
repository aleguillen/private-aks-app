locals {
  rg_name   = "${var.prefix}-${var.environment_name}-rg"
  
  vnet_name   = "${var.prefix}-${var.environment_name}-vnet"

  aks_private_link_service_name = "${var.prefix}-${var.environment_name}-aks-pls"

  aks_private_link_endpoint_name = "${var.prefix}-${var.environment_name}-aks-pe"

  aks_private_link_endpoint_connection_name = "${var.prefix}-${var.environment_name}-aks-connection"
  
  aks_private_dns_link_name = "${var.prefix}-${var.environment_name}-aks-dns-link"

  acr_name = "${var.prefix}${var.environment_name}acr"
  
  aks_rg_name = "MC_${local.rg_name}_${local.aks_name}_${var.location}"

  aks_name = "${var.prefix}-${var.environment_name}-aks"

  aks_dns_prefix = "${var.prefix}${var.environment_name}aks"

  aks_node_count = 1

  log_analytics_workspace_name = "${var.prefix}-${var.environment_name}-law"
  
  log_analytics_workspace_sku = "PerGB2018"


  common_tags = {
    environment = var.environment_name
    source      = "terraform"
    owner       = "Alejandra Guillen"
  }
}
