locals {
  # Following Azure Naming Conventions: 
  # https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging

  # General
  rg_name   = "rg-${var.prefix}-${var.environment_name}"
  
  vnet_name   = "vnet-${var.prefix}-${var.environment_name}"

  common_tags = merge(
    var.common_tags, 
    {
      environment = var.environment_name
      last_modified = formatdate("DD MMM YYYY hh:mm ZZZ", timestamp())
    }
  )
  
  # Azure Kubernetes Service
  aks_private_link_service_name = "pls-${var.prefix}-${var.environment_name}-aks"

  aks_private_link_endpoint_name = "pe-${var.prefix}-${var.environment_name}-aks"

  aks_private_link_endpoint_connection_name = "peconn-${var.prefix}-${var.environment_name}-aks"
  
  aks_private_dns_link_name = "dnslink-${var.prefix}-${var.environment_name}-aks"

  aks_rg_name = "MC_${local.rg_name}_${local.aks_name}_${var.location}"

  aks_name = "aks-${var.prefix}-${var.environment_name}"

  aks_dns_prefix = "aks${var.prefix}${var.environment_name}"

  aks_node_count = 1

  # Azure Container Registry
  acr_name = "acr${var.prefix}${var.environment_name}"

  acr_ado_private_link_endpoint_name = "pe-${var.prefix}-${var.environment_name}-acr-ado"

  acr_ado_private_link_endpoint_connection_name = "peconn-${var.prefix}-${var.environment_name}-acr-ado"

  acr_private_link_endpoint_name = "pe-${var.prefix}-${var.environment_name}-acr"

  acr_private_link_endpoint_connection_name = "peconn${var.prefix}-${var.environment_name}-aks"
  
  acr_ado_private_dns_link_name = "dnslink-${var.prefix}-${var.environment_name}-acr-ado"
  
  acr_private_dns_link_name = "dnslink-${var.prefix}-${var.environment_name}-acr"
  
  # Log Analytics - Monitor
  log_analytics_workspace_name = "log-${var.prefix}-${var.environment_name}"
  
  log_analytics_workspace_sku = "PerGB2018"

}
