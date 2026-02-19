# MIT License - Copyright (c) fintonlabs.com
#
# extensions.tf - Service Extensions (Webhooks & Integrations)
# ==============================================================
# Extensions connect PagerDuty services to external systems via webhooks.
# When incidents are triggered, acknowledged, or resolved, PagerDuty sends
# HTTP requests to configured endpoints.
#
# Extension Types:
#   - Generic V2 Webhook: Custom HTTP endpoints for any system
#   - Slack: Native Slack integration (see slack_connections.tf)
#   - ServiceNow: ITSM integration
#   - Jira: Issue tracking integration
#   - Microsoft Teams: Chat integration
#   - Zendesk: Customer support integration
#
# Webhook Payload:
#   PagerDuty sends JSON payloads containing incident details including:
#   - Incident ID, title, description
#   - Service information
#   - Assigned users
#   - Priority and urgency
#   - Custom details from the triggering event
#
# Security Considerations:
#   - Use HTTPS endpoints only
#   - Implement webhook signature verification
#   - Use authentication tokens in headers or URLs
#   - Whitelist PagerDuty IP ranges if needed

# =============================================================================
# Extension Schema Data Sources
# =============================================================================
# Look up extension schemas (templates) for different integration types

data "pagerduty_extension_schema" "webhook" {
  name = "Generic V2 Webhook"
}

# Slack extension schema (requires Slack app installed in PagerDuty)
# Uncomment if you have Slack integration enabled
# data "pagerduty_extension_schema" "slack" {
#   name = "Slack"
# }

# ServiceNow extension schema (requires ServiceNow integration)
# data "pagerduty_extension_schema" "servicenow" {
#   name = "ServiceNow"
# }

# =============================================================================
# Generic Webhook Extensions
# =============================================================================
# Send incident notifications to custom HTTP endpoints

# Webhook for incident notifications to internal systems
resource "pagerduty_extension" "webhook_api_gateway" {
  name              = "API Gateway Incident Webhook"
  extension_schema  = data.pagerduty_extension_schema.webhook.id
  extension_objects = [pagerduty_service.services["api_gateway"].id]

  # Your webhook endpoint URL
  # Replace with your actual endpoint
  endpoint_url = "https://hooks.example.com/pagerduty/incidents"

  # Optional: Include custom configuration
  # config = jsonencode({
  #   headers = {
  #     "X-Custom-Header" = "value"
  #   }
  # })
}

# Webhook for payment service (critical notifications)
resource "pagerduty_extension" "webhook_payment" {
  name              = "Payment Service Critical Webhook"
  extension_schema  = data.pagerduty_extension_schema.webhook.id
  extension_objects = [pagerduty_service.services["payment_service"].id]

  endpoint_url = "https://hooks.example.com/pagerduty/critical"
}

# Webhook for database alerts
resource "pagerduty_extension" "webhook_database" {
  name              = "Database Alert Webhook"
  extension_schema  = data.pagerduty_extension_schema.webhook.id
  extension_objects = [pagerduty_service.database_primary.id]

  endpoint_url = "https://hooks.example.com/pagerduty/database"
}

# =============================================================================
# Multi-Service Webhook Extension (COMMENTED - one service per extension only)
# =============================================================================
# PagerDuty only allows ONE service per extension_objects array.
# To send multiple services to the same endpoint, create separate extensions
# for each service pointing to the same URL.
#
# resource "pagerduty_extension" "webhook_all_services" {
#   name             = "Central Incident Webhook"
#   extension_schema = data.pagerduty_extension_schema.webhook.id
#
#   # LIMITATION: Only ONE service allowed per extension
#   extension_objects = [pagerduty_service.services["api_gateway"].id]
#
#   endpoint_url = "https://hooks.example.com/pagerduty/all-incidents"
# }

# =============================================================================
# Automation Trigger Webhook
# =============================================================================
# Webhook to trigger external automation (runbooks, scripts, etc.)

resource "pagerduty_extension" "automation_trigger" {
  name              = "Automation Trigger Webhook"
  extension_schema  = data.pagerduty_extension_schema.webhook.id
  extension_objects = [pagerduty_service.services["api_gateway"].id]

  # Endpoint for your automation system (e.g., Rundeck, Jenkins, AWS Lambda)
  endpoint_url = "https://automation.example.com/webhooks/pagerduty"
}

# =============================================================================
# Observability Platform Webhook
# =============================================================================
# Send incident data to observability platforms for correlation
# NOTE: Only ONE service per extension - create multiple for more services

resource "pagerduty_extension" "observability_webhook" {
  name             = "Observability Platform Webhook"
  extension_schema = data.pagerduty_extension_schema.webhook.id

  # Only ONE service allowed per extension
  extension_objects = [pagerduty_service.services["api_gateway"].id]

  # Endpoint for your observability platform
  # Examples: Datadog, New Relic, Splunk, Grafana
  endpoint_url = "https://observability.example.com/webhooks/incidents"
}

# =============================================================================
# Status Page Webhook
# =============================================================================
# Update external status page when incidents occur
# NOTE: Only ONE service per extension - create multiple for more services

resource "pagerduty_extension" "status_page_webhook" {
  name             = "Status Page Update Webhook"
  extension_schema = data.pagerduty_extension_schema.webhook.id

  # Only ONE service allowed per extension
  extension_objects = [pagerduty_service.services["api_gateway"].id]

  # Endpoint for your status page provider
  # Examples: Statuspage.io, Cachet, Atlassian Statuspage
  endpoint_url = "https://statuspage.example.com/webhooks/pagerduty"
}

# =============================================================================
# Dynamic Extensions from Variables
# =============================================================================
# Create extensions from a variable map for flexibility

variable "webhook_extensions" {
  description = "Map of webhook extensions to create (NOTE: only first service_key used - one service per extension)"
  type = map(object({
    name         = string
    endpoint_url = string
    service_keys = list(string) # Only first element used - PagerDuty limitation
  }))
  default = {}

  # Example usage in terraform.tfvars:
  # NOTE: PagerDuty only allows ONE service per extension.
  # Create separate extensions for each service if needed.
  # webhook_extensions = {
  #   api_gateway_slack = {
  #     name         = "API Gateway Slack Webhook"
  #     endpoint_url = "https://hooks.slack.com/services/xxx"
  #     service_keys = ["api_gateway"]  # Only first element used
  #   }
  # }
}

resource "pagerduty_extension" "dynamic" {
  for_each = var.webhook_extensions

  name             = each.value.name
  extension_schema = data.pagerduty_extension_schema.webhook.id

  # NOTE: Only ONE service per extension - uses first service_key only
  extension_objects = [
    lookup(local.all_service_ids, each.value.service_keys[0], pagerduty_service.services[each.value.service_keys[0]].id)
  ]

  endpoint_url = each.value.endpoint_url
}

# =============================================================================
# Locals for Extension References
# =============================================================================

locals {
  extension_ids = {
    webhook_api_gateway   = pagerduty_extension.webhook_api_gateway.id
    webhook_payment       = pagerduty_extension.webhook_payment.id
    webhook_database      = pagerduty_extension.webhook_database.id
    automation_trigger    = pagerduty_extension.automation_trigger.id
    observability_webhook = pagerduty_extension.observability_webhook.id
    status_page_webhook   = pagerduty_extension.status_page_webhook.id
  }
}

# =============================================================================
# Webhook Security Best Practices
# =============================================================================
#
# 1. Verify Webhook Signatures:
#    PagerDuty signs webhooks with HMAC-SHA256. Verify the signature:
#
#    signature = HMAC-SHA256(webhook_body, signing_secret)
#    if request_signature != computed_signature:
#        reject_request()
#
# 2. Use HTTPS Only:
#    Always use HTTPS endpoints to encrypt data in transit.
#
# 3. Implement Idempotency:
#    Webhooks may be retried. Use incident_id as idempotency key.
#
# 4. Respond Quickly:
#    Return 2xx within 16 seconds or PagerDuty will retry.
#
# 5. Handle Retries:
#    PagerDuty retries failed webhooks with exponential backoff.
