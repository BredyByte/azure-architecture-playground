variable "subscription_id" {
  description = "Azure subscription where the troubleshooting lab will be deployed."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group dedicated to this troubleshooting case."
  type        = string
  default     = "rg-dev-troubleshooting-hub-spoke"
}

variable "location" {
  description = "Primary Azure region."
  type        = string
  default     = "Spain Central"
}

variable "secondary_location" {
  description = "Secondary Azure region used by the remote VNet."
  type        = string
  default     = "Italy North"
}

variable "vm_admin_username" {
  description = "Shared administrator username for both Windows VMs."
  type        = string
  default     = "azureuser"
}

variable "vm_admin_password" {
  description = "Shared administrator password for both Windows VMs."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.vm_admin_password) >= 12
    error_message = "The VM administrator password must contain at least 12 characters."
  }
}

variable "create_vpn_gateway" {
  description = "Controls whether the VPN Gateway and its public IP are created."
  type        = bool
  default     = false
}
