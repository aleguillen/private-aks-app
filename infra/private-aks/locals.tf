locals {
  # General
  rg_name   = "${var.prefix}-${var.environment_name}-rg"
  
  vnet_name   = "${var.prefix}-${var.environment_name}-vnet"

  common_tags = merge(
    var.common_tags, 
    {
      environment = var.environment_name
      last_modified = formatdate("DD MMM YYYY hh:mm ZZZ", timestamp())
      created = formatdate("DD MMM YYYY hh:mm ZZZ", timestamp())
    }
  )
  
  # Azure Kubernetes Service
  aks_private_link_service_name = "${var.prefix}-${var.environment_name}-aks-pls"

  aks_private_link_endpoint_name = "${var.prefix}-${var.environment_name}-aks-pe"

  aks_private_link_endpoint_connection_name = "${var.prefix}-${var.environment_name}-aks-connection"
  
  aks_private_dns_link_name = "${var.prefix}-${var.environment_name}-aks-dns-link"

  aks_rg_name = "MC_${local.rg_name}_${local.aks_name}_${var.location}"

  aks_name = "${var.prefix}-${var.environment_name}-aks"

  aks_dns_prefix = "${var.prefix}${var.environment_name}aks"

  aks_node_count = 1

  # Azure Container Registry
  acr_name = "${var.prefix}${var.environment_name}acr"

  acr_ado_private_link_endpoint_name = "${var.prefix}-${var.environment_name}-acr-ado-pe"

  acr_ado_private_link_endpoint_connection_name = "${var.prefix}-${var.environment_name}-acr-ado-connection"

  acr_private_link_endpoint_name = "${var.prefix}-${var.environment_name}-acr-pe"

  acr_private_link_endpoint_connection_name = "${var.prefix}-${var.environment_name}-aks-connection"
  
  acr_ado_private_dns_link_name = "${var.prefix}-${var.environment_name}-acr-ado-dns-link"
  
  acr_private_dns_link_name = "${var.prefix}-${var.environment_name}-acr-dns-link"
  
  # Log Analytics - Monitor
  log_analytics_workspace_name = "${var.prefix}-${var.environment_name}-law"
  
  log_analytics_workspace_sku = "PerGB2018"

}
