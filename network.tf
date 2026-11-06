# Resource group (created, or looked up when it already exists)
resource "azurerm_resource_group" "access_server" {
  count    = var.create_resource_group ? 1 : 0
  name     = local.rg_name
  location = var.location
  tags     = local.tags
}

data "azurerm_resource_group" "existing" {
  count = var.create_resource_group ? 0 : 1
  name  = local.rg_name
}

# Virtual network and subnet, created only when no existing subnet is given
resource "azurerm_virtual_network" "access_server" {
  count               = local.create_network ? 1 : 0
  name                = "${var.name_prefix}-vnet"
  location            = var.location
  resource_group_name = local.resource_group_name
  address_space       = [var.vnet_address_space]
  tags                = local.tags
}

resource "azurerm_subnet" "access_server" {
  count                = local.create_network ? 1 : 0
  name                 = "${var.name_prefix}-snet"
  resource_group_name  = local.resource_group_name
  virtual_network_name = azurerm_virtual_network.access_server[0].name
  address_prefixes     = [var.subnet_address_prefix]
}

locals {
  create_network      = var.subnet_id == null
  rg_name             = coalesce(var.resource_group_name, "${var.name_prefix}-rg")
  resource_group_name = var.create_resource_group ? azurerm_resource_group.access_server[0].name : data.azurerm_resource_group.existing[0].name
  subnet_id           = local.create_network ? azurerm_subnet.access_server[0].id : var.subnet_id
  tags                = merge({ Name = "OpenVPNAccessServer_Terraform" }, var.tags)
}
