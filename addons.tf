# MIT License - Copyright (c) fintonlabs.com
#
# addons.tf - PagerDuty Add-ons
# ==============================
# Add-ons extend PagerDuty's UI with custom functionality by embedding
# external web applications within incident details pages.
#
# Use Cases:
#   - Display runbooks alongside incidents
#   - Show monitoring dashboards (Grafana, Datadog)
#   - Embed wiki/documentation pages
#   - Link to internal tools and dashboards
#   - Display service architecture diagrams
#
# Add-on Types:
#   - Full Page Add-ons: Standalone pages in PagerDuty navigation
#   - Incident Show Add-ons: Embedded in incident detail views
#
# Security Considerations:
#   - URLs must be HTTPS
#   - Add-ons can access incident context via URL parameters
#   - Consider authentication for sensitive dashboards

# =============================================================================
# Runbook Dashboard Add-on
# =============================================================================
# Embed runbook documentation in incident views

resource "pagerduty_addon" "runbook_dashboard" {
  name = "Runbook Dashboard"
  src  = "https://wiki.example.com/runbooks/embed"
}

# =============================================================================
# Grafana Dashboard Add-on
# =============================================================================
# Display Grafana metrics dashboard

resource "pagerduty_addon" "grafana_dashboard" {
  name = "Service Metrics (Grafana)"
  src  = "https://grafana.example.com/d/service-overview/embed"
}

# =============================================================================
# Service Architecture Add-on
# =============================================================================
# Show service dependency diagram

resource "pagerduty_addon" "architecture_diagram" {
  name = "Service Architecture"
  src  = "https://architecture.example.com/diagrams/embed"
}

# =============================================================================
# Recent Deployments Add-on
# =============================================================================
# Display recent deployments for correlation

resource "pagerduty_addon" "recent_deployments" {
  name = "Recent Deployments"
  src  = "https://deploys.example.com/timeline/embed"
}

# =============================================================================
# Incident Playbook Add-on
# =============================================================================
# Interactive incident response playbook

resource "pagerduty_addon" "incident_playbook" {
  name = "Incident Response Playbook"
  src  = "https://playbook.example.com/incident/embed"
}

# =============================================================================
# Log Viewer Add-on
# =============================================================================
# Quick access to centralized logging

resource "pagerduty_addon" "log_viewer" {
  name = "Log Viewer"
  src  = "https://logs.example.com/embed"
}

# =============================================================================
# Dynamic Add-ons from Variables
# =============================================================================

variable "custom_addons" {
  description = "Map of custom add-ons to create"
  type = map(object({
    name = string
    src  = string
  }))
  default = {}

  # Example usage in terraform.tfvars:
  # custom_addons = {
  #   datadog = {
  #     name = "Datadog Dashboard"
  #     src  = "https://app.datadoghq.com/dashboard/embed"
  #   }
  # }
}

resource "pagerduty_addon" "dynamic" {
  for_each = var.custom_addons

  name = each.value.name
  src  = each.value.src
}

# =============================================================================
# Locals for Add-on References
# =============================================================================

locals {
  addon_ids = {
    runbook_dashboard    = pagerduty_addon.runbook_dashboard.id
    grafana_dashboard    = pagerduty_addon.grafana_dashboard.id
    architecture_diagram = pagerduty_addon.architecture_diagram.id
    recent_deployments   = pagerduty_addon.recent_deployments.id
    incident_playbook    = pagerduty_addon.incident_playbook.id
    log_viewer           = pagerduty_addon.log_viewer.id
  }
}

# =============================================================================
# Add-on URL Parameters
# =============================================================================
#
# PagerDuty passes incident context to add-ons via URL parameters:
#
# Available parameters:
#   - incident_id: The incident ID
#   - service_id: The service ID
#   - subdomain: Your PagerDuty subdomain
#
# Example URL with parameters:
#   https://wiki.example.com/runbooks/embed?
#     incident_id={{incident.id}}&
#     service_id={{incident.service.id}}
#
# Your add-on page can read these parameters to display
# context-aware information.
