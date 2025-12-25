resource "azurerm_policy_definition" "tagging" {
  name         = "require-cost-center-tag"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Exigir etiqueta Centro de Costos"

  metadata = <<METADATA
    {
      "category": "General"
    }
METADATA

  policy_rule = <<POLICY_RULE
    {
      "if": {
        "field": "tags['CentroCostos']",
        "exists": "false"
      },
      "then": {
        "effect": "Deny"
      }
    }
POLICY_RULE
}
