output "acr_id" {
  value = azurerm_container_registry.acr.id
}

output "ado_subnet" {
  value = data.azurerm_subnet.ado_pe.id
}

output "aks_private_fqdn" {
  value = azurerm_kubernetes_cluster.k8s.private_fqdn
}

output "aks_client_certificate" {
  value = azurerm_kubernetes_cluster.k8s.kube_config.0.client_certificate
}

output "aks_kube_config" {
  value = azurerm_kubernetes_cluster.k8s.kube_config_raw
}

output "ado_acr_pe" {
  value = azurerm_private_endpoint.ado_acr_pe
}

output "aks_acr_pe" {
  value = azurerm_private_endpoint.aks_acr_pe
}
