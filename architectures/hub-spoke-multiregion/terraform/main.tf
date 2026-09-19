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
# Resource group
############################################################

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    environment = "learning"
    purpose     = "azure-troubleshooting"
    case        = "hub-spoke-missing-peerings"
  }
}

############################################################
# Network security groups
############################################################

resource "azurerm_network_security_group" "vm1" {
  name                = "vm-VM1-dev-troubleshooting-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_network_security_group" "vm2" {
  name                = "vm-VM2-dev-troubleshooting-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_network_security_group" "vm3" {
  name                = "vm-VM3-dev-troubleshooting-nsg"
  location            = var.secondary_location
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_network_security_rule" "vm1_rdp" {
  name                        = "RDP"
  priority                    = 300
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.vm1.name
}

resource "azurerm_network_security_rule" "vm2_rdp" {
  name                        = "RDP"
  priority                    = 300
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.vm2.name
}

resource "azurerm_network_security_rule" "vm3_rdp" {
  name                        = "RDP"
  priority                    = 300
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.vm3.name
}

############################################################
# Public IP addresses
############################################################

resource "azurerm_public_ip" "vpn_gateway" {
  count = var.create_vpn_gateway ? 1 : 0

  name                = "pip-vpngw-dev-troubleshooting"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
}

resource "azurerm_public_ip" "vm1" {
  name                = "vm-VM1-dev-troubleshooting-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "vm2" {
  name                = "vm-VM2-dev-troubleshooting-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "vm3" {
  name                = "vm-VM3-dev-troubleshooting-ip"
  location            = var.secondary_location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

############################################################
# Virtual networks
############################################################

resource "azurerm_virtual_network" "hub" {
  name                = "vnet-hub-dev-troubleshooting"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_virtual_network" "spoke_a" {
  name                = "vnet-spokeA-dev-troubleshooting"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.2.0.0/16"]
}

resource "azurerm_virtual_network" "spoke_b" {
  name                = "vnet-spokeB-dev-troubleshooting"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.3.0.0/16"]
}

resource "azurerm_virtual_network" "spoke_c" {
  name                = "vnet-spokeC-dev-troubleshooting"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.4.0.0/16"]
}

resource "azurerm_virtual_network" "italy" {
  name                = "vnet-ItalyNorth-dev-troubleshooting"
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

resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.1.1.0/24"]
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

############################################################
# Vnet Peering
############################################################

# Global VNet peering: Spain hub <-> Italy North
resource "azurerm_virtual_network_peering" "hub_to_italy" {
  name                         = "SpainHub-to-Italy"
  resource_group_name          = azurerm_resource_group.this.name
  virtual_network_name         = azurerm_virtual_network.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.italy.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "italy_to_hub" {
  name                         = "Italy-to-SpainHub"
  resource_group_name          = azurerm_resource_group.this.name
  virtual_network_name         = azurerm_virtual_network.italy.name
  remote_virtual_network_id    = azurerm_virtual_network.hub.id
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

# VNet peering: spoke a <-> spoke C
resource "azurerm_virtual_network_peering" "spoke_a_to_spoke_c" {
  name                         = "SpokeA-to-SpokeC"
  resource_group_name          = azurerm_resource_group.this.name
  virtual_network_name         = azurerm_virtual_network.spoke_a.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke_c.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "spoke_c_to_spoke_a" {
  name                         = "SpokeC-to-SpokeA"
  resource_group_name          = azurerm_resource_group.this.name
  virtual_network_name         = azurerm_virtual_network.spoke_c.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke_a.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# The hub-to-spoke peerings are intentionally missing.
# This is the failure that must be investigated in this troubleshooting case.

############################################################
# VPN gateway
############################################################

resource "azurerm_virtual_network_gateway" "this" {
  count = var.create_vpn_gateway ? 1 : 0

  name                = "vntgw-dev-troubleshooting"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name

  type          = "Vpn"
  vpn_type      = "RouteBased"
  active_active = false
  bgp_enabled   = false
  generation    = "Generation2"
  sku           = "VpnGw2AZ"

  ip_configuration {
    name = "default"

    public_ip_address_id = azurerm_public_ip.vpn_gateway[0].id

    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway.id
  }
}

############################################################
# Network interfaces
############################################################

resource "azurerm_network_interface" "vm1" {
  name                           = "nic-vm1-dev-troubleshooting"
  location                       = var.location
  resource_group_name            = azurerm_resource_group.this.name
  accelerated_networking_enabled = true

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.spoke_a_1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm1.id
  }
}

resource "azurerm_network_interface" "vm2" {
  name                = "nic-vm2-dev-troubleshooting"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.spoke_c_1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm2.id
  }
}

resource "azurerm_network_interface" "vm3" {
  name                = "nic-vm3-dev-troubleshooting"
  location            = var.secondary_location
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.italy_1.id
    private_ip_address_allocation = "Dynamic"
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
# Windows virtual machines
############################################################

resource "azurerm_windows_virtual_machine" "vm1" {
  name                = "vm-VM1-dev-troubleshooting"
  computer_name       = "vm-VM1-dev-trou"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  size                = "Standard_B2ts_v2"

  admin_username = var.vm_admin_username
  admin_password = var.vm_admin_password

  network_interface_ids = [
    azurerm_network_interface.vm1.id
  ]

  os_disk {
    name                 = "osdisk-vm1-dev-troubleshooting"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
    disk_size_gb         = 127
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2025-datacenter-g2"
    version   = "latest"
  }

  boot_diagnostics {}

  depends_on = [
    azurerm_network_interface_security_group_association.vm1
  ]
}

resource "azurerm_windows_virtual_machine" "vm2" {
  name                = "vm-VM2-dev-troubleshooting"
  computer_name       = "vm-VM2-dev-trou"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  size                = "Standard_B2ats_v2"

  admin_username = var.vm_admin_username
  admin_password = var.vm_admin_password

  network_interface_ids = [
    azurerm_network_interface.vm2.id
  ]

  os_disk {
    name                 = "osdisk-vm2-dev-troubleshooting"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
    disk_size_gb         = 127
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2025-datacenter-g2"
    version   = "latest"
  }
}

resource "azurerm_windows_virtual_machine" "vm3" {
  name                = "vm-VM3-dev-troubleshooting"
  computer_name       = "vm-VM3-dev-trou"
  location            = var.secondary_location
  resource_group_name = azurerm_resource_group.this.name
  size                = "Standard_D2als_v7"

  admin_username = var.vm_admin_username
  admin_password = var.vm_admin_password

  network_interface_ids = [
    azurerm_network_interface.vm3.id
  ]

  os_disk {
    name                 = "osdisk-vm3-dev-troubleshooting"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
    disk_size_gb         = 127
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2025-datacenter-g2"
    version   = "latest"
  }
}
