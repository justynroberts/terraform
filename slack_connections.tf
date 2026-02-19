# MIT License - Copyright (c) fintonlabs.com
#
# slack_connections.tf - Slack Integration (V2 Connections)
# ===========================================================
# Slack Connections enable native integration between PagerDuty and Slack,
# allowing incident notifications, acknowledgment, and resolution directly
# from Slack channels.
#
# Prerequisites:
#   1. PagerDuty Slack app installed in your Slack workspace
#   2. Slack workspace connected to PagerDuty account
#   3. Workspace ID and Channel ID from Slack
#
# Getting Slack IDs:
#   - Workspace ID: Slack Admin > About this workspace > Workspace ID
#   - Channel ID: Right-click channel > View channel details > scroll to bottom
#
# Connection Types:
#   - Team Connection: All incidents for a team go to a channel
#   - Service Connection: Incidents for specific services go to a channel
#
# Features Enabled:
#   - Incident notifications in Slack
#   - Acknowledge/resolve from Slack
#   - Add responders from Slack
#   - Escalate from Slack
#   - Status updates to channel

# =============================================================================
# Variables for Slack Configuration
# =============================================================================

variable "slack_workspace_id" {
  description = "Slack workspace ID (e.g., T01ABC123)"
  type        = string
  default     = ""
}

variable "slack_channels" {
  description = "Map of Slack channel configurations"
  type = map(object({
    channel_id   = string
    channel_name = string
  }))
  default = {
    # Example configuration - replace with your actual channel IDs
    # incidents = {
    #   channel_id   = "C01234567"
    #   channel_name = "#incidents"
    # }
    # critical = {
    #   channel_id   = "C07654321"
    #   channel_name = "#critical-incidents"
    # }
  }
}

variable "enable_slack_connections" {
  description = "Whether to create Slack connections (requires Slack integration)"
  type        = bool
  default     = false
}

# =============================================================================
# Slack Connection - SRE Team
# =============================================================================
# Connect all SRE team incidents to the main incidents channel

resource "pagerduty_slack_connection" "sre_team" {
  count = var.enable_slack_connections && var.slack_workspace_id != "" && contains(keys(var.slack_channels), "incidents") ? 1 : 0

  source_id   = pagerduty_team.teams["sre"].id
  source_type = "team_reference"

  workspace_id = var.slack_workspace_id
  channel_id   = var.slack_channels["incidents"].channel_id

  notification_type = "responder"

  config {
    events = [
      "incident.triggered",
      "incident.acknowledged",
      "incident.escalated",
      "incident.resolved",
      "incident.reassigned",
      "incident.annotated",
      "incident.unacknowledged",
      "incident.delegated",
      "incident.priority_updated",
      "incident.responder.added",
      "incident.responder.replied",
      "incident.status_update_published",
      "incident.reopened",
    ]

    # Priority filtering (optional)
    # priorities = ["*"] # All priorities
  }
}

# =============================================================================
# Slack Connection - Critical Services
# =============================================================================
# High-priority channel for critical service incidents only

resource "pagerduty_slack_connection" "critical_services" {
  count = var.enable_slack_connections && var.slack_workspace_id != "" && contains(keys(var.slack_channels), "critical") ? 1 : 0

  source_id   = pagerduty_service.services["payment_service"].id
  source_type = "service_reference"

  workspace_id = var.slack_workspace_id
  channel_id   = var.slack_channels["critical"].channel_id

  notification_type = "responder"

  config {
    events = [
      "incident.triggered",
      "incident.acknowledged",
      "incident.escalated",
      "incident.resolved",
      "incident.priority_updated",
    ]
  }
}

# =============================================================================
# Slack Connection - API Gateway Service
# =============================================================================

resource "pagerduty_slack_connection" "api_gateway" {
  count = var.enable_slack_connections && var.slack_workspace_id != "" && contains(keys(var.slack_channels), "incidents") ? 1 : 0

  source_id   = pagerduty_service.services["api_gateway"].id
  source_type = "service_reference"

  workspace_id = var.slack_workspace_id
  channel_id   = var.slack_channels["incidents"].channel_id

  notification_type = "responder"

  config {
    events = [
      "incident.triggered",
      "incident.acknowledged",
      "incident.escalated",
      "incident.resolved",
    ]
  }
}

# =============================================================================
# Slack Connection - Database Service
# =============================================================================

resource "pagerduty_slack_connection" "database" {
  count = var.enable_slack_connections && var.slack_workspace_id != "" && contains(keys(var.slack_channels), "incidents") ? 1 : 0

  source_id   = pagerduty_service.database_primary.id
  source_type = "service_reference"

  workspace_id = var.slack_workspace_id
  channel_id   = var.slack_channels["incidents"].channel_id

  notification_type = "responder"

  config {
    events = [
      "incident.triggered",
      "incident.acknowledged",
      "incident.escalated",
      "incident.resolved",
      "incident.priority_updated",
    ]
  }
}

# =============================================================================
# Dynamic Slack Connections
# =============================================================================
# Create connections from a variable map for flexibility

variable "slack_service_connections" {
  description = "Map of service-to-channel Slack connections"
  type = map(object({
    service_key = string
    channel_key = string
    events      = optional(list(string), ["incident.triggered", "incident.acknowledged", "incident.resolved"])
  }))
  default = {}

  # Example usage in terraform.tfvars:
  # slack_service_connections = {
  #   user_service = {
  #     service_key = "user_service"
  #     channel_key = "incidents"
  #   }
  # }
}

resource "pagerduty_slack_connection" "dynamic" {
  for_each = var.enable_slack_connections && var.slack_workspace_id != "" ? var.slack_service_connections : {}

  source_id   = pagerduty_service.services[each.value.service_key].id
  source_type = "service_reference"

  workspace_id = var.slack_workspace_id
  channel_id   = var.slack_channels[each.value.channel_key].channel_id

  notification_type = "responder"

  config {
    events = each.value.events
  }
}

# =============================================================================
# Locals for Slack Connection References
# =============================================================================

locals {
  slack_connection_ids = var.enable_slack_connections && var.slack_workspace_id != "" ? {
    sre_team          = try(pagerduty_slack_connection.sre_team[0].id, null)
    critical_services = try(pagerduty_slack_connection.critical_services[0].id, null)
    api_gateway       = try(pagerduty_slack_connection.api_gateway[0].id, null)
    database          = try(pagerduty_slack_connection.database[0].id, null)
  } : {}
}

# =============================================================================
# Configuration Notes
# =============================================================================
#
# To enable Slack connections:
#
# 1. Install PagerDuty app in Slack:
#    - Go to PagerDuty: Integrations > Extensions > Add > Slack V2
#    - Follow OAuth flow to connect workspace
#
# 2. Get Slack IDs:
#    Workspace ID:
#      - Go to Slack > Settings & Administration > Workspace settings
#      - Scroll to "Workspace ID" at bottom of page
#
#    Channel ID:
#      - Right-click on channel name
#      - Select "View channel details"
#      - Scroll to bottom to find Channel ID
#
# 3. Configure terraform.tfvars:
#    enable_slack_connections = true
#    slack_workspace_id       = "T01ABC123"
#    slack_channels = {
#      incidents = {
#        channel_id   = "C01234567"
#        channel_name = "#pagerduty-incidents"
#      }
#      critical = {
#        channel_id   = "C07654321"
#        channel_name = "#critical-alerts"
#      }
#    }
#
# 4. Apply configuration:
#    terraform apply
