locals {
  # General
  rg_name   = "${var.prefix}-${var.environment_name}-rg"

  vnet_name   = "${var.prefix}-${var.environment_name}-vnet"

  nsg_name   = "${var.prefix}-${var.environment_name}-default-nsg"

  common_tags = merge(
    var.common_tags, 
    {
      environment = var.environment_name
      last_modified_on  = formatdate("DD MMM YYYY hh:mm ZZZ", timestamp())
    }
  )
  
  # ADO Agent Pool - Agents details
  ado_vm_name   = "${var.prefix}-${var.environment_name}-ado-vm" 
  
  ado_vmss_name   = "${var.prefix}-${var.environment_name}-ado-vmss" 
  
  ado_vm_computer_name   = "${var.prefix}-${var.environment_name}-ado"
  
  ado_vm_os_name   = "${var.prefix}-${var.environment_name}-ado-vm-osdisk"

  ado_nic_name   = "${var.prefix}-${var.environment_name}-ado-vm-nic"

  # Terraform
  tf_container_name = "terraform"
  
  blob_private_dns_link_name = "${var.prefix}-${var.environment_name}-blob-link"
}
