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

