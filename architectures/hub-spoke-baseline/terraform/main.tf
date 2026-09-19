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

# VNet peering: hub <-> Italy North
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

# VNet peering: spoke A <-> Italy North
resource "azurerm_virtual_network_peering" "spoke_a_to_italy" {
  name                         = "SpokeA-to-Italy"
  resource_group_name          = azurerm_resource_group.this.name
  virtual_network_name         = azurerm_virtual_network.spoke_a.name
  remote_virtual_network_id    = azurerm_virtual_network.italy.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# VNet peering: spoke A <-> spoke B
resource "azurerm_virtual_network_peering" "spoke_a_to_spoke_b" {
  name                         = "SpokeA-to-SpokeB"
  resource_group_name          = azurerm_resource_group.this.name
  virtual_network_name         = azurerm_virtual_network.spoke_a.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke_b.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# VNet peering: spoke A <-> spoke C
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

# VNet peering: spoke B <-> Italy North
resource "azurerm_virtual_network_peering" "spoke_b_to_italy" {
  name                         = "SpokeB-to-Italy"
  resource_group_name          = azurerm_resource_group.this.name
  virtual_network_name         = azurerm_virtual_network.spoke_b.name
  remote_virtual_network_id    = azurerm_virtual_network.italy.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# VNet peering: spoke B <-> spoke A
resource "azurerm_virtual_network_peering" "spoke_b_to_spoke_a" {
  name                         = "SpokeB-to-SpokeA"
  resource_group_name          = azurerm_resource_group.this.name
  virtual_network_name         = azurerm_virtual_network.spoke_b.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke_a.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# VNet peering: spoke B <-> spoke C
resource "azurerm_virtual_network_peering" "spoke_b_to_spoke_c" {
  name                         = "SpokeB-to-SpokeC"
  resource_group_name          = azurerm_resource_group.this.name
  virtual_network_name         = azurerm_virtual_network.spoke_b.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke_c.id
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

# VNet peering: spoke C <-> Italy North
resource "azurerm_virtual_network_peering" "spoke_c_to_italy" {
  name                         = "SpokeC-to-Italy"
  resource_group_name          = azurerm_resource_group.this.name
  virtual_network_name         = azurerm_virtual_network.spoke_c.name
  remote_virtual_network_id    = azurerm_virtual_network.italy.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# VNet peering: spoke C <-> spoke A
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

# VNet peering: spoke C <-> spoke B
resource "azurerm_virtual_network_peering" "spoke_c_to_spoke_b" {
  name                         = "SpokeC-to-SpokeB"
  resource_group_name          = azurerm_resource_group.this.name
  virtual_network_name         = azurerm_virtual_network.spoke_c.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke_b.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# VNet peering: Italy North <-> hub
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

# VNet peering: Italy North <-> spoke A
resource "azurerm_virtual_network_peering" "italy_to_spoke_a" {
  name                         = "Italy-to-SpokeA"
  resource_group_name          = azurerm_resource_group.this.name
  virtual_network_name         = azurerm_virtual_network.italy.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke_a.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# VNet peering: Italy North <-> spoke B
resource "azurerm_virtual_network_peering" "italy_to_spoke_b" {
  name                         = "Italy-to-SpokeB"
  resource_group_name          = azurerm_resource_group.this.name
  virtual_network_name         = azurerm_virtual_network.italy.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke_b.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# VNet peering: Italy North <-> spoke C
resource "azurerm_virtual_network_peering" "italy_to_spoke_c" {
  name                         = "Italy-to-SpokeC"
  resource_group_name          = azurerm_resource_group.this.name
  virtual_network_name         = azurerm_virtual_network.italy.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke_c.id
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
