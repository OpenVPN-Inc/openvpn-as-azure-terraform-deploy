
# OpenVPN Access Server Deployment on Azure Cloud Using Terraform

This Terraform project automates the deployment of an **OpenVPN Access Server**. The OpenVPN Access Server is installed on a generic Linux virtual machine (Ubuntu 26.04 LTS) using a custom script sent as Azure **user data** and executed via **cloud-init** during the provisioning process.

## Prerequisites

- Azure Cloud account with permissions to manage resource groups, virtual networks, and virtual machines.
- **Azure CLI** installed and logged in (`az login`), and **Terraform** 1.5 or later.
- An SSH key. You can use your own public key, use a key that already exists in Azure, or let Terraform generate one.
- The Azure subscription ID, set in `subscription_id` or in the `ARM_SUBSCRIPTION_ID` environment variable.

## Quick Start

```bash
cp terraform.tfvars.example terraform.tfvars   # edit the values
terraform init
terraform plan
terraform apply
terraform output -json openvpnas_credentials          # show the admin credentials
```

To remove all resources, run `terraform destroy`.

## Input Variables

The key variables include:

- `subscription_id`: Azure subscription ID (`null`, uses `ARM_SUBSCRIPTION_ID`).
- `location`: The region where resources will be deployed (`eastus`).
- `vm_size`: Virtual machine size (`Standard_D2als_v7`).
- `name_prefix`: Base name for all resources. The resource type is added as a suffix, for example `openvpn-as-vm` (`openvpn-as`).
- `resource_group_name`: Resource group name. If `null`, `<name_prefix>-rg` is used (`null`).
- `create_resource_group`: Create the resource group, or use an existing one (`true`).
- `subnet_id`: ID of your existing Subnet. If `null`, a new virtual network and subnet are created (`null`).
- `generate_ssh_key`: Generate an SSH key pair with Terraform (`false`).
- `ssh_public_key`: The content of your own SSH public key (`null`).
- `existing_ssh_key_name`: Name of an SSH public key that already exists in Azure (`null`). Use `existing_ssh_key_resource_group_name` if it is in another resource group.
- `vm_admin_username`: Operating system user for SSH (`azureuser`).
- `ssh_allowed_cidrs`: CIDR blocks allowed to use SSH, for example `["203.0.113.10/32"]` (required, no default).
- `admin_ui_allowed_cidrs`: CIDR blocks allowed to reach the Web UI on port 943 (`["0.0.0.0/0"]`).
- `https_allowed_cidrs`: CIDR blocks allowed to reach TCP port 443 (`["0.0.0.0/0"]`).
- `vpn_allowed_cidrs`: CIDR blocks allowed to connect to the VPN on UDP port 1194 (`["0.0.0.0/0"]`).
- `admin_username`: The OpenVPN Access Server admin username (`openvpn`).
- `admin_password`: The OpenVPN Access Server admin password. If `null`, a random password is generated (`null`).
- `activation_key`: The OpenVPN Access Server activation key. If `null` or empty, no license line is added (`null`).
- `as_version`: OpenVPN Access Server version to install (`3.2.4`).
- `assign_public_ip`: Create a static Standard public IP (`true`).
- `enable_lets_encrypt`: Automatically request a Let's Encrypt TLS certificate for the public IP address on boot (no domain name needed). Needs `assign_public_ip` (`true`).
- `enable_ip_forwarding`: Enable IP forwarding on the network interface for routing to private networks (`false`).
- `tags`: Extra tags for all resources (`{}`).

Set exactly one of `generate_ssh_key`, `ssh_public_key`, and `existing_ssh_key_name`. The `admin_password` needs at least 12 characters from letters, digits and `! @ # % ^ * _ + = . , : -`. The `admin_password` and `activation_key` values are sensitive.

## SSH Key

- **Generate:** with `generate_ssh_key = true`, Terraform creates an RSA key pair and stores the public key in the resource group. The private key is a sensitive output. Save it with `terraform output -raw ssh_private_key > key.pem`.
- **Your own key:** set `ssh_public_key` to the content of your public key, for example `~/.ssh/id_rsa.pub`.
- **Existing Azure key:** set `existing_ssh_key_name` to the name of an SSH public key in Azure. You need the matching private key to log in.

## Network Access

| Port | Protocol | Purpose | Source |
|------|----------|---------|--------|
| 22 | TCP | SSH | `ssh_allowed_cidrs` |
| 943 | TCP | Admin and Client Web UI | `admin_ui_allowed_cidrs` (default: any) |
| 443 | TCP | HTTPS and OpenVPN over TCP | `https_allowed_cidrs` (default: any) |
| 1194 | UDP | OpenVPN tunnel | `vpn_allowed_cidrs` (default: any) |

We recommend you set `admin_ui_allowed_cidrs` to trusted IP addresses if your users do not need the Web UI from the internet. If you restrict `https_allowed_cidrs`, Let's Encrypt validation may fail.

## Project Structure

```bash
├── README.md                   # Project documentation
├── image.tf                    # Base image configuration
├── network.tf                  # Resource group, virtual network, and subnet
├── outputs.tf                  # Outputs from Admin credentials, Admin UI, and Client UI URLs
├── provider.tf                 # Provider info and versions
├── public_ip.tf                # Static public IP
├── security_groups.tf          # Network Security Group setup
├── ssh_key.tf                  # SSH key setup (generate, own key, or existing Azure key)
├── terraform.tfvars.example    # Example values
├── user_data.tf                # User Data (cloud-init) and admin password setup
├── variables.tf                # Input variables
├── vm.tf                       # Network interface and virtual machine
```

## Contact support

You can contact the support team for OpenVPN Access Server here:

https://support.openvpn.com/hc/en-us/categories/360006075631-Access-Server
