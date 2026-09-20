terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}

############################################################
# Local values
############################################################

locals {
  name_suffix = "${var.environment}-${var.project_name}"
}

############################################################
# Resource group
############################################################

resource "azurerm_resource_group" "this" {
  name     = "rg-${local.name_suffix}"
  location = var.location

  tags = {
    environment = "learning"
    purpose     = "azure-troubleshooting"
    case        = "private-dns-troubleshooting"
  }
}

############################################################
# Network security groups
############################################################

resource "azurerm_network_security_group" "vm1" {
  name                = "nsg-vm-VM1-${local.name_suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_network_security_group" "vm2" {
  name                = "nsg-vm-VM2-${local.name_suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_network_security_group" "vm3" {
  name                = "nsg-vm-VM3-${local.name_suffix}"
  location            = var.secondary_location
  resource_group_name = azurerm_resource_group.this.name
}

############################################################
# SSH network security rules
############################################################

resource "azurerm_network_security_rule" "vm1_ssh" {
  name                        = "SSH"
  priority                    = 300
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = var.allowed_ssh_source
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.vm1.name
}

resource "azurerm_network_security_rule" "vm2_ssh" {
  name                        = "SSH"
  priority                    = 300
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = var.allowed_ssh_source
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.vm2.name
}

resource "azurerm_network_security_rule" "vm3_ssh" {
  name                        = "SSH"
  priority                    = 300
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = var.allowed_ssh_source
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.vm3.name
}

############################################################
# Public IP addresses
############################################################

resource "azurerm_public_ip" "vm1" {
  name                = "pip-vm1-${local.name_suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "vm2" {
  name                = "pip-vm2-${local.name_suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "vm3" {
  name                = "pip-vm3-${local.name_suffix}"
  location            = var.secondary_location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "firewall" {
  name                = "pip-afw-hub-${local.name_suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "hub_gateway" {
  name                = "pip-vpngw-hub-${local.name_suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "italy_gateway" {
  name                = "pip-vpngw-italy-${local.name_suffix}"
  location            = var.secondary_location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

############################################################
# Virtual networks
############################################################

resource "azurerm_virtual_network" "hub" {
  name                = "vnet-hub-${local.name_suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_virtual_network" "spoke_a" {
  name                = "vnet-spokeA-${local.name_suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.2.0.0/16"]
}

resource "azurerm_virtual_network" "spoke_b" {
  name                = "vnet-spokeB-${local.name_suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.3.0.0/16"]
}

resource "azurerm_virtual_network" "spoke_c" {
  name                = "vnet-spokeC-${local.name_suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.4.0.0/16"]
}

resource "azurerm_virtual_network" "italy" {
  name                = "vnet-ItalyNorth-${local.name_suffix}"
  location            = var.secondary_location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.10.0.0/16"]
}

############################################################
# Subnets
############################################################

resource "azurerm_subnet" "hub_workload" {
  name                 = "subnet1a"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.1.0.0/24"]
}

resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.1.1.0/26"]
}

resource "azurerm_subnet" "hub_gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.1.255.0/27"]
}

resource "azurerm_subnet" "spoke_a_1" {
  name                 = "subnetSpokeA1"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.spoke_a.name
  address_prefixes     = ["10.2.0.0/24"]
}

resource "azurerm_subnet" "spoke_a_2" {
  name                 = "subnetSpokeA2"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.spoke_a.name
  address_prefixes     = ["10.2.1.0/24"]
}

resource "azurerm_subnet" "spoke_b_1" {
  name                 = "subnetSpokeB1"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.spoke_b.name
  address_prefixes     = ["10.3.0.0/24"]
}

resource "azurerm_subnet" "spoke_b_2" {
  name                 = "subnetSpokeB2"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.spoke_b.name
  address_prefixes     = ["10.3.1.0/24"]
}

resource "azurerm_subnet" "spoke_c_1" {
  name                 = "subnetSpokeC1"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.spoke_c.name
  address_prefixes     = ["10.4.0.0/24"]
}

resource "azurerm_subnet" "italy_1" {
  name                 = "SubnetItaly1"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.italy.name
  address_prefixes     = ["10.10.0.0/24"]
}

resource "azurerm_subnet" "italy_gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.italy.name
  address_prefixes     = ["10.10.255.0/27"]
}

############################################################
# Vnet Peering
############################################################

# VNet peering: hub <-> spoke A
resource "azurerm_virtual_network_peering" "hub_to_spoke_a" {
  name                         = "Hub-to-SpokeA"
  resource_group_name          = azurerm_resource_group.this.name
  virtual_network_name         = azurerm_virtual_network.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke_a.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# VNet peering: hub <-> spoke B
resource "azurerm_virtual_network_peering" "hub_to_spoke_b" {
  name                         = "Hub-to-SpokeB"
  resource_group_name          = azurerm_resource_group.this.name
  virtual_network_name         = azurerm_virtual_network.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke_b.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# VNet peering: hub <-> spoke C
resource "azurerm_virtual_network_peering" "hub_to_spoke_c" {
  name                         = "Hub-to-SpokeC"
  resource_group_name          = azurerm_resource_group.this.name
  virtual_network_name         = azurerm_virtual_network.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke_c.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# VNet peering: spoke A <-> hub
resource "azurerm_virtual_network_peering" "spoke_a_to_hub" {
  name                         = "SpokeA-to-Hub"
  resource_group_name          = azurerm_resource_group.this.name
  virtual_network_name         = azurerm_virtual_network.spoke_a.name
  remote_virtual_network_id    = azurerm_virtual_network.hub.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}


# VNet peering: spoke B <-> hub
resource "azurerm_virtual_network_peering" "spoke_b_to_hub" {
  name                         = "SpokeB-to-Hub"
  resource_group_name          = azurerm_resource_group.this.name
  virtual_network_name         = azurerm_virtual_network.spoke_b.name
  remote_virtual_network_id    = azurerm_virtual_network.hub.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# VNet peering: spoke C <-> hub
resource "azurerm_virtual_network_peering" "spoke_c_to_hub" {
  name                         = "SpokeC-to-Hub"
  resource_group_name          = azurerm_resource_group.this.name
  virtual_network_name         = azurerm_virtual_network.spoke_c.name
  remote_virtual_network_id    = azurerm_virtual_network.hub.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

############################################################
# Network interfaces
############################################################

resource "azurerm_network_interface" "vm1" {
  name                = "nic-vm1-${local.name_suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.spoke_a_1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.2.0.4"
    public_ip_address_id          = azurerm_public_ip.vm1.id
  }
}

resource "azurerm_network_interface" "vm2" {
  name                = "nic-vm2-${local.name_suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.spoke_c_1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.4.0.4"
    public_ip_address_id          = azurerm_public_ip.vm2.id
  }
}

resource "azurerm_network_interface" "vm3" {
  name                = "nic-vm3-${local.name_suffix}"
  location            = var.secondary_location
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.italy_1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.10.0.4"
    public_ip_address_id          = azurerm_public_ip.vm3.id
  }
}

resource "azurerm_network_interface_security_group_association" "vm1" {
  network_interface_id      = azurerm_network_interface.vm1.id
  network_security_group_id = azurerm_network_security_group.vm1.id
}

resource "azurerm_network_interface_security_group_association" "vm2" {
  network_interface_id      = azurerm_network_interface.vm2.id
  network_security_group_id = azurerm_network_security_group.vm2.id
}

resource "azurerm_network_interface_security_group_association" "vm3" {
  network_interface_id      = azurerm_network_interface.vm3.id
  network_security_group_id = azurerm_network_security_group.vm3.id
}

############################################################
# Linux virtual machines
############################################################


resource "azurerm_linux_virtual_machine" "vm1" {
  name                = "vm-VM1-${local.name_suffix}"
  computer_name       = "vm1"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  size                = "Standard_B2ats_v2"

  admin_username                  = var.vm_admin_username
  admin_password                  = var.vm_admin_password
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.vm1.id
  ]

  os_disk {
    name                 = "osdisk-vm1-${local.name_suffix}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  custom_data = base64encode(<<-CLOUD_INIT
    #cloud-config
    package_update: true
    packages:
      - dnsutils
      - netcat-openbsd
      - traceroute
      - curl
    CLOUD_INIT
  )

  boot_diagnostics {}

  depends_on = [
    azurerm_network_interface_security_group_association.vm1
  ]
}

resource "azurerm_linux_virtual_machine" "vm2" {
  name                = "vm-VM2-${local.name_suffix}"
  computer_name       = "vm2"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  size                = "Standard_B2ats_v2"

  admin_username                  = var.vm_admin_username
  admin_password                  = var.vm_admin_password
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.vm2.id
  ]

  os_disk {
    name                 = "osdisk-vm2-${local.name_suffix}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  custom_data = base64encode(<<-CLOUD_INIT
    #cloud-config
    package_update: true
    packages:
      - dnsutils
      - netcat-openbsd
      - traceroute
      - curl
    CLOUD_INIT
  )

  boot_diagnostics {}

  depends_on = [
    azurerm_network_interface_security_group_association.vm2
  ]
}

resource "azurerm_linux_virtual_machine" "vm3" {
  name                = "vm-VM3-${local.name_suffix}"
  computer_name       = "vm3"
  location            = var.secondary_location
  resource_group_name = azurerm_resource_group.this.name
  size                = "Standard_F1als_v7"

  admin_username                  = var.vm_admin_username
  admin_password                  = var.vm_admin_password
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.vm3.id
  ]

  os_disk {
    name                 = "osdisk-vm3-${local.name_suffix}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  custom_data = base64encode(<<-CLOUD_INIT
    #cloud-config
    package_update: true
    packages:
      - dnsutils
      - netcat-openbsd
      - traceroute
      - curl
    CLOUD_INIT
  )

  boot_diagnostics {}

  depends_on = [
    azurerm_network_interface_security_group_association.vm3
  ]
}

############################################################
# Azure Firewall and policy
############################################################

resource "azurerm_firewall_policy" "hub" {
  name                = "afwp-hub-${local.name_suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Standard"
}


resource "azurerm_firewall" "hub" {
  name                = "afw-hub-${local.name_suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  firewall_policy_id  = azurerm_firewall_policy.hub.id

  ip_configuration {
    name                 = "AzureFirewallIpConfiguration"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }
}


############################################################
# Firewall network rules
############################################################

resource "azurerm_firewall_policy_rule_collection_group" "network" {
  name               = "DefaultNetworkRuleCollectionGroup"
  firewall_policy_id = azurerm_firewall_policy.hub.id
  priority           = 200

  network_rule_collection {
    name     = "allow-spoke-a-to-c-ssh"
    priority = 200
    action   = "Allow"

    rule {
      name                  = "vm1-to-vm2-ssh"
      protocols             = ["TCP"]
      source_addresses      = ["10.2.0.0/16"]
      destination_addresses = ["10.4.0.0/16"]
      destination_ports     = ["22"]
    }

    rule {
      name                  = "vm2-to-vm1-ssh"
      protocols             = ["TCP"]
      source_addresses      = ["10.4.0.0/16"]
      destination_addresses = ["10.2.0.0/16"]
      destination_ports     = ["22"]
    }
  }

  network_rule_collection {
    name     = "allow-vm-run-command"
    priority = 210
    action   = "Allow"

    rule {
      name                  = "run-command-spoke-a"
      protocols             = ["TCP"]
      source_addresses      = ["10.2.0.0/24"]
      destination_addresses = ["AzureCloud"]
      destination_ports     = ["443"]
    }

    rule {
      name                  = "run-command-spoke-c"
      protocols             = ["TCP"]
      source_addresses      = ["10.4.0.0/24"]
      destination_addresses = ["AzureCloud"]
      destination_ports     = ["443"]
    }
  }
}


############################################################
# Firewall application rules
############################################################

resource "azurerm_firewall_policy_rule_collection_group" "application" {
  name               = "DefaultApplicationRuleCollectionGroup"
  firewall_policy_id = azurerm_firewall_policy.hub.id
  priority           = 300

  application_rule_collection {
    name     = "allow-web"
    priority = 210
    action   = "Allow"

    rule {
      name              = "check-public-ip-spoke-c"
      source_addresses  = ["10.4.0.0/24"]
      destination_fqdns = ["api.ipify.org"]

      protocols {
        type = "Https"
        port = 443
      }
    }

    rule {
      name              = "check-public-ip-spoke-a"
      source_addresses  = ["10.2.0.0/24"]
      destination_fqdns = ["api.ipify.org"]

      protocols {
        type = "Https"
        port = 443
      }
    }
  }

  depends_on = [azurerm_firewall_policy_rule_collection_group.network]
}

############################################################
# Route tables
############################################################

resource "azurerm_route_table" "spoke_a" {
  name                          = "rt-spoke-a-fw"
  location                      = var.location
  resource_group_name           = azurerm_resource_group.this.name
  bgp_route_propagation_enabled = true

  route {
    name                   = "to-spoke-c"
    address_prefix         = "10.4.0.0/16"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.hub.ip_configuration[0].private_ip_address
  }

  route {
    name                   = "internet-via-fw"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.hub.ip_configuration[0].private_ip_address
  }
}

resource "azurerm_route_table" "spoke_c" {
  name                          = "rt-spoke-c-fw"
  location                      = var.location
  resource_group_name           = azurerm_resource_group.this.name
  bgp_route_propagation_enabled = true

  route {
    name                   = "to-spoke-a"
    address_prefix         = "10.2.0.0/16"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.hub.ip_configuration[0].private_ip_address
  }

  route {
    name                   = "internet-via-fw"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.hub.ip_configuration[0].private_ip_address
  }
}

############################################################
# Subnet route table associations
############################################################

resource "azurerm_subnet_route_table_association" "spoke_a" {
  subnet_id      = azurerm_subnet.spoke_a_1.id
  route_table_id = azurerm_route_table.spoke_a.id
}

resource "azurerm_subnet_route_table_association" "spoke_c" {
  subnet_id      = azurerm_subnet.spoke_c_1.id
  route_table_id = azurerm_route_table.spoke_c.id
}

############################################################
# VPN gateways
############################################################

resource "azurerm_virtual_network_gateway" "hub" {
  name                = "vpngw-hub-${local.name_suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name

  type          = "Vpn"
  vpn_type      = "RouteBased"
  sku           = "VpnGw1AZ"
  generation    = "Generation1"
  active_active = false
  bgp_enabled   = true

  bgp_settings {
    asn = 65010
  }

  ip_configuration {
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.hub_gateway.id
    subnet_id                     = azurerm_subnet.hub_gateway.id
  }
}

resource "azurerm_virtual_network_gateway" "italy" {
  name                = "vpngw-italy-${local.name_suffix}"
  location            = var.secondary_location
  resource_group_name = azurerm_resource_group.this.name

  type          = "Vpn"
  vpn_type      = "RouteBased"
  sku           = "VpnGw1AZ"
  generation    = "Generation1"
  active_active = false
  bgp_enabled   = true

  bgp_settings {
    asn = 65020
  }

  ip_configuration {
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.italy_gateway.id
    subnet_id                     = azurerm_subnet.italy_gateway.id
  }
}

############################################################
# VNet-to-VNet VPN connections
############################################################

resource "azurerm_virtual_network_gateway_connection" "hub_to_italy" {
  name                = "conn-hub-to-italy"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name

  type                            = "Vnet2Vnet"
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.hub.id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.italy.id

  shared_key                         = var.vpn_shared_key
  bgp_enabled                        = true
  dpd_timeout_seconds                = 45
  connection_mode                    = "Default"
  use_policy_based_traffic_selectors = false
}

resource "azurerm_virtual_network_gateway_connection" "italy_to_hub" {
  name                = "conn-italy-to-hub"
  location            = var.secondary_location
  resource_group_name = azurerm_resource_group.this.name

  type                            = "Vnet2Vnet"
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.italy.id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.hub.id

  shared_key                         = var.vpn_shared_key
  bgp_enabled                        = true
  dpd_timeout_seconds                = 45
  connection_mode                    = "Default"
  use_policy_based_traffic_selectors = false
}
