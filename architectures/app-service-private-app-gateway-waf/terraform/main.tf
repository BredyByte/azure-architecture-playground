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

# #############################################################*
# Local values
# #############################################################*

locals {
  name_suffix = "${var.environment}-${var.project_name}"

  tags = {
    environment = "learning"
    purpose     = "azure-troubleshooting"
    case        = "app-service-gateway-troubleshooting"
  }

  appgw_frontend_ip_configuration_name = "appgw-frontend-ip"
  appgw_frontend_port_name             = "appgw-frontend-port-http"
  appgw_backend_pool_name              = "appgw-backend-appservice"
  appgw_backend_http_settings_name     = "appgw-backend-https-settings"
  appgw_http_listener_name             = "appgw-http-listener"
  appgw_request_routing_rule_name      = "appgw-basic-routing-rule"
  appgw_probe_name                     = "appservice-health-probe"
}

# #############################################################*
# Resource group
# #############################################################*

resource "azurerm_resource_group" "this" {
  name     = "rg-${local.name_suffix}"
  location = var.location
  tags     = local.tags
}

# #############################################################*
# Network security groups
# #############################################################*

resource "azurerm_network_security_group" "appgw" {
  name                = "nsg-snet-appgw-${local.name_suffix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags

  security_rule {
    name                       = "Allow-HTTP-Internet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-GatewayManager"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "65200-65535"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "private_endpoints" {
  name                = "nsg-snet-private-endpoints-${local.name_suffix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

# #############################################################*
# Public IP address
# #############################################################*

resource "azurerm_public_ip" "appgw" {
  name                = "pip-appgw-${local.name_suffix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

# #############################################################*
# Virtual network
# #############################################################*

resource "azurerm_virtual_network" "appgw" {
  name                = "vnet-${local.name_suffix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.20.0.0/16"]
  tags                = local.tags
}

# #############################################################*
# Subnets
# #############################################################*

resource "azurerm_subnet" "appgw" {
  name                 = "snet-application-gateway"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.appgw.name
  address_prefixes     = ["10.20.1.0/24"]
}

resource "azurerm_subnet" "private_endpoints" {
  name                 = "snet-private-endpoints"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.appgw.name
  address_prefixes     = ["10.20.2.0/24"]

  private_endpoint_network_policies = "NetworkSecurityGroupEnabled"
}

resource "azurerm_subnet_network_security_group_association" "appgw" {
  subnet_id                 = azurerm_subnet.appgw.id
  network_security_group_id = azurerm_network_security_group.appgw.id
}

resource "azurerm_subnet_network_security_group_association" "private_endpoints" {
  subnet_id                 = azurerm_subnet.private_endpoints.id
  network_security_group_id = azurerm_network_security_group.private_endpoints.id
}

# #############################################################*
# Private DNS zone
# #############################################################*

resource "azurerm_private_dns_zone" "appservice" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

# #############################################################*
# Private DNS zone link
# #############################################################*

resource "azurerm_private_dns_zone_virtual_network_link" "appgw" {
  name                  = "link-appgw-vnet"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.appservice.name
  virtual_network_id    = azurerm_virtual_network.appgw.id
  registration_enabled  = false

  tags = local.tags
}

# No manual A record is required. The private_dns_zone_group in the
# Private Endpoint creates and maintains the App Service DNS record.

# #############################################################*
# Linux App Service plan
# #############################################################*

resource "azurerm_service_plan" "this" {
  name                = "asp-${local.name_suffix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  os_type             = "Linux"
  sku_name            = "B1"
  tags                = local.tags
}

# #############################################################*
# Linux Web App
# #############################################################*

resource "azurerm_linux_web_app" "this" {
  name                = "app-${local.name_suffix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  service_plan_id     = azurerm_service_plan.this.id

  https_only                    = true
  public_network_access_enabled = false

  site_config {
    always_on = false

    application_stack {
      node_version = "20-lts"
    }
  }

  tags = local.tags
}

# #############################################################*
# App Service Private Endpoint
# #############################################################*

resource "azurerm_private_endpoint" "appservice" {
  name                = "pe-appservice-${local.name_suffix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = local.tags

  private_service_connection {
    name                           = "psc-appservice-${local.name_suffix}"
    private_connection_resource_id = azurerm_linux_web_app.this.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdzg-appservice"
    private_dns_zone_ids = [azurerm_private_dns_zone.appservice.id]
  }
}

# #############################################################*
# Web Application Firewall policy
# #############################################################*

resource "azurerm_web_application_firewall_policy" "appgw" {
  name                = "wafpol-${local.name_suffix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags

  policy_settings {
    enabled            = true
    mode               = "Prevention"
    request_body_check = true
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }
}

# #############################################################*
# Application Gateway
# #############################################################*

resource "azurerm_application_gateway" "this" {
  name                = "agw-${local.name_suffix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  firewall_policy_id  = azurerm_web_application_firewall_policy.appgw.id
  tags                = local.tags

  sku {
    name = "WAF_v2"
    tier = "WAF_v2"
  }

  autoscale_configuration {
    min_capacity = 0
    max_capacity = 2
  }

  gateway_ip_configuration {
    name      = "appgw-ip-configuration"
    subnet_id = azurerm_subnet.appgw.id
  }

  frontend_ip_configuration {
    name                 = local.appgw_frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  frontend_port {
    name = local.appgw_frontend_port_name
    port = 80
  }

  backend_address_pool {
    name  = local.appgw_backend_pool_name
    fqdns = [azurerm_linux_web_app.this.default_hostname]
  }

  probe {
    name                                      = local.appgw_probe_name
    protocol                                  = "Https"
    path                                      = "/"
    host                                      = azurerm_linux_web_app.this.default_hostname
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = false

    match {
      status_code = ["200-399"]
    }
  }

  backend_http_settings {
    name                  = local.appgw_backend_http_settings_name
    cookie_based_affinity = "Disabled"
    port                  = 443
    protocol              = "Https"
    request_timeout       = 30
    host_name             = azurerm_linux_web_app.this.default_hostname
    probe_name            = local.appgw_probe_name
  }

  http_listener {
    name                           = local.appgw_http_listener_name
    frontend_ip_configuration_name = local.appgw_frontend_ip_configuration_name
    frontend_port_name             = local.appgw_frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.appgw_request_routing_rule_name
    priority                   = 100
    rule_type                  = "Basic"
    http_listener_name         = local.appgw_http_listener_name
    backend_address_pool_name  = local.appgw_backend_pool_name
    backend_http_settings_name = local.appgw_backend_http_settings_name
  }

  depends_on = [
    azurerm_private_endpoint.appservice,
    azurerm_private_dns_zone_virtual_network_link.appgw,
    azurerm_subnet_network_security_group_association.appgw
  ]
}

# #############################################################*
# Log Analytics workspace
# #############################################################*

resource "azurerm_log_analytics_workspace" "this" {
  name                = "law-${local.name_suffix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

# #############################################################*
# Diagnostic settings
# #############################################################*

resource "azurerm_monitor_diagnostic_setting" "appgw" {
  name                       = "diag-appgw"
  target_resource_id         = azurerm_application_gateway.this.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_log {
    category = "ApplicationGatewayAccessLog"
  }

  enabled_log {
    category = "ApplicationGatewayFirewallLog"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "appservice" {
  name                       = "diag-appservice"
  target_resource_id         = azurerm_linux_web_app.this.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_log {
    category = "AppServiceHTTPLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

# #############################################################*
# Outputs
# #############################################################*

output "application_gateway_public_ip" {
  description = "Public IP used to test the Application Gateway listener."
  value       = azurerm_public_ip.appgw.ip_address
}

output "application_gateway_test_url" {
  description = "HTTP URL used for the initial lab tests."
  value       = "http://${azurerm_public_ip.appgw.ip_address}"
}

output "app_service_default_hostname" {
  description = "App Service hostname configured in the backend pool."
  value       = azurerm_linux_web_app.this.default_hostname
}

output "app_service_private_ip" {
  description = "Private IP assigned to the App Service Private Endpoint."
  value       = azurerm_private_endpoint.appservice.private_service_connection[0].private_ip_address
}
