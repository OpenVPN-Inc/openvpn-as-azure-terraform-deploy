resource "azurerm_network_interface" "access_server" {
  name                  = "${var.name_prefix}-nic"
  location              = var.location
  resource_group_name   = local.resource_group_name
  ip_forwarding_enabled = var.enable_ip_forwarding
  tags                  = local.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = local.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.assign_public_ip ? azurerm_public_ip.access_server[0].id : null
  }
}

resource "azurerm_linux_virtual_machine" "access_server" {
  name                            = "${var.name_prefix}-vm"
  location                        = var.location
  resource_group_name             = local.resource_group_name
  size                            = var.vm_size
  admin_username                  = var.vm_admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.access_server.id]
  user_data                       = base64encode(local.user_data)
  tags                            = local.tags

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = local.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_type
  }

  source_image_reference {
    publisher = local.ubuntu26_image.publisher
    offer     = local.ubuntu26_image.offer
    sku       = local.ubuntu26_image.sku
    version   = local.ubuntu26_image.version
  }

  # Managed boot diagnostics (no storage account needed)
  boot_diagnostics {}

  # Attach the network security group before the first boot, so Let's Encrypt can be reached
  depends_on = [azurerm_network_interface_security_group_association.access_server]

  lifecycle {
    precondition {
      condition     = !var.enable_lets_encrypt || var.assign_public_ip
      error_message = "enable_lets_encrypt requires assign_public_ip = true."
    }

    precondition {
      condition     = length([for v in [var.generate_ssh_key ? true : null, var.ssh_public_key, var.existing_ssh_key_name] : v if v != null]) == 1
      error_message = "Set exactly one of generate_ssh_key = true, ssh_public_key, or existing_ssh_key_name."
    }
  }
}
