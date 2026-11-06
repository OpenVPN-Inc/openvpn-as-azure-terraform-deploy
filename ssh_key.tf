# SSH key for the virtual machine. There are three ways to get it:
# 1. generate_ssh_key = true: Terraform generates a key pair
# 2. ssh_public_key: you give the public key content
# 3. existing_ssh_key_name: you use an SSH public key resource that already exists in Azure
resource "tls_private_key" "access_server" {
  count     = var.generate_ssh_key ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Store the generated public key in the resource group (Azure does not store the private key)
resource "azurerm_ssh_public_key" "access_server" {
  count               = var.generate_ssh_key ? 1 : 0
  name                = "${var.name_prefix}-sshkey"
  location            = var.location
  resource_group_name = local.resource_group_name
  public_key          = tls_private_key.access_server[0].public_key_openssh
  tags                = local.tags
}

data "azurerm_ssh_public_key" "existing" {
  count               = var.existing_ssh_key_name != null ? 1 : 0
  name                = var.existing_ssh_key_name
  resource_group_name = coalesce(var.existing_ssh_key_resource_group_name, local.resource_group_name)
}

locals {
  # Empty string when no key is set, so the precondition in vm.tf shows a clear error
  ssh_public_key = trimspace(try(coalesce(
    var.ssh_public_key,
    one(tls_private_key.access_server[*].public_key_openssh),
    one(data.azurerm_ssh_public_key.existing[*].public_key),
  ), ""))
}
