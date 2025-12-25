# ==================================================================================================
# MÓDULO DE GOBERNANZA AZURE - AZURE POLICY
# ==================================================================================================
# Autor: Ronny Ortiz
# Propósito: Implementar políticas de gobernanza y cumplimiento mediante Azure Policy
# Componentes: Policy Definition para etiquetado obligatorio
# ==================================================================================================

# --------------------------------------------------------------------------------------------------
# POLÍTICA: ETIQUETA CENTRO DE COSTOS OBLIGATORIA
# --------------------------------------------------------------------------------------------------
# Política personalizada que DENIEGA la creación de recursos sin tag 'CentroCostos'
# Propósito de negocio: Asegurar atribución de costos para chargeback/showback
# Scope: Se aplica a nivel de subscription o management group (definido en asignación)
resource "azurerm_policy_definition" "tagging" {
  name         = "require-cost-center-tag"
  policy_type  = "Custom"  # Política creada por nosotros (no built-in)
  mode         = "Indexed" # Se aplica a recursos con tags
  display_name = "Exigir etiqueta Centro de Costos"

  # Metadatos para organización en Azure Portal
  metadata = <<METADATA
    {
      "category": "General",
      "version": "1.0.0",
      "description": "Requiere tag CentroCostos para tracking de costos por departamento"
    }
METADATA

  # Definición de la regla en formato JSON
  # Estructura: IF (condición) THEN (efecto)
  policy_rule = <<POLICY_RULE
    {
      "if": {
        "field": "tags['CentroCostos']",         # Evalúa si existe el tag
        "exists": "false"                        # Condición: tag NO existe
      },
      "then": {
        "effect": "Deny"                         # Acción: Bloquear creación del recurso
      }
    }
POLICY_RULE

  # Para aplicar esta policy, crear un azurerm_policy_assignment
  # Ejemplo en proyecto:
  # resource "azurerm_policy_assignment" "cost_center" {
  #   policy_definition_id = azurerm_policy_definition.tagging.id
  #   scope                = azurerm_resource_group.rg.id
  # }
}
