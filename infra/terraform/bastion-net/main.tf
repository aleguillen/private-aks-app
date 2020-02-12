terraform {
  required_version = ">= 0.12" 
  backend "azurerm" {
      storage_account_name = "__terraformstorageaccount__"
      container_name       = "terraform"
      key                  = "terraform.tfstate"
      access_key  ="__storagekey__"
  }
}

resource "azurerm_resource_group" "bastion" {
  name      = local.rg_name
  location  = var.location
  tags = merge(
    local.common_tags, 
    {
        display_name = "Bastion Resource Group"
    }
  )
}

resource "azurerm_network_security_group" "bastion" {
  name                = local.nsg_name
  location            = azurerm_resource_group.bastion.location
  resource_group_name = azurerm_resource_group.bastion.name

  tags = merge(
    local.common_tags, 
    {
        display_name = "Bastion Network Security Group - Default Subnet"
    }
  )
}

resource "azurerm_virtual_network" "bastion" {
  name                = local.vnet_name
  location            = azurerm_resource_group.bastion.location
  resource_group_name = azurerm_resource_group.bastion.name
  address_space       = ["10.0.0.0/16"]

  tags = merge(
    local.common_tags, 
    {
        display_name = "Bastion Virtual Network"
    }
  )
}

resource "azurerm_subnet" "default" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.bastion.name
  virtual_network_name = azurerm_virtual_network.bastion.name
  address_prefix       = "10.0.1.0/24"
}

resource "azurerm_subnet_network_security_group_association" "default" {
  subnet_id                 = azurerm_subnet.default.id
  network_security_group_id = azurerm_network_security_group.bastion.id
}

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.bastion.name
  virtual_network_name = azurerm_virtual_network.bastion.name
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_subnet" "ado" {
  name                 = "devops"
  resource_group_name  = azurerm_resource_group.bastion.name
  virtual_network_name = azurerm_virtual_network.bastion.name
  address_prefix       = "10.0.3.0/24"

  service_endpoints = [
    "Microsoft.ContainerRegistry"
  ]
}

# Azure Bastion Host setup
resource "azurerm_public_ip" "bastion" {
  name                = "bastion-ip"
  location            = azurerm_resource_group.bastion.location
  resource_group_name = azurerm_resource_group.bastion.name
  allocation_method   = "Static"
  sku                 = "Standard"
  
  tags = merge(
    local.common_tags, 
    {
        display_name = "Public IP for Bastion VM"
    }
  )
}

resource "azurerm_bastion_host" "bastion" {
  name                = "bastion-vm"
  location            = azurerm_resource_group.bastion.location
  resource_group_name = azurerm_resource_group.bastion.name

  ip_configuration {
    name                 = "ipconfig"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
}

# Windows Server 2019 - JumpServer VM

resource "azurerm_network_interface" "jumpserver" {
  name                = local.nic_name
  location            = azurerm_resource_group.bastion.location
  resource_group_name = azurerm_resource_group.bastion.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.default.id
    private_ip_address_allocation = "Dynamic"
  }
  
  tags = merge(
    local.common_tags, 
    {
        display_name = "NIC for Bastion VM"
    }
  )
}

resource "azurerm_virtual_machine" "bastion" {
  name                  = local.vm_name
  location              = azurerm_resource_group.bastion.location
  resource_group_name   = azurerm_resource_group.bastion.name
  network_interface_ids = [azurerm_network_interface.jumpserver.id]
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name              = local.vm_os_name
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = local.vm_computer_name
    admin_username = var.bastion_vm_username
    admin_password = var.bastion_vm_password
  }

  os_profile_windows_config {
    provision_vm_agent = true
  }

  tags = merge(
    local.common_tags, 
    {
        display_name = "Bastion VM"
    }
  )
}

# Linux - Azure DevOps Agent
resource "azurerm_network_interface" "ado" {
  name                = local.ado_nic_name
  location            = azurerm_resource_group.bastion.location
  resource_group_name = azurerm_resource_group.bastion.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.ado.id
    private_ip_address_allocation = "Dynamic"
  }
  
  tags = merge(
    local.common_tags, 
    {
        display_name = "NIC for ADO VM"
    }
  )
}

# ADO Configuration
data "template_file" "cloudinit" {
  template = file("/scripts/cloudinit.tpl")

  vars = {
    server_url = var.ado_server_url
    pat_token = var.ado_pat_token
    pool_name = var.ado_pool_name
  }
}

data "template_cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  part {
    content = data.template_file.cloudinit.rendered
  }
}

resource "azurerm_virtual_machine" "ado" {
  name                  = local.ado_vm_name
  location              = azurerm_resource_group.bastion.location
  resource_group_name   = azurerm_resource_group.bastion.name
  network_interface_ids = [azurerm_network_interface.ado.id]
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = local.ado_vm_os_name
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = local.ado_vm_computer_name
    admin_username = var.ado_vm_username
    admin_password = var.ado_vm_password
    
    custom_data = data.template_cloudinit_config.config.rendered
  }
  

  os_profile_linux_config {
    disable_password_authentication = false
    # ssh_keys {
    #   path     = "/home/${var.admin_username}/.ssh/authorized_keys"
    #   key_data = length(var.ssh_key_path) > 0 ? file(var.ssh_key_path) : var.ssh_key_data
    # }
  }

  tags = merge(
    local.common_tags, 
    {
        display_name = "Azure DevOps VM"
    }
  )

  lifecycle {
    ignore_changes = [ 
      os_profile
    ]
  }
}