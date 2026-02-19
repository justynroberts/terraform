# MIT License - Copyright (c) fintonlabs.com
#
# maintenance_windows.tf - Maintenance Window Resources
# =======================================================
# Maintenance windows temporarily disable services to prevent incidents
# and notifications during planned maintenance activities.
#
# Key Behaviors:
#   - No incidents are triggered during the maintenance window
#   - No notifications are sent for affected services
#   - Once started, windows cannot be deleted (only ended early)
#   - Events received during maintenance are still logged
#
# Use Cases:
#   - Scheduled deployments
#   - Infrastructure upgrades
#   - Database maintenance
#   - Network maintenance
#   - Planned failovers
#
# Best Practices:
#   - Schedule windows slightly longer than expected
#   - Include all dependent services
#   - Notify stakeholders before and after
#   - Document the maintenance reason
#
# IMPORTANT: Maintenance windows require FUTURE timestamps.
# The examples below are commented out - uncomment and update dates as needed.

# =============================================================================
# Example: Weekly Deployment Window (COMMENTED - update dates before use)
# =============================================================================
# Uncomment and update start_time/end_time to future dates
#
# resource "pagerduty_maintenance_window" "weekly_deployment" {
#   description = "Weekly deployment window - Tuesday 2 AM UTC"
#   start_time  = "2025-03-01T02:00:00Z"  # UPDATE to future date
#   end_time    = "2025-03-01T04:00:00Z"  # UPDATE to future date
#
#   services = [
#     pagerduty_service.services["api_gateway"].id,
#     pagerduty_service.services["user_service"].id,
#     pagerduty_service.services["notification_service"].id,
#   ]
# }

# =============================================================================
# Example: Database Maintenance Window (COMMENTED - update dates before use)
# =============================================================================
#
# resource "pagerduty_maintenance_window" "database_maintenance" {
#   description = "Scheduled database maintenance - schema migration"
#   start_time  = "2025-03-07T03:00:00Z"  # UPDATE to future date
#   end_time    = "2025-03-07T07:00:00Z"  # UPDATE to future date
#
#   services = [
#     pagerduty_service.database_primary.id,
#     pagerduty_service.services["api_gateway"].id,
#     pagerduty_service.services["user_service"].id,
#     pagerduty_service.services["payment_service"].id,
#   ]
# }

# =============================================================================
# Dynamic Maintenance Window
# =============================================================================
# Create maintenance windows from a variable map - the recommended approach
# This allows CI/CD pipelines to create windows dynamically

variable "maintenance_windows" {
  description = "Map of maintenance windows to create"
  type = map(object({
    description  = string
    start_time   = string # RFC3339 format: "2025-03-01T02:00:00Z"
    end_time     = string # RFC3339 format: "2025-03-01T04:00:00Z"
    service_keys = list(string)
  }))
  default = {}

  # Example usage in terraform.tfvars:
  # maintenance_windows = {
  #   deployment = {
  #     description  = "Weekly deployment"
  #     start_time   = "2025-03-10T02:00:00Z"
  #     end_time     = "2025-03-10T04:00:00Z"
  #     service_keys = ["api_gateway", "user_service"]
  #   }
  # }
}

resource "pagerduty_maintenance_window" "dynamic" {
  for_each = var.maintenance_windows

  description = each.value.description
  start_time  = each.value.start_time
  end_time    = each.value.end_time

  services = [
    for key in each.value.service_keys :
    lookup(local.all_service_ids, key, pagerduty_service.services[key].id)
  ]
}

# =============================================================================
# Locals for Maintenance Window References
# =============================================================================

locals {
  maintenance_window_ids = {
    for key, window in pagerduty_maintenance_window.dynamic :
    key => window.id
  }
}

# =============================================================================
# Usage: Creating Maintenance Windows via CI/CD
# =============================================================================
#
# For automated deployments, create windows dynamically:
#
#   # In your deployment script
#   START=$(date -u +%Y-%m-%dT%H:%M:%SZ)
#   END=$(date -u -d '+2 hours' +%Y-%m-%dT%H:%M:%SZ)
#
#   terraform apply -var="maintenance_windows={
#     deployment = {
#       description  = \"Deployment $(date)\"
#       start_time   = \"$START\"
#       end_time     = \"$END\"
#       service_keys = [\"api_gateway\"]
#     }
#   }"
#
# Or use the PagerDuty API directly for ad-hoc windows:
#   curl -X POST "https://api.pagerduty.com/maintenance_windows" \
#     -H "Authorization: Token token=$PAGERDUTY_TOKEN" \
#     -H "Content-Type: application/json" \
#     -d '{
#       "maintenance_window": {
#         "type": "maintenance_window",
#         "start_time": "2025-03-01T02:00:00Z",
#         "end_time": "2025-03-01T04:00:00Z",
#         "description": "Deployment window",
#         "services": [{"id": "PSERVICE123", "type": "service_reference"}]
#       }
#     }'
