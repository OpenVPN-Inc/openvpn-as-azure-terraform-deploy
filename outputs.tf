locals {
  access_server_address = var.assign_public_ip ? azurerm_public_ip.access_server[0].ip_address : azurerm_network_interface.access_server.private_ip_address
}

output "admin_ui_url" {
  description = "OpenVPN Access Server Admin Web UI URL"
  value       = "https://${local.access_server_address}:943/admin"
}

output "client_ui_url" {
  description = "OpenVPN Access Server Client Web UI URL"
  value       = "https://${local.access_server_address}:943"
}

output "public_ip_address" {
  description = "Public IP address of the Access Server (null when assign_public_ip is false)"
  value       = var.assign_public_ip ? azurerm_public_ip.access_server[0].ip_address : null
}

output "private_ip_address" {
  description = "Private IP address of the Access Server"
  value       = azurerm_network_interface.access_server.private_ip_address
}

output "vm_id" {
  description = "Resource ID of the Access Server virtual machine"
  value       = azurerm_linux_virtual_machine.access_server.id
}

output "ssh_command" {
  description = "Command to connect to the virtual machine over SSH"
  value       = "ssh ${var.vm_admin_username}@${local.access_server_address}"
}

output "ssh_private_key" {
  description = "Generated SSH private key (null unless generate_ssh_key is true). Save it with: terraform output -raw ssh_private_key > key.pem"
  sensitive   = true
  value       = var.generate_ssh_key ? tls_private_key.access_server[0].private_key_openssh : null
}

output "openvpnas_user" {
  description = "OpenVPN Access Server Admin Credentials"
  sensitive   = true
  value = {
    admin_account  = var.admin_username
    admin_password = local.admin_password
  }
}
