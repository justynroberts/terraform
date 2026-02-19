# MIT License - Copyright (c) fintonlabs.com
#
# webhook_subscriptions.tf - V3 Webhook Subscriptions
# =====================================================
# V3 Webhooks provide a modern, flexible way to receive PagerDuty events
# at custom HTTP endpoints. They replace the older extension-based webhooks
# with improved filtering and event selection capabilities.
#
# V3 Webhook Features:
#   - Filter by account, team, or service
#   - Select specific event types
#   - HMAC signature verification
#   - Automatic retries with exponential backoff
#   - Rich event payloads with full incident context
#
# Event Types:
#   - incident.*: Incident lifecycle events
#   - service.*: Service configuration changes
#   - pagey.ping: Test/validation pings
#
# Security:
#   - Webhooks are signed with HMAC-SHA256
#   - Use the signature to verify authenticity
#   - Always use HTTPS endpoints

# =============================================================================
# Variables for Webhook Configuration
# =============================================================================

variable "webhook_endpoints" {
  description = "Map of webhook endpoint configurations"
  type = map(object({
    url         = string
    description = string
    active      = optional(bool, true)
  }))
  default = {
    # Example configuration - replace with your actual endpoints
    # primary = {
    #   url         = "https://hooks.example.com/pagerduty"
    #   description = "Primary incident webhook"
    # }
  }
}

variable "enable_webhook_subscriptions" {
  description = "Whether to create V3 webhook subscriptions"
  type        = bool
  default     = true
}

# =============================================================================
# Account-Wide Webhook Subscription
# =============================================================================
# Receives all incident events across the entire account

resource "pagerduty_webhook_subscription" "account_incidents" {
  count = var.enable_webhook_subscriptions ? 1 : 0

  description = "Account-wide incident webhook for central monitoring"
  type        = "webhook_subscription"

  delivery_method {
    type = "http_delivery_method"
    url  = "https://hooks.example.com/pagerduty/account"

    # Optional: Custom headers for authentication
    # custom_header {
    #   name  = "Authorization"
    #   value = "Bearer ${var.webhook_token}"
    # }
  }

  # Filter: All incidents in the account
  filter {
    type = "account_reference"
  }

  events = [
    "incident.triggered",
    "incident.acknowledged",
    "incident.escalated",
    "incident.resolved",
    "incident.reassigned",
    "incident.annotated",
    "incident.unacknowledged",
    "incident.priority_updated",
    "incident.responder.added",
    "incident.responder.replied",
    "incident.status_update_published",
    "incident.reopened",
    "incident.workflow.started",
    "incident.workflow.completed",
  ]

  active = true
}

# =============================================================================
# Service-Specific Webhook Subscription
# =============================================================================
# Receives events only for specific critical services

resource "pagerduty_webhook_subscription" "critical_services" {
  count = var.enable_webhook_subscriptions ? 1 : 0

  description = "Critical services webhook for high-priority alerting"
  type        = "webhook_subscription"

  delivery_method {
    type = "http_delivery_method"
    url  = "https://hooks.example.com/pagerduty/critical"
  }

  # Filter: Specific service only
  filter {
    type = "service_reference"
    id   = pagerduty_service.services["payment_service"].id
  }

  events = [
    "incident.triggered",
    "incident.acknowledged",
    "incident.escalated",
    "incident.resolved",
  ]

  active = true
}

# =============================================================================
# Team-Based Webhook Subscription
# =============================================================================
# Receives events for all services owned by a specific team

resource "pagerduty_webhook_subscription" "sre_team" {
  count = var.enable_webhook_subscriptions ? 1 : 0

  description = "SRE team webhook for team-specific monitoring"
  type        = "webhook_subscription"

  delivery_method {
    type = "http_delivery_method"
    url  = "https://hooks.example.com/pagerduty/sre"
  }

  # Filter: Team-based filtering
  filter {
    type = "team_reference"
    id   = pagerduty_team.teams["sre"].id
  }

  events = [
    "incident.triggered",
    "incident.acknowledged",
    "incident.resolved",
    "incident.priority_updated",
  ]

  active = true
}

# =============================================================================
# Automation Webhook Subscription
# =============================================================================
# Triggers external automation systems for specific events

resource "pagerduty_webhook_subscription" "automation" {
  count = var.enable_webhook_subscriptions ? 1 : 0

  description = "Automation webhook for triggering runbooks"
  type        = "webhook_subscription"

  delivery_method {
    type = "http_delivery_method"
    url  = "https://automation.example.com/pagerduty/trigger"
  }

  # Account-wide for automation triggers
  filter {
    type = "account_reference"
  }

  # Only trigger on new incidents and high-priority updates
  events = [
    "incident.triggered",
    "incident.priority_updated",
  ]

  active = true
}

# =============================================================================
# Analytics/Logging Webhook Subscription
# =============================================================================
# Send all events to analytics platform for reporting

resource "pagerduty_webhook_subscription" "analytics" {
  count = var.enable_webhook_subscriptions ? 1 : 0

  description = "Analytics webhook for incident metrics and reporting"
  type        = "webhook_subscription"

  delivery_method {
    type = "http_delivery_method"
    url  = "https://analytics.example.com/pagerduty/events"
  }

  filter {
    type = "account_reference"
  }

  # Capture all events for comprehensive analytics
  events = [
    "incident.triggered",
    "incident.acknowledged",
    "incident.escalated",
    "incident.resolved",
    "incident.reassigned",
    "incident.priority_updated",
    "incident.responder.added",
    "incident.workflow.started",
    "incident.workflow.completed",
  ]

  active = true
}

# =============================================================================
# Dynamic Webhook Subscriptions
# =============================================================================
# Create webhooks from a variable map

variable "custom_webhooks" {
  description = "Map of custom webhook subscription configurations"
  type = map(object({
    description = string
    url         = string
    filter_type = string                # account_reference, service_reference, team_reference
    filter_id   = optional(string, null)
    events      = list(string)
    active      = optional(bool, true)
  }))
  default = {}

  # Example usage in terraform.tfvars:
  # custom_webhooks = {
  #   slack_backup = {
  #     description = "Backup Slack notification"
  #     url         = "https://hooks.slack.com/services/xxx"
  #     filter_type = "account_reference"
  #     events      = ["incident.triggered", "incident.resolved"]
  #   }
  #   jira_sync = {
  #     description = "JIRA incident sync"
  #     url         = "https://jira.example.com/webhooks/pagerduty"
  #     filter_type = "service_reference"
  #     filter_id   = "PSERVICE123"
  #     events      = ["incident.triggered", "incident.resolved"]
  #   }
  # }
}

resource "pagerduty_webhook_subscription" "dynamic" {
  for_each = var.enable_webhook_subscriptions ? var.custom_webhooks : {}

  description = each.value.description
  type        = "webhook_subscription"

  delivery_method {
    type = "http_delivery_method"
    url  = each.value.url
  }

  filter {
    type = each.value.filter_type
    id   = each.value.filter_id
  }

  events = each.value.events
  active = each.value.active
}

# =============================================================================
# Locals for Webhook Subscription References
# =============================================================================

locals {
  webhook_subscription_ids = var.enable_webhook_subscriptions ? {
    account_incidents = try(pagerduty_webhook_subscription.account_incidents[0].id, null)
    critical_services = try(pagerduty_webhook_subscription.critical_services[0].id, null)
    sre_team          = try(pagerduty_webhook_subscription.sre_team[0].id, null)
    automation        = try(pagerduty_webhook_subscription.automation[0].id, null)
    analytics         = try(pagerduty_webhook_subscription.analytics[0].id, null)
  } : {}
}

# =============================================================================
# Webhook Verification Example
# =============================================================================
#
# V3 Webhooks are signed with HMAC-SHA256. To verify:
#
# Python example:
# ```python
# import hmac
# import hashlib
#
# def verify_webhook(payload, signature, secret):
#     computed = hmac.new(
#         secret.encode(),
#         payload.encode(),
#         hashlib.sha256
#     ).hexdigest()
#     return hmac.compare_digest(computed, signature)
#
# # In your webhook handler:
# signature = request.headers.get('X-PagerDuty-Signature')
# if not verify_webhook(request.body, signature, WEBHOOK_SECRET):
#     return Response(status=401)
# ```
#
# The signature is in the X-PagerDuty-Signature header.
