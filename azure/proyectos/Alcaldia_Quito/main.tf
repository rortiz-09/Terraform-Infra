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

# --------------------------------------------------------------------------------------------------
# ESTRUCTURA ORGANIZACIONAL Y GOBERNANZA (Azure Management Groups)
# --------------------------------------------------------------------------------------------------
# Grupo de recursos central para servicios compartidos del municipio.
resource "azurerm_resource_group" "corp_governance" {
  name     = "rg-quito-gobernanza-prod"
  location = "East US 2" # Región con baja latencia para Ecuador

  tags = {
    Departamento = "Administracion Central"
    Responsable  = "CIO Alcaldia"
    Compliance   = "Normativa-Interna-001"
  }
}

# --------------------------------------------------------------------------------------------------
# POLÍTICAS DE GOBIERNO (Azure Policy)
# --------------------------------------------------------------------------------------------------
# Restricción para desplegar recursos solo en regiones aprobadas por soberanía de datos o latencia.
resource "azurerm_policy_definition" "allowed_regions" {
  name         = "only-allowed-regions"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Permitir solo regiones US para Alcaldia"

  policy_rule = <<POLICY_RULE
    {
    "if": {
      "not": {
        "field": "location",
        "in": ["eastus", "eastus2", "centralus"]
      }
    },
    "then": {
      "effect": "Deny"
    }
  }
POLICY_RULE
}

resource "azurerm_resource_group_policy_assignment" "audit_regions" {
  name                 = "asignacion-region-permitida"
  resource_group_id    = azurerm_resource_group.corp_governance.id
  policy_definition_id = azurerm_policy_definition.allowed_regions.id
  description          = "Asegura que los datos no salgan de las regiones permitidas."
}

# --------------------------------------------------------------------------------------------------
# CONECTIVIDAD HÍBRIDA (Simulación Conexión On-Premise)
# --------------------------------------------------------------------------------------------------
# Red Virtual preparada para VPN Gateway para conectar oficinas municipales dispersas.
resource "azurerm_virtual_network" "hybrid_vnet" {
  name                = "vnet-quito-hybrid"
  location            = azurerm_resource_group.corp_governance.location
  resource_group_name = azurerm_resource_group.corp_governance.name
  address_space       = ["10.100.0.0/16"]

  tags = {
    Environment = "Produccion"
    Conexion    = "Site-to-Site VPN"
  }
}

resource "azurerm_subnet" "gateway_subnet" {
  name                 = "GatewaySubnet" # Nombre requerido para VPN Gateways
  resource_group_name  = azurerm_resource_group.corp_governance.name
  virtual_network_name = azurerm_virtual_network.hybrid_vnet.name
  address_prefixes     = ["10.100.1.0/24"]
}

# Subred para Active Directory Controllers (Extensión de identidad on-prem)
resource "azurerm_subnet" "identity_subnet" {
  name                 = "snet-identity-ad"
  resource_group_name  = azurerm_resource_group.corp_governance.name
  virtual_network_name = azurerm_virtual_network.hybrid_vnet.name
  address_prefixes     = ["10.100.2.0/24"]
}
