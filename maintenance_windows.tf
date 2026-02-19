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
# IMPORTANT: Maintenance windows use RFC3339 timestamps.
# If start_time is in the past, PagerDuty updates it to current time.

# =============================================================================
# Example: Weekly Deployment Window
# =============================================================================
# Recurring deployment window every Tuesday at 2 AM UTC for 2 hours
# Note: Terraform manages state, so this creates a single window.
# For recurring windows, use external scheduling (CI/CD, cron) to create them.

resource "pagerduty_maintenance_window" "weekly_deployment" {
  description = "Weekly deployment window - Tuesday 2 AM UTC"

  # Start time must be in the future when created
  # Update these values for your actual maintenance window
  start_time = "2024-12-03T02:00:00Z"
  end_time   = "2024-12-03T04:00:00Z"

  services = [
    pagerduty_service.services["api_gateway"].id,
    pagerduty_service.services["user_service"].id,
    pagerduty_service.services["notification_service"].id,
  ]
}

# =============================================================================
# Example: Database Maintenance Window
# =============================================================================
# Longer window for database maintenance with all database-dependent services

resource "pagerduty_maintenance_window" "database_maintenance" {
  description = "Scheduled database maintenance - schema migration and optimization"

  start_time = "2024-12-07T03:00:00Z"
  end_time   = "2024-12-07T07:00:00Z"

  services = [
    pagerduty_service.database_primary.id,
    pagerduty_service.services["api_gateway"].id,
    pagerduty_service.services["user_service"].id,
    pagerduty_service.services["payment_service"].id,
  ]
}

# =============================================================================
# Example: Infrastructure Upgrade Window
# =============================================================================
# Platform-wide maintenance for infrastructure upgrades

resource "pagerduty_maintenance_window" "infrastructure_upgrade" {
  description = "Quarterly infrastructure upgrade - Kubernetes cluster update"

  start_time = "2024-12-14T00:00:00Z"
  end_time   = "2024-12-14T06:00:00Z"

  # All services affected during platform maintenance
  services = [
    pagerduty_service.services["api_gateway"].id,
    pagerduty_service.services["user_service"].id,
    pagerduty_service.services["payment_service"].id,
    pagerduty_service.services["notification_service"].id,
    pagerduty_service.services["analytics_service"].id,
    pagerduty_service.database_primary.id,
  ]
}

# =============================================================================
# Dynamic Maintenance Window Example
# =============================================================================
# Create maintenance windows from a variable map for more flexibility

variable "maintenance_windows" {
  description = "Map of maintenance windows to create"
  type = map(object({
    description  = string
    start_time   = string
    end_time     = string
    service_keys = list(string)
  }))
  default = {}

  # Example usage in terraform.tfvars:
  # maintenance_windows = {
  #   deployment = {
  #     description  = "Weekly deployment"
  #     start_time   = "2024-12-10T02:00:00Z"
  #     end_time     = "2024-12-10T04:00:00Z"
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
    weekly_deployment      = pagerduty_maintenance_window.weekly_deployment.id
    database_maintenance   = pagerduty_maintenance_window.database_maintenance.id
    infrastructure_upgrade = pagerduty_maintenance_window.infrastructure_upgrade.id
  }
}

# =============================================================================
# Usage Notes
# =============================================================================
#
# Creating Maintenance Windows via CI/CD:
# --------------------------------------
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
# Ending a Maintenance Window Early:
# ----------------------------------
# Update the end_time to the current time (or slightly in the past):
#
#   terraform apply -var='maintenance_windows={...end_time="2024-01-01T00:00:00Z"...}'
#
# Or use the PagerDuty API directly:
#   curl -X DELETE "https://api.pagerduty.com/maintenance_windows/{id}" \
#     -H "Authorization: Token token=$PAGERDUTY_TOKEN"
