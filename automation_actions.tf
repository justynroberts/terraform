# MIT License - Copyright (c) fintonlabs.com
#
# automation_actions.tf - Automation Actions Resources
# ======================================================
# Automation Actions allow you to run scripts and runbooks directly from
# PagerDuty incidents. This enables automated diagnostics and remediation.
#
# Components:
#   - Runner: Executes automation actions (Runbook Automation or Process Automation)
#   - Action: The script or runbook to execute
#   - Service Association: Links actions to services where they can be triggered
#   - Team Association: Controls who can run the action
#
# Action Types:
#   - process_automation: Runs jobs in Process Automation (Rundeck)
#   - script: Runs inline scripts via Process Automation runner
#
# Categories:
#   - diagnostic: Read-only actions for gathering information
#   - remediation: Actions that make changes to resolve issues
#
# PREREQUISITES:
#   - PagerDuty Automation Actions license
#   - Runbook Automation or Process Automation configured
#   - Runner installed and registered
#
# IMPORTANT: Automation Actions are disabled by default. Set
# enable_automation_actions = true and provide runbook credentials to enable.

# =============================================================================
# Runbook Automation Runner
# =============================================================================
# Connects PagerDuty to your Runbook Automation (Rundeck) instance.
# The runner handles authentication and job execution.

resource "pagerduty_automation_actions_runner" "runbook" {
  count = var.enable_automation_actions && var.runbook_api_key != "" ? 1 : 0

  name             = "${var.environment} - Runbook Automation Runner"
  description      = "Runner for Runbook Automation integration"
  runner_type      = "runbook"
  runbook_base_uri = var.runbook_base_uri
  runbook_api_key  = var.runbook_api_key
}

# =============================================================================
# Diagnostic Actions
# =============================================================================
# Read-only actions that gather information without making changes.
# Safe to run during any incident for troubleshooting.
#
# Note: These use process_automation type which references jobs defined
# in your Runbook Automation instance. Replace action_data_reference
# with your actual job IDs.

# Action: Check System Health
resource "pagerduty_automation_actions_action" "check_health" {
  count = var.enable_automation_actions && var.runbook_api_key != "" ? 1 : 0

  name        = "Check System Health"
  description = "Run health checks on affected systems and gather diagnostic information"

  action_type           = "process_automation"
  action_classification = "diagnostic"

  runner_id = pagerduty_automation_actions_runner.runbook[0].id

  # Reference to the job in Runbook Automation
  # Replace with your actual job UUID from Rundeck
  action_data_reference {
    process_automation_job_id = "health-check-job-id"
  }
}

# Action: Check Database Status
resource "pagerduty_automation_actions_action" "check_database" {
  count = var.enable_automation_actions && var.runbook_api_key != "" ? 1 : 0

  name        = "Check Database Status"
  description = "Check database connectivity, replication status, and connection pool"

  action_type           = "process_automation"
  action_classification = "diagnostic"

  runner_id = pagerduty_automation_actions_runner.runbook[0].id

  action_data_reference {
    process_automation_job_id = "database-check-job-id"
  }
}

# Action: Check Application Logs
resource "pagerduty_automation_actions_action" "check_logs" {
  count = var.enable_automation_actions && var.runbook_api_key != "" ? 1 : 0

  name        = "Check Application Logs"
  description = "Retrieve recent application logs for error analysis"

  action_type           = "process_automation"
  action_classification = "diagnostic"

  runner_id = pagerduty_automation_actions_runner.runbook[0].id

  action_data_reference {
    process_automation_job_id = "log-check-job-id"
  }
}

# =============================================================================
# Remediation Actions
# =============================================================================
# Actions that make changes to resolve issues. Use with caution.
# These should have safeguards and confirmation steps.

# Action: Restart Application Service
resource "pagerduty_automation_actions_action" "restart_service" {
  count = var.enable_automation_actions && var.runbook_api_key != "" ? 1 : 0

  name        = "Restart Application Service"
  description = "Safely restart the application service with health checks"

  action_type           = "process_automation"
  action_classification = "remediation"

  runner_id = pagerduty_automation_actions_runner.runbook[0].id

  action_data_reference {
    process_automation_job_id = "restart-service-job-id"
  }
}

# Action: Clear Application Cache
resource "pagerduty_automation_actions_action" "clear_cache" {
  count = var.enable_automation_actions && var.runbook_api_key != "" ? 1 : 0

  name        = "Clear Application Cache"
  description = "Clear application caches (Redis, file cache, etc.)"

  action_type           = "process_automation"
  action_classification = "remediation"

  runner_id = pagerduty_automation_actions_runner.runbook[0].id

  action_data_reference {
    process_automation_job_id = "clear-cache-job-id"
  }
}

# Action: Scale Application (Kubernetes)
resource "pagerduty_automation_actions_action" "scale_application" {
  count = var.enable_automation_actions && var.runbook_api_key != "" ? 1 : 0

  name        = "Scale Application Replicas"
  description = "Scale Kubernetes deployment replicas up to handle increased load"

  action_type           = "process_automation"
  action_classification = "remediation"

  runner_id = pagerduty_automation_actions_runner.runbook[0].id

  action_data_reference {
    process_automation_job_id = "scale-app-job-id"
  }
}

# =============================================================================
# Service Associations
# =============================================================================
# Link automation actions to specific services where they can be triggered

resource "pagerduty_automation_actions_action_service_association" "health_check_api" {
  count = var.enable_automation_actions && var.runbook_api_key != "" ? 1 : 0

  action_id  = pagerduty_automation_actions_action.check_health[0].id
  service_id = pagerduty_service.services["api_gateway"].id
}

resource "pagerduty_automation_actions_action_service_association" "health_check_payment" {
  count = var.enable_automation_actions && var.runbook_api_key != "" ? 1 : 0

  action_id  = pagerduty_automation_actions_action.check_health[0].id
  service_id = pagerduty_service.services["payment_service"].id
}

resource "pagerduty_automation_actions_action_service_association" "database_check" {
  count = var.enable_automation_actions && var.runbook_api_key != "" ? 1 : 0

  action_id  = pagerduty_automation_actions_action.check_database[0].id
  service_id = pagerduty_service.database_primary.id
}

resource "pagerduty_automation_actions_action_service_association" "restart_api" {
  count = var.enable_automation_actions && var.runbook_api_key != "" ? 1 : 0

  action_id  = pagerduty_automation_actions_action.restart_service[0].id
  service_id = pagerduty_service.services["api_gateway"].id
}

# =============================================================================
# Team Associations
# =============================================================================
# Control which teams can run each action

resource "pagerduty_automation_actions_action_team_association" "diagnostic_sre" {
  count = var.enable_automation_actions && var.runbook_api_key != "" ? 1 : 0

  action_id = pagerduty_automation_actions_action.check_health[0].id
  team_id   = pagerduty_team.teams["sre"].id
}

resource "pagerduty_automation_actions_action_team_association" "remediation_sre" {
  count = var.enable_automation_actions && var.runbook_api_key != "" ? 1 : 0

  action_id = pagerduty_automation_actions_action.restart_service[0].id
  team_id   = pagerduty_team.teams["sre"].id
}

# =============================================================================
# Locals for Automation Action References
# =============================================================================

locals {
  automation_runner_id = var.enable_automation_actions && var.runbook_api_key != "" ? pagerduty_automation_actions_runner.runbook[0].id : null

  automation_action_ids = var.enable_automation_actions && var.runbook_api_key != "" ? {
    check_health      = pagerduty_automation_actions_action.check_health[0].id
    check_database    = pagerduty_automation_actions_action.check_database[0].id
    check_logs        = pagerduty_automation_actions_action.check_logs[0].id
    restart_service   = pagerduty_automation_actions_action.restart_service[0].id
    clear_cache       = pagerduty_automation_actions_action.clear_cache[0].id
    scale_application = pagerduty_automation_actions_action.scale_application[0].id
  } : {}
}

# =============================================================================
# Example Script for Runbook Automation
# =============================================================================
# Below is an example of what your Rundeck jobs might look like.
# Create these jobs in your Runbook Automation instance and update
# the process_automation_job_id values above with the actual job UUIDs.
#
# Health Check Job (health-check-job-id):
# ```bash
# #!/bin/bash
# echo "=== System Health Check ==="
# echo "Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
# echo "=== Memory Usage ===" && free -h
# echo "=== Disk Usage ===" && df -h /
# echo "=== Load Average ===" && uptime
# echo "=== Health Check Complete ==="
# ```
#
# Database Check Job (database-check-job-id):
# ```bash
# #!/bin/bash
# echo "=== Database Status Check ==="
# psql -c "SELECT 1 as connection_test;"
# psql -c "SELECT count(*) as active_connections FROM pg_stat_activity WHERE state = 'active';"
# echo "=== Database Check Complete ==="
# ```
#
# Restart Service Job (restart-service-job-id):
# ```bash
# #!/bin/bash
# SERVICE_NAME="${SERVICE_NAME:-application}"
# echo "Restarting $SERVICE_NAME..."
# systemctl restart "$SERVICE_NAME"
# sleep 10
# systemctl status "$SERVICE_NAME"
# ```
