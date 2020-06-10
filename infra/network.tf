
# CREATE: AKS VNET and Subnets
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
  address_prefixes     = ["192.168.0.0/24"]

  enforce_private_link_service_network_policies = true
}

resource "azurerm_subnet" "default" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.k8s.name
  virtual_network_name = azurerm_virtual_network.k8s.name
  address_prefixes     = ["192.168.1.0/24"]

  enforce_private_link_endpoint_network_policies = true
  
  service_endpoints = []
}