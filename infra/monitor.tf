
# CREATE: Log Analytics Workspace to monitor Container
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