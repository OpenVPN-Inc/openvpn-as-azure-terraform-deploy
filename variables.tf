variable "subscription_id" {
  description = "Azure subscription ID. If null, the ARM_SUBSCRIPTION_ID environment variable is used"
  type        = string
  default     = null
}

variable "location" {
  description = "Azure region to deploy the resources in"
  type        = string
  default     = "eastus"
}

variable "name_prefix" {
  description = "Prefix for the resource names, which follow the Azure naming convention (for example <prefix>-rg, <prefix>-vnet, <prefix>-vm). Use a different prefix to deploy more than one Access Server"
  type        = string
  default     = "openvpn-as"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,39}$", var.name_prefix))
    error_message = "name_prefix must use lowercase letters, digits, and hyphens only, start with a letter or digit, and be at most 40 characters."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group for the Access Server resources. If null, <name_prefix>-rg is used"
  type        = string
  default     = null
}

variable "create_resource_group" {
  description = "Whether to create the resource group. Set to false to use an existing resource group with the name above"
  type        = bool
  default     = true
}

variable "subnet_id" {
  description = "ID of your existing Subnet. If null, a new virtual network and subnet are created"
  type        = string
  default     = null
}

variable "vnet_address_space" {
  description = "Address space of the new virtual network (used only when subnet_id is null)"
  type        = string
  default     = "10.10.0.0/16"
}

variable "subnet_address_prefix" {
  description = "Address prefix of the new subnet (used only when subnet_id is null)"
  type        = string
  default     = "10.10.1.0/24"
}

variable "vm_size" {
  description = "Access Server virtual machine size"
  type        = string
  default     = "Standard_D2als_v7"
}

variable "os_disk_type" {
  description = "Storage account type of the OS disk"
  type        = string
  default     = "Premium_LRS"

  validation {
    condition     = contains(["Standard_LRS", "StandardSSD_LRS", "Premium_LRS"], var.os_disk_type)
    error_message = "os_disk_type must be Standard_LRS, StandardSSD_LRS, or Premium_LRS."
  }
}

variable "vm_admin_username" {
  description = "Operating system user for SSH access to the virtual machine (SSH key only, no password)"
  type        = string
  default     = "azureuser"

  validation {
    condition     = !contains(["admin", "administrator", "root", "guest", "test", "user", "ubuntu"], lower(var.vm_admin_username)) && can(regex("^[a-z_][a-z0-9_-]{0,31}$", var.vm_admin_username))
    error_message = "vm_admin_username must be a valid Linux user name and must not be a name that Azure reserves (admin, administrator, root, guest, test, user, ubuntu)."
  }
}

variable "generate_ssh_key" {
  description = "Generate an SSH key pair with Terraform. The public key is stored in the resource group. The private key is in the sensitive output ssh_private_key and in the Terraform state. Set exactly one of generate_ssh_key, ssh_public_key, or existing_ssh_key_name"
  type        = bool
  default     = false
}

variable "ssh_public_key" {
  description = "SSH public key content (for example the content of ~/.ssh/id_rsa.pub) for access to the virtual machine. Set exactly one of generate_ssh_key, ssh_public_key, or existing_ssh_key_name"
  type        = string
  default     = null

  validation {
    condition     = var.ssh_public_key == null || can(regex("^(ssh-rsa|ssh-ed25519|ecdsa-sha2-nistp[0-9]+) ", var.ssh_public_key))
    error_message = "ssh_public_key must be a public key in OpenSSH format (ssh-rsa, ssh-ed25519, or ecdsa-sha2-...)."
  }
}

variable "existing_ssh_key_name" {
  description = "Name of an SSH public key resource that already exists in Azure. Set exactly one of generate_ssh_key, ssh_public_key, or existing_ssh_key_name"
  type        = string
  default     = null
}

variable "existing_ssh_key_resource_group_name" {
  description = "Resource group of the existing SSH public key. If null, the resource group of this deployment is used"
  type        = string
  default     = null
}

variable "ssh_allowed_cidrs" {
  description = "List of CIDR blocks allowed to connect over SSH (port 22). Restrict this to trusted IP addresses, for example [\"11.22.33.44/32\"]"
  type        = list(string)

  validation {
    condition     = length(var.ssh_allowed_cidrs) > 0 && alltrue([for c in var.ssh_allowed_cidrs : can(cidrhost(c, 0))])
    error_message = "ssh_allowed_cidrs must contain at least one valid CIDR block, for example 11.22.33.44/32."
  }
}

variable "admin_ui_allowed_cidrs" {
  description = "List of CIDR blocks allowed to reach the Web UI (port 943). The default is open to the internet. We recommend you restrict it to trusted IP addresses"
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = length(var.admin_ui_allowed_cidrs) > 0 && alltrue([for c in var.admin_ui_allowed_cidrs : can(cidrhost(c, 0))])
    error_message = "admin_ui_allowed_cidrs must contain at least one valid CIDR block."
  }
}

variable "https_allowed_cidrs" {
  description = "List of CIDR blocks allowed to reach the Client Web UI and OpenVPN over TCP (port 443). The default is open to the internet. If you restrict it, Let's Encrypt validation may fail"
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = length(var.https_allowed_cidrs) > 0 && alltrue([for c in var.https_allowed_cidrs : can(cidrhost(c, 0))])
    error_message = "https_allowed_cidrs must contain at least one valid CIDR block."
  }
}

variable "vpn_allowed_cidrs" {
  description = "List of CIDR blocks allowed to connect to the VPN over UDP (port 1194). The default is open to the internet, so VPN clients can connect from anywhere"
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = length(var.vpn_allowed_cidrs) > 0 && alltrue([for c in var.vpn_allowed_cidrs : can(cidrhost(c, 0))])
    error_message = "vpn_allowed_cidrs must contain at least one valid CIDR block."
  }
}

variable "admin_username" {
  description = "The OpenVPN Access Server admin username (lowercase letters, digits, underscore, hyphen)"
  type        = string
  default     = "openvpn"

  validation {
    condition     = can(regex("^[a-z_][a-z0-9_-]{0,31}$", var.admin_username))
    error_message = "admin_username must start with a lowercase letter or underscore and use only lowercase letters, digits, underscore, and hyphen (max 32 characters)."
  }
}

variable "admin_password" {
  description = "The OpenVPN Access Server admin password (at least 12 characters: letters, digits, and ! @ # % ^ * _ + = . , : -). If null, a random password is generated"
  type        = string
  default     = null
  sensitive   = true

  validation {
    condition     = var.admin_password == null || can(regex("^[A-Za-z0-9!@#%^*_+=.,:-]{12,}$", var.admin_password))
    error_message = "admin_password must be at least 12 characters and use only letters, digits, and these symbols: ! @ # % ^ * _ + = . , : -"
  }
}

variable "activation_key" {
  description = "OpenVPN Access Server activation key (subscription license). If null or empty, the license line is not added and Access Server starts without a key"
  type        = string
  default     = null
  sensitive   = true

  validation {
    condition     = var.activation_key == null || can(regex("^[A-Za-z0-9_.-]*$", var.activation_key))
    error_message = "activation_key must contain only letters, digits, and the symbols _ . -"
  }
}

variable "as_version" {
  description = "OpenVPN Access Server version to install"
  type        = string
  default     = "3.2.4"
}

variable "assign_public_ip" {
  description = "Whether to create a static Standard public IP for the Access Server (required for Let's Encrypt and for access from the internet)"
  type        = bool
  default     = true
}

variable "enable_lets_encrypt" {
  description = "Whether to automatically request and install a Let's Encrypt TLS certificate for the Access Server once it boots (requires assign_public_ip)"
  type        = bool
  default     = true
}

variable "enable_ip_forwarding" {
  description = "Whether to enable IP forwarding on the network interface (needed only when VPN clients must reach other private networks through the Access Server)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
