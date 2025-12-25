# --------------------------------------------------------------------------------------------------
# Created by Ronny
# Project: Retail Supermaxi E-Commerce
# License: MIT
# --------------------------------------------------------------------------------------------------

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg_retail" {
  name     = "rg-supermaxi-ecommerce-prod"
  location = "East US"
}

# --------------------------------------------------------------------------------------------------
# NETWORKING (Modular)
# --------------------------------------------------------------------------------------------------
module "networking" {
  source = "../../../modules/networking"

  resource_group_name = azurerm_resource_group.rg_retail.name
  location            = azurerm_resource_group.rg_retail.location
  vnet_name           = "vnet-ecommerce-prod"
  address_space       = ["10.160.0.0/16"]

  subnets = {
    "snet-aks"   = "10.160.10.0/24"
    "snet-appgw" = "10.160.20.0/24"
  }
}

# --------------------------------------------------------------------------------------------------
# IP PUBLICA (WAF Frontend)
# --------------------------------------------------------------------------------------------------
resource "azurerm_public_ip" "waf_public_ip" {
  name                = "pip-appgw-supermaxi"
  resource_group_name = azurerm_resource_group.rg_retail.name
  location            = azurerm_resource_group.rg_retail.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# --------------------------------------------------------------------------------------------------
# ORQUESTACIÓN DE CONTENEDORES (AKS)
# --------------------------------------------------------------------------------------------------
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-supermaxi-prod-001"
  location            = azurerm_resource_group.rg_retail.location
  resource_group_name = azurerm_resource_group.rg_retail.name
  dns_prefix          = "supermaxi-k8s"

  default_node_pool {
    name                = "default"
    node_count          = 3
    vm_size             = "Standard_D4s_v3"
    enable_auto_scaling = true
    min_count           = 3
    max_count           = 20
    vnet_subnet_id      = module.networking.subnet_ids["snet-aks"]
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }

  tags = {
    Environment = "Production"
    Team        = "Ecommerce AppDev"
  }
}

# --------------------------------------------------------------------------------------------------
# APPLICATION GATEWAY + WAF
# --------------------------------------------------------------------------------------------------
resource "azurerm_application_gateway" "network" {
  name                = "appgw-supermaxi-prod"
  resource_group_name = azurerm_resource_group.rg_retail.name
  location            = azurerm_resource_group.rg_retail.location

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = module.networking.subnet_ids["snet-appgw"]
  }

  waf_configuration {
    enabled          = true
    firewall_mode    = "Prevention"
    rule_set_type    = "OWASP"
    rule_set_version = "3.2"
  }

  # Configuración Frontend
  frontend_port {
    name = "port_80"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "frontend_ip"
    public_ip_address_id = azurerm_public_ip.waf_public_ip.id
  }

  # Configuración Backend (Apunta a AKS indirectamente)
  backend_address_pool {
    name = "aks-backend"
  }

  backend_http_settings {
    name                  = "http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = "listener"
    frontend_ip_configuration_name = "frontend_ip"
    frontend_port_name             = "port_80"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "rule"
    rule_type                  = "Basic"
    http_listener_name         = "listener"
    backend_address_pool_name  = "aks-backend"
    backend_http_settings_name = "http-settings"
  }

  # Identidad administrada (opcional pero buena práctica)
  identity {
    type = "SystemAssigned"
  }
}
