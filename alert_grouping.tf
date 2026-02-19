# MIT License - Copyright (c) fintonlabs.com
#
# alert_grouping.tf - Alert Grouping Settings
# =============================================
# Alert Grouping automatically combines related alerts into a single incident,
# reducing noise and helping responders focus on the root cause.
#
# IMPORTANT: Each service can only have ONE alert grouping setting.
# The examples below are commented out to avoid conflicts with existing settings.
# Use the dynamic variable-based approach or uncomment individual resources as needed.
#
# Grouping Types:
#   - time: Group alerts within a time window (timeout in seconds: 60-86400)
#   - intelligent: ML-based grouping using alert content
#   - content_based: Group by specific field values
#   - content_based_intelligent: Combines content matching with ML

# =============================================================================
# Examples (COMMENTED - each service can only have one grouping setting)
# =============================================================================

# Intelligent grouping example:
# resource "pagerduty_alert_grouping_setting" "api_gateway_intelligent" {
#   name        = "API Gateway Intelligent Grouping"
#   description = "ML-based alert grouping for API Gateway service"
#   type        = "intelligent"
#   services    = [pagerduty_service.services["api_gateway"].id]
#   config {
#     time_window = 300  # seconds
#     aggregate   = "all"
#   }
# }

# Time-based grouping example:
# resource "pagerduty_alert_grouping_setting" "database_time_based" {
#   name        = "Database Time-Based Grouping"
#   description = "Group database alerts within a time window"
#   type        = "time"
#   services    = [pagerduty_service.database_primary.id]
#   config {
#     timeout = 600  # seconds (must be 60-86400)
#   }
# }

# Content-based grouping example:
# resource "pagerduty_alert_grouping_setting" "payment_content_based" {
#   name        = "Payment Service Content Grouping"
#   description = "Group payment alerts by error code"
#   type        = "content_based"
#   services    = [pagerduty_service.services["payment_service"].id]
#   config {
#     time_window = 300
#     fields      = ["source", "custom_details.error_code"]
#     aggregate   = "all"
#   }
# }

# =============================================================================
# Dynamic Alert Grouping from Variables (Recommended)
# =============================================================================
# Use this approach to configure alert grouping via terraform.tfvars

variable "alert_grouping_settings" {
  description = "Map of alert grouping configurations"
  type = map(object({
    name         = string
    description  = string
    type         = string # intelligent, time, content_based, content_based_intelligent
    service_keys = list(string)
    time_window  = optional(number, 300)  # seconds for intelligent/content_based
    timeout      = optional(number, 600)  # seconds for time-based (60-86400)
    fields       = optional(list(string), [])
    aggregate    = optional(string, "all")
  }))
  default = {}

  # Example usage in terraform.tfvars:
  # alert_grouping_settings = {
  #   api_intelligent = {
  #     name         = "API Gateway Grouping"
  #     description  = "Intelligent grouping for API"
  #     type         = "intelligent"
  #     service_keys = ["api_gateway"]
  #     time_window  = 300
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
    time_window = each.value.type != "time" ? each.value.time_window : null
    timeout     = each.value.type == "time" ? each.value.timeout : null
    fields      = contains(["content_based", "content_based_intelligent"], each.value.type) ? each.value.fields : null
    aggregate   = each.value.aggregate
  }
}

# =============================================================================
# Locals for Alert Grouping References
# =============================================================================

locals {
  alert_grouping_ids = {
    for key, setting in pagerduty_alert_grouping_setting.dynamic :
    key => setting.id
  }
}
