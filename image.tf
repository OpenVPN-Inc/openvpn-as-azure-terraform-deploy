# Image for the virtual machine: Ubuntu 26.04 LTS AMD64 (Gen2) from Canonical
locals {
  ubuntu26_image = {
    publisher = "Canonical"
    offer     = "ubuntu-26_04-lts"
    sku       = "server"
    version   = "latest"
  }
}
