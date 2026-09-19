variable "subscription_id" {
  description = "Azure subscription ID."
  type        = string
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name used in Azure resource names."
  type        = string
  default     = "dns-troubleshooting"
}

variable "location" {
  description = "Primary Azure region."
  type        = string
  default     = "spaincentral"
}

variable "secondary_location" {
  description = "Secondary Azure region."
  type        = string
  default     = "italynorth"
}

variable "vm_admin_username" {
  description = "Administrator username used by all Linux virtual machines."
  type        = string
  default     = "azureadmin"
}

variable "vm_admin_password" {
  description = "Administrator password used by all Linux virtual machines."
  type        = string
  sensitive   = true
}

variable "allowed_ssh_source" {
  description = "Source address allowed to connect using SSH."
  type        = string
  default     = "*"
}
