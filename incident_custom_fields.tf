# MIT License - Copyright (c) fintonlabs.com
#
# incident_custom_fields.tf - Incident Custom Fields
# ====================================================
# Custom fields allow you to add structured metadata to incidents for
# better categorization, reporting, and workflow automation.
#
# Use Cases:
#   - Track affected customers or regions
#   - Categorize incident types (infrastructure, application, security)
#   - Record business impact metrics
#   - Link to external ticket systems
#   - Capture compliance-related information
#
# Field Types:
#   - single_value: Single selection from predefined options
#   - multi_value: Multiple selections allowed
#   - single_value_fixed: Single selection, cannot be changed after creation
#   - multi_value_fixed: Multiple selections, cannot be changed
#
# Prerequisites:
#   Custom fields require specific PagerDuty plan features.
#   Check your plan's feature availability.

# =============================================================================
# Incident Type Field
# =============================================================================
# Categorize incidents by type for better reporting

resource "pagerduty_incident_custom_field" "incident_type" {
  name          = "incident_type"
  display_name  = "Incident Type"
  description   = "The category/type of this incident"
  data_type     = "string"
  field_type    = "single_value_fixed"
  }

resource "pagerduty_incident_custom_field_option" "incident_type_infrastructure" {
  field    = pagerduty_incident_custom_field.incident_type.id
  data_type = "string"
  value    = "Infrastructure"
}

resource "pagerduty_incident_custom_field_option" "incident_type_application" {
  field    = pagerduty_incident_custom_field.incident_type.id
  data_type = "string"
  value    = "Application"
}

resource "pagerduty_incident_custom_field_option" "incident_type_security" {
  field    = pagerduty_incident_custom_field.incident_type.id
  data_type = "string"
  value    = "Security"
}

resource "pagerduty_incident_custom_field_option" "incident_type_network" {
  field    = pagerduty_incident_custom_field.incident_type.id
  data_type = "string"
  value    = "Network"
}

resource "pagerduty_incident_custom_field_option" "incident_type_database" {
  field    = pagerduty_incident_custom_field.incident_type.id
  data_type = "string"
  value    = "Database"
}

resource "pagerduty_incident_custom_field_option" "incident_type_third_party" {
  field    = pagerduty_incident_custom_field.incident_type.id
  data_type = "string"
  value    = "Third-Party Dependency"
}

# =============================================================================
# Affected Region Field
# =============================================================================
# Track which regions are impacted

resource "pagerduty_incident_custom_field" "affected_region" {
  name          = "affected_region"
  display_name  = "Affected Region(s)"
  description   = "Geographic regions impacted by this incident"
  data_type     = "string"
  field_type    = "multi_value_fixed"
  }

resource "pagerduty_incident_custom_field_option" "region_us_east" {
  field    = pagerduty_incident_custom_field.affected_region.id
  data_type = "string"
  value    = "US-East"
}

resource "pagerduty_incident_custom_field_option" "region_us_west" {
  field    = pagerduty_incident_custom_field.affected_region.id
  data_type = "string"
  value    = "US-West"
}

resource "pagerduty_incident_custom_field_option" "region_eu" {
  field    = pagerduty_incident_custom_field.affected_region.id
  data_type = "string"
  value    = "EU"
}

resource "pagerduty_incident_custom_field_option" "region_apac" {
  field    = pagerduty_incident_custom_field.affected_region.id
  data_type = "string"
  value    = "APAC"
}

resource "pagerduty_incident_custom_field_option" "region_global" {
  field    = pagerduty_incident_custom_field.affected_region.id
  data_type = "string"
  value    = "Global"
}

# =============================================================================
# Customer Impact Field
# =============================================================================
# Quantify customer impact for prioritization

resource "pagerduty_incident_custom_field" "customer_impact" {
  name          = "customer_impact"
  display_name  = "Customer Impact"
  description   = "Level of customer impact"
  data_type     = "string"
  field_type    = "single_value_fixed"
  }

resource "pagerduty_incident_custom_field_option" "impact_none" {
  field    = pagerduty_incident_custom_field.customer_impact.id
  data_type = "string"
  value    = "None - Internal Only"
}

resource "pagerduty_incident_custom_field_option" "impact_minimal" {
  field    = pagerduty_incident_custom_field.customer_impact.id
  data_type = "string"
  value    = "Minimal - Few Customers"
}

resource "pagerduty_incident_custom_field_option" "impact_moderate" {
  field    = pagerduty_incident_custom_field.customer_impact.id
  data_type = "string"
  value    = "Moderate - Some Customers"
}

resource "pagerduty_incident_custom_field_option" "impact_significant" {
  field    = pagerduty_incident_custom_field.customer_impact.id
  data_type = "string"
  value    = "Significant - Many Customers"
}

resource "pagerduty_incident_custom_field_option" "impact_critical" {
  field    = pagerduty_incident_custom_field.customer_impact.id
  data_type = "string"
  value    = "Critical - All Customers"
}

# =============================================================================
# Root Cause Category Field
# =============================================================================
# Track root cause categories for trending analysis

resource "pagerduty_incident_custom_field" "root_cause_category" {
  name          = "root_cause_category"
  display_name  = "Root Cause Category"
  description   = "Category of the root cause (set during post-incident)"
  data_type     = "string"
  field_type    = "single_value_fixed"
  }

resource "pagerduty_incident_custom_field_option" "cause_code_change" {
  field    = pagerduty_incident_custom_field.root_cause_category.id
  data_type = "string"
  value    = "Code Change/Deployment"
}

resource "pagerduty_incident_custom_field_option" "cause_config_change" {
  field    = pagerduty_incident_custom_field.root_cause_category.id
  data_type = "string"
  value    = "Configuration Change"
}

resource "pagerduty_incident_custom_field_option" "cause_infrastructure" {
  field    = pagerduty_incident_custom_field.root_cause_category.id
  data_type = "string"
  value    = "Infrastructure Failure"
}

resource "pagerduty_incident_custom_field_option" "cause_capacity" {
  field    = pagerduty_incident_custom_field.root_cause_category.id
  data_type = "string"
  value    = "Capacity/Scaling"
}

resource "pagerduty_incident_custom_field_option" "cause_external" {
  field    = pagerduty_incident_custom_field.root_cause_category.id
  data_type = "string"
  value    = "External/Third-Party"
}

resource "pagerduty_incident_custom_field_option" "cause_security" {
  field    = pagerduty_incident_custom_field.root_cause_category.id
  data_type = "string"
  value    = "Security Incident"
}

resource "pagerduty_incident_custom_field_option" "cause_unknown" {
  field    = pagerduty_incident_custom_field.root_cause_category.id
  data_type = "string"
  value    = "Unknown/Under Investigation"
}

# =============================================================================
# External Ticket Field
# =============================================================================
# Link to external ticketing systems (free text)

resource "pagerduty_incident_custom_field" "external_ticket" {
  name         = "external_ticket"
  display_name = "External Ticket"
  description  = "Link to JIRA, ServiceNow, or other ticket"
  data_type    = "string"
  field_type   = "single_value"
}

# =============================================================================
# Locals for Custom Field References
# =============================================================================

locals {
  custom_field_ids = {
    incident_type       = pagerduty_incident_custom_field.incident_type.id
    affected_region     = pagerduty_incident_custom_field.affected_region.id
    customer_impact     = pagerduty_incident_custom_field.customer_impact.id
    root_cause_category = pagerduty_incident_custom_field.root_cause_category.id
    external_ticket     = pagerduty_incident_custom_field.external_ticket.id
  }
}

# =============================================================================
# Usage Notes
# =============================================================================
#
# Setting Custom Fields via API:
# ------------------------------
# When creating/updating incidents via API, include custom fields:
#
# curl -X POST https://api.pagerduty.com/incidents \
#   -H "Authorization: Token token=$PAGERDUTY_TOKEN" \
#   -H "Content-Type: application/json" \
#   -d '{
#     "incident": {
#       "type": "incident",
#       "title": "Server outage",
#       "service": {"id": "PSERVICE123", "type": "service_reference"},
#       "custom_fields": [
#         {
#           "name": "incident_type",
#           "value": "Infrastructure"
#         },
#         {
#           "name": "customer_impact",
#           "value": "Significant - Many Customers"
#         }
#       ]
#     }
#   }'
#
# Reporting on Custom Fields:
# ---------------------------
# Custom fields appear in:
#   - Incident detail pages
#   - Analytics reports
#   - Webhook payloads
#   - API responses
#
# Use them for:
#   - Trending analysis (most common incident types)
#   - Impact reporting (customer impact over time)
#   - Root cause analysis (deployment vs config changes)
