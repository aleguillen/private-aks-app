locals {
  rg_name   = "${var.prefix}-${var.environment_name}-rg"

  vnet_name   = "${var.prefix}-${var.environment_name}-vnet"


  vm_name   = "${var.prefix}-${var.environment_name}-jumpserver-vm"
  
  vm_computer_name   = "jumpserver-vm"
  
  vm_os_name   = "${var.prefix}-${var.environment_name}-jumpserver-vm-osdisk"

  nic_name   = "${var.prefix}-${var.environment_name}-jumpserver-vm-nic"

  nsg_name   = "${var.prefix}-${var.environment_name}-default-nsg"


  ado_vm_name   = "${var.prefix}-${var.environment_name}-ado-vm"
  
  ado_vm_computer_name   = "${var.prefix}-${var.environment_name}-ado"
  
  ado_vm_os_name   = "${var.prefix}-${var.environment_name}-ado-vm-osdisk"

  ado_nic_name   = "${var.prefix}-${var.environment_name}-ado-vm-nic"


  common_tags = {
    environment = var.environment_name
    source      = "terraform"
    owner       = "Alejandra Guillen"
  }
}
