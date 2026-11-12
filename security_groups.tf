resource "azurerm_network_security_group" "access_server" {
  name                = "${var.name_prefix}-nsg"
  location            = var.location
  resource_group_name = local.resource_group_name
  tags                = local.tags

  security_rule {
    name                       = "AllowAdminUI"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "943"
    source_address_prefixes    = var.admin_ui_allowed_cidrs
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefixes    = var.https_allowed_cidrs
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowVPNPort"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "1194"
    source_address_prefixes    = var.vpn_allowed_cidrs
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowSSH"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.ssh_allowed_cidrs
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "access_server" {
  network_interface_id      = azurerm_network_interface.access_server.id
  network_security_group_id = azurerm_network_security_group.access_server.id
}
