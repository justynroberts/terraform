# MIT License - Copyright (c) fintonlabs.com
#
# alert_grouping.tf - Alert Grouping Settings
# =============================================
# Alert Grouping automatically combines related alerts into a single incident,
# reducing noise and helping responders focus on the root cause.
#
# Grouping Types:
#   - time: Group alerts within a time window
#   - intelligent: ML-based grouping using alert content
#   - content_based: Group by specific field values
#   - content_based_intelligent: Combines content matching with ML
#
# Benefits:
#   - Reduces alert fatigue
#   - Creates actionable incidents
#   - Correlates related issues automatically
#   - Improves mean time to resolution (MTTR)
#
# Configuration Options:
#   - Time window for grouping
#   - Fields to match for content-based grouping
#   - Aggregate type (all alerts vs. recent only)

# =============================================================================
# Intelligent Alert Grouping (ML-Based)
# =============================================================================
# PagerDuty's ML automatically identifies related alerts based on content.
# Best for services with varied alert patterns.

resource "pagerduty_alert_grouping_setting" "api_gateway_intelligent" {
  name        = "API Gateway Intelligent Grouping"
  description = "ML-based alert grouping for API Gateway service"
  type        = "intelligent"

  services = [
    pagerduty_service.services["api_gateway"].id,
  ]

  config {
    # Time window for grouping (in seconds)
    # Alerts within this window may be grouped together
    time_window = 300 # 5 minutes

    # Aggregate determines how alerts are shown
    # all: Show all alerts in the incident
    # recent: Show only recent alerts
    aggregate = "all"
  }
}

# =============================================================================
# Time-Based Alert Grouping
# =============================================================================
# Groups all alerts within a time window into a single incident.
# Simple but effective for high-volume, related alerts.

resource "pagerduty_alert_grouping_setting" "database_time_based" {
  name        = "Database Time-Based Grouping"
  description = "Group database alerts within a 10-minute window"
  type        = "time"

  services = [
    pagerduty_service.database_primary.id,
  ]

  config {
    # 10-minute grouping window
    time_window = 600
    aggregate   = "all"
  }
}

# =============================================================================
# Content-Based Alert Grouping
# =============================================================================
# Groups alerts with matching field values.
# Useful when alerts have consistent identifying fields.

resource "pagerduty_alert_grouping_setting" "payment_content_based" {
  name        = "Payment Service Content Grouping"
  description = "Group payment alerts by transaction type and error code"
  type        = "content_based"

  services = [
    pagerduty_service.services["payment_service"].id,
  ]

  config {
    time_window = 300

    # Fields to match for grouping
    # Alerts with same values in these fields are grouped
    fields = [
      "source",
      "custom_details.error_code",
      "custom_details.transaction_type",
    ]

    aggregate = "all"
  }
}

# =============================================================================
# Content-Based Intelligent Grouping
# =============================================================================
# Combines content matching with ML for sophisticated grouping.
# Best for complex environments with varied alert patterns.

resource "pagerduty_alert_grouping_setting" "user_service_hybrid" {
  name        = "User Service Hybrid Grouping"
  description = "Content + ML grouping for user service alerts"
  type        = "content_based_intelligent"

  services = [
    pagerduty_service.services["user_service"].id,
  ]

  config {
    time_window = 300

    # Primary grouping fields
    fields = [
      "source",
      "custom_details.component",
    ]

    aggregate = "all"
  }
}

# =============================================================================
# Multi-Service Alert Grouping
# =============================================================================
# Apply same grouping strategy to multiple related services

resource "pagerduty_alert_grouping_setting" "backend_services" {
  name        = "Backend Services Intelligent Grouping"
  description = "Intelligent grouping for all backend services"
  type        = "intelligent"

  services = [
    pagerduty_service.services["notification_service"].id,
    pagerduty_service.services["analytics_service"].id,
  ]

  config {
    time_window = 300
    aggregate   = "all"
  }
}

# =============================================================================
# Dynamic Alert Grouping from Variables
# =============================================================================

variable "alert_grouping_settings" {
  description = "Map of alert grouping configurations"
  type = map(object({
    name         = string
    description  = string
    type         = string # intelligent, time, content_based, content_based_intelligent
    service_keys = list(string)
    time_window  = optional(number, 300)
    fields       = optional(list(string), [])
    aggregate    = optional(string, "all")
  }))
  default = {}

  # Example usage in terraform.tfvars:
  # alert_grouping_settings = {
  #   custom_grouping = {
  #     name         = "Custom Service Grouping"
  #     description  = "Custom grouping configuration"
  #     type         = "content_based"
  #     service_keys = ["api_gateway"]
  #     time_window  = 600
  #     fields       = ["source", "severity"]
  #   }
  # }
}

resource "pagerduty_alert_grouping_setting" "dynamic" {
  for_each = var.alert_grouping_settings

  name        = each.value.name
  description = each.value.description
  type        = each.value.type

  services = [
    for key in each.value.service_keys :
    lookup(local.all_service_ids, key, pagerduty_service.services[key].id)
  ]

  config {
    time_window = each.value.time_window
    fields      = each.value.type == "content_based" || each.value.type == "content_based_intelligent" ? each.value.fields : null
    aggregate   = each.value.aggregate
  }
}

# =============================================================================
# Locals for Alert Grouping References
# =============================================================================

locals {
  alert_grouping_ids = {
    api_gateway_intelligent = pagerduty_alert_grouping_setting.api_gateway_intelligent.id
    database_time_based     = pagerduty_alert_grouping_setting.database_time_based.id
    payment_content_based   = pagerduty_alert_grouping_setting.payment_content_based.id
    user_service_hybrid     = pagerduty_alert_grouping_setting.user_service_hybrid.id
    backend_services        = pagerduty_alert_grouping_setting.backend_services.id
  }
}

# =============================================================================
# Alert Grouping Best Practices
# =============================================================================
#
# Choosing a Grouping Type:
# -------------------------
# - intelligent: Start here if unsure. Good for varied alert patterns.
# - time: Simple and predictable. Good for burst-heavy services.
# - content_based: Use when alerts have consistent identifying fields.
# - content_based_intelligent: Best of both worlds, but more complex.
#
# Time Window Guidelines:
# -----------------------
# - 1-5 minutes: For fast-moving, related alerts
# - 5-10 minutes: Standard grouping window
# - 10-30 minutes: For slow-developing incidents
# - Avoid very long windows (>30 min) as they may group unrelated alerts
#
# Field Selection for Content-Based:
# ----------------------------------
# Good fields to match:
#   - source: Alert source/origin
#   - custom_details.error_code: Specific error codes
#   - custom_details.host: Affected hosts
#   - custom_details.component: System components
#
# Avoid fields that vary too much (timestamps, IDs) or are too generic.
#
# Testing Alert Grouping:
# -----------------------
# 1. Send test alerts with similar content
# 2. Verify they group into a single incident
# 3. Send different alerts to verify they stay separate
# 4. Adjust time window and fields as needed
