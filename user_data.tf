resource "random_password" "admin" {
  count   = var.admin_password == null ? 1 : 0
  length  = 16
  special = false
}

locals {
  admin_password = var.admin_password != null ? var.admin_password : random_password.admin[0].result

  # The public IP is created before the VM, so its address is known here
  public_ip = var.assign_public_ip ? azurerm_public_ip.access_server[0].ip_address : ""

  # Sent to the VM as Azure user_data (IMDS), like the official OpenVPN ARM template.
  # The lines after "exit 0" are not run. Access Server reads admin_user and admin_pw from them
  user_data = <<-EOF
    #!/bin/bash
    echo unattended-upgrades unattended-upgrades/enable_auto_updates boolean true | debconf-set-selections
    dpkg-reconfigure -f noninteractive unattended-upgrades
    OVPN_INIT_MANUAL=true bash <(curl -fsS https://packages.openvpn.net/as/install.sh) --as-version=${var.as_version} --yes
    ovpn-init --azure --batch --force
    apt-mark hold openvpn-as
    . /usr/local/openvpn_as/etc/VERSION
    echo "OpenVPN Access Server Appliance $AS_VERSION \n \l" > /etc/issue
    cat > /etc/update-motd.d/00-header <<HEADER
    #!/bin/sh
    echo "Welcome to OpenVPN Access Server Appliance $AS_VERSION"
    HEADER
    %{if var.enable_lets_encrypt}
    PUBLIC_IP=${local.public_ip}
    for i in $(seq 1 90); do sacli status 2>/dev/null | grep -q '"api": "on"' && break; sleep 2; done
    sacli --key "acme.ip_addresses.0" --value "$PUBLIC_IP" ConfigPut
    sacli --key "acme.cert_profile" --value "shortlived" ConfigPut
    sacli start
    echo y | sacli AcmeRegisterAccount
    sacli AcmeRequestCertificate
    %{endif}
    exit 0
    %{if var.activation_key != null && var.activation_key != ""}license=${var.activation_key}
    %{endif}admin_user=${var.admin_username}
    admin_pw=${local.admin_password}
  EOF
}
