# CREATE: Resource Group
resource "azurerm_resource_group" "ado" {
  name      = local.rg_name
  location  = var.location
  tags = merge(
    local.common_tags, 
    {
        display_name = "ADO Resource Group"
    }
  )
}

# CREATE: Network Security Group - prevent inbound internet connection.
resource "azurerm_network_security_group" "ado" {
  name                = local.nsg_name
  location            = azurerm_resource_group.ado.location
  resource_group_name = azurerm_resource_group.ado.name

  tags = merge(
    local.common_tags, 
    {
        display_name = "ADO Network Security Group - Default Subnet"
    }
  )
}

# CREATE: Virtual Network
resource "azurerm_virtual_network" "ado" {
  name                = local.vnet_name
  location            = azurerm_resource_group.ado.location
  resource_group_name = azurerm_resource_group.ado.name
  address_space       = ["10.0.0.0/16"]

  tags = merge(
    local.common_tags, 
    {
        display_name = "ADO Virtual Network"
    }
  )
}

# CREATE: Subnet
resource "azurerm_subnet" "ado" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.ado.name
  virtual_network_name = azurerm_virtual_network.ado.name
  address_prefixes     = ["10.0.1.0/24"]

  enforce_private_link_endpoint_network_policies = true

}

# UPDATE: Assign Network Security Group to Subnet
resource "azurerm_subnet_network_security_group_association" "ado" {
  subnet_id                 = azurerm_subnet.ado.id
  network_security_group_id = azurerm_network_security_group.ado.id
}

# CREATE: Storage Account for Boot Diagnostics
resource "azurerm_storage_account" "diag" {
    name                     = "diag${substr(md5(azurerm_resource_group.ado.id),0,15)}sa"
    resource_group_name      = azurerm_resource_group.ado.name
    location                 = azurerm_resource_group.ado.location
    account_tier             = "Standard"
    account_replication_type = "LRS"

    tags = merge(
        local.common_tags, 
        {
            display_name = "Diagnostics Storage Account"
        }
    )
}

# CREATE: Private Endpoint to Blob Storage for Diagnostics
resource "azurerm_private_endpoint" "diag" {
    name                = "${azurerm_storage_account.diag.name}-pe"
    location            = azurerm_resource_group.ado.location
    resource_group_name = azurerm_resource_group.ado.name
    subnet_id           = azurerm_subnet.ado.id

    private_service_connection {
      name                           = "${azurerm_storage_account.diag.name}-pecon"
      private_connection_resource_id = azurerm_storage_account.diag.id
      is_manual_connection           = false
      subresource_names              = ["blob"]
    }
  
    tags = merge(
        local.common_tags, 
        {
            display_name = "Private Endpoint to connect to Diagnostics Storage Account"
        }
    )
}

# CREATE: Storage Account for Terraform State file
resource "azurerm_storage_account" "ado" {
    name                     = "tf${substr(md5(azurerm_resource_group.ado.id),0,15)}sa"
    resource_group_name      = azurerm_resource_group.ado.name
    location                 = azurerm_resource_group.ado.location
    account_tier             = "Standard"
    account_replication_type = "LRS"

    tags = merge(
        local.common_tags, 
        {
            display_name = "Terraform Storage Account"
        }
    )
}

# CREATE: Storage Account Container for Terraform State file
resource "azurerm_storage_container" "ado" {
    name                  = local.tf_container_name
    storage_account_name  = azurerm_storage_account.ado.name
    container_access_type = "private"
}

# CREATE: Private Endpoint to Terraform Blob Storage
resource "azurerm_private_endpoint" "ado" {
    name                = "${azurerm_storage_account.ado.name}-pe"
    location            = azurerm_resource_group.ado.location
    resource_group_name = azurerm_resource_group.ado.name
    subnet_id           = azurerm_subnet.ado.id

    private_service_connection {
      name                           = "${azurerm_storage_account.ado.name}-pecon"
      private_connection_resource_id = azurerm_storage_account.ado.id
      is_manual_connection           = false
      subresource_names              = ["blob"]
    }
  
    tags = merge(
        local.common_tags, 
        {
            display_name = "Private Endpoint to connect to Storage Account"
        }
    )
}

# CREATE: Private DNS zone to blob endpoint
resource "azurerm_private_dns_zone" "blob" {
    name                = "privatelink.blob.core.windows.net"  
    resource_group_name = azurerm_resource_group.ado.name
    
    tags = merge(
        local.common_tags, 
        {
            display_name = "Private DNS zone to resolve storage private endpoint."
        }
    )
}

# CREATE: A record to Terraform Blob Storage.
resource "azurerm_private_dns_a_record" "tf" {
    name                = azurerm_storage_account.ado.name
    zone_name           = azurerm_private_dns_zone.blob.name
    resource_group_name = azurerm_resource_group.ado.name
    ttl                 = 3600
    records             = [azurerm_private_endpoint.ado.private_service_connection.0.private_ip_address]
    
    tags = merge(
        local.common_tags, 
        {
            display_name = "Private DNS record to Blob endpoint."
        }
    )
}

# CREATE: A record to Diagnostics Blob Storage.
resource "azurerm_private_dns_a_record" "diag" {
    name                = azurerm_storage_account.diag.name
    zone_name           = azurerm_private_dns_zone.blob.name
    resource_group_name = azurerm_resource_group.ado.name
    ttl                 = 3600
    records             = [azurerm_private_endpoint.diag.private_service_connection.0.private_ip_address]
    
    tags = merge(
        local.common_tags, 
        {
            display_name = "Private DNS record to Diagnostics Blob endpoint."
        }
    )
}

# CREATE: Link Private DNS zone with Virtual Network
resource "azurerm_private_dns_zone_virtual_network_link" "ado" {
    name                  = local.blob_private_dns_link_name
    resource_group_name   = azurerm_resource_group.ado.name
    private_dns_zone_name = azurerm_private_dns_zone.blob.name
    virtual_network_id    = azurerm_virtual_network.ado.id
    registration_enabled  = false
    
    tags = merge(
        local.common_tags, 
        {
            display_name = "Private DNS zone Link to VNET."
        }
    )
}

################################################################
# CREATE: Linux VM or VMSS Agent - for Azure DevOps Agent Pool #
################################################################

# GET: ADO Configuration cloudinit file. This can be converted to use an image.
data "template_file" "cloudinit" {
  template = file("${path.module}/scripts/cloudinit.tpl")

  vars = {
    server_url = var.ado_server_url
    pat_token = var.ado_pat_token
    pool_name = var.ado_pool_name
    vm_admin = var.ado_vm_username
  }
}

data "template_cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  part {
    content = data.template_file.cloudinit.rendered
  }
}

# CREATE: Private/Public SSH Key for Linux Virtual Machine
resource "tls_private_key" "ado" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# CREATE: Network Interface for Azure Linux VM as Azure DevOps Agent
# CREATE IF: ado_vmss_enabled is FALSE
resource "azurerm_network_interface" "ado" {
  count                 = var.ado_vmss_enabled ? 0 : 1
  name                = local.ado_nic_name
  location            = azurerm_resource_group.ado.location
  resource_group_name = azurerm_resource_group.ado.name

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

# CREATE: Azure Linux VM as Azure DevOps Agent
# CREATE IF: ado_vmss_enabled is FALSE
resource "azurerm_linux_virtual_machine" "ado" {
  count                 = var.ado_vmss_enabled ? 0 : 1

  name                  = local.ado_vm_name
  location              = azurerm_resource_group.ado.location
  resource_group_name   = azurerm_resource_group.ado.name
  network_interface_ids = [azurerm_network_interface.ado.0.id]
  size               = var.ado_vm_size

  computer_name  = local.ado_vm_computer_name
  admin_username = var.ado_vm_username
  disable_password_authentication = length(var.ado_vm_password) > 0 ? false : true
  admin_password =  length(var.ado_vm_password) > 0 ? var.ado_vm_password : null

  dynamic "admin_ssh_key" {
    for_each = length(var.ado_vm_password) > 0 ? [] : [var.ado_vm_username]
    content {
      username   = var.ado_vm_username
      public_key = tls_private_key.ado["public_key_openssh"]
    }
  }

  # Cloud Init Config file
  custom_data = data.template_cloudinit_config.config.rendered

  os_disk {
    name              = local.ado_vm_os_name
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # if using a custom image specify source_image_id instead of source_image_reference
  # source_image_id = ""
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  
  identity {
    type = "SystemAssigned"
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.diag.primary_blob_endpoint
  }

  tags = merge(
    local.common_tags, 
    {
        display_name = "Azure DevOps VM"
    }
  )
}

# CREATE: Azure Linux VMSS as Azure DevOps Agent
# CREATE IF: ado_vmss_enabled is TRUE
resource "azurerm_linux_virtual_machine_scale_set" "ado" {
  count                 = var.ado_vmss_enabled ? 1 : 0

  name                  = local.ado_vmss_name
  location              = azurerm_resource_group.ado.location
  resource_group_name   = azurerm_resource_group.ado.name
  sku                   = var.ado_vm_size

  instances             = var.ado_vmss_instances
  upgrade_mode          = "Manual"
  overprovision = false 

  computer_name_prefix  = local.ado_vm_computer_name
  admin_username = var.ado_vm_username
  disable_password_authentication = length(var.ado_vm_password) > 0 ? false : true
  admin_password =  length(var.ado_vm_password) > 0 ? var.ado_vm_password : null

  dynamic "admin_ssh_key" {
    for_each = length(var.ado_vm_password) > 0 ? [] : [var.ado_vm_username]
    content {
      username   = var.ado_vm_username
      public_key = tls_private_key.ado["public_key_openssh"]
    }
  }

  # Cloud Init Config file
  custom_data = data.template_cloudinit_config.config.rendered

  # if using a custom image specify source_image_id instead of source_image_reference
  # source_image_id = ""
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    caching               = "ReadWrite"
    storage_account_type  = "Standard_LRS"
  }

  network_interface {
    name    = local.ado_nic_name
    primary = true

    ip_configuration {
      name      = "ipconfig1"
      primary   = true
      subnet_id = azurerm_subnet.ado.id
    }
  }

  identity {
    type = "SystemAssigned"
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.diag.primary_blob_endpoint
  }

  tags = merge(
    local.common_tags, 
    {
        display_name = "Azure DevOps VMSS"
    }
  )
}

# CREATE: Role Assignment to Subscriptions using Managed Identity of the Agent
resource "azurerm_role_assignment" "ado" {
  count             = length(var.ado_subscription_ids)
  
  scope                = "/subscriptions/${element(var.ado_subscription_ids, count.index)}"
  role_definition_name = "Contributor"
  principal_id         = var.ado_vmss_enabled ? azurerm_linux_virtual_machine_scale_set.ado.0.identity.0.principal_id : azurerm_linux_virtual_machine.ado.0.identity.0.principal_id
}