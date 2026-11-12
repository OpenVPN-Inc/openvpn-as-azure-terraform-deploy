# Static public IP for the Access Server (Standard SKU is always static)
resource "azurerm_public_ip" "access_server" {
  count               = var.assign_public_ip ? 1 : 0
  name                = "${var.name_prefix}-pip"
  location            = var.location
  resource_group_name = local.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}
