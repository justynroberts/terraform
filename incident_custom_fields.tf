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
#   - single_value: Free text, single value
#   - multi_value: Free text, multiple values
#
# NOTE: Field options (predefined values) can only be added to NEW fields
# created with field_type ending in "_fixed". Existing fields cannot be
# converted. This config uses simple free-text fields for compatibility.
#
# Prerequisites:
#   Custom fields require specific PagerDuty plan features.

# =============================================================================
# Incident Type Field
# =============================================================================
# Categorize incidents by type for better reporting

resource "pagerduty_incident_custom_field" "incident_type" {
  name         = "incident_type"
  display_name = "Incident Type"
  description  = "The category/type of this incident (e.g., Infrastructure, Application, Security)"
  data_type    = "string"
  field_type   = "single_value"
}

# =============================================================================
# Affected Region Field
# =============================================================================
# Track which regions are impacted

resource "pagerduty_incident_custom_field" "affected_region" {
  name         = "affected_region"
  display_name = "Affected Region(s)"
  description  = "Geographic regions impacted (e.g., US-East, EU, APAC, Global)"
  data_type    = "string"
  field_type   = "single_value"
}

# =============================================================================
# Customer Impact Field
# =============================================================================
# Quantify customer impact for prioritization

resource "pagerduty_incident_custom_field" "customer_impact" {
  name         = "customer_impact"
  display_name = "Customer Impact"
  description  = "Level of customer impact (None, Minimal, Moderate, Significant, Critical)"
  data_type    = "string"
  field_type   = "single_value"
}

# =============================================================================
# Root Cause Category Field
# =============================================================================
# Track root cause categories for trending analysis

resource "pagerduty_incident_custom_field" "root_cause_category" {
  name         = "root_cause_category"
  display_name = "Root Cause Category"
  description  = "Category of the root cause (Code Change, Config Change, Infrastructure, etc.)"
  data_type    = "string"
  field_type   = "single_value"
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
