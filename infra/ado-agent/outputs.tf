output "subnet_id" {
  value = azurerm_subnet.ado.id
}

output "ado_vm_id" {
  value = azurerm_linux_virtual_machine.ado.*.id
}

output "ado_vmss_id" {
  value = azurerm_linux_virtual_machine_scale_set.ado.*.id
}

output "storage_id" {
  value = azurerm_storage_account.ado.id
}

output "storage_pe_ip_address" {
  value = azurerm_private_endpoint.ado.private_service_connection.0.private_ip_address
}