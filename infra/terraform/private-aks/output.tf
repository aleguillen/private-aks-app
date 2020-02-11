output "acr_id" {
  value = "${azurerm_container_registry.acr.id}"
}

# output "aks_private_link_service_id" {
#   value = "${azurerm_private_link_service.pls.id}"
# }

output "aks_client_certificate" {
  value = "${azurerm_kubernetes_cluster.k8s.kube_config.0.client_certificate}"
}

output "aks_kube_config" {
  value = "${azurerm_kubernetes_cluster.k8s.kube_config_raw}"
}