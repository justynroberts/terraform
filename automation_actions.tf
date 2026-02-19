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

# Action: Check System Health
resource "pagerduty_automation_actions_action" "check_health" {
  count = var.enable_automation_actions && var.runbook_api_key != "" ? 1 : 0

  name        = "Check System Health"
  description = "Run health checks on affected systems and gather diagnostic information"

  action_type          = "script"
  action_classification = "diagnostic"

  runner = pagerduty_automation_actions_runner.runbook[0].id

  # Inline script for basic health check
  # In production, this would call your actual monitoring/diagnostic scripts
  script = <<-EOF
    #!/bin/bash
    # System Health Check Script
    # This script runs basic health checks and outputs results

    echo "=== System Health Check ==="
    echo "Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo ""

    echo "=== Memory Usage ==="
    free -h || cat /proc/meminfo | head -10

    echo ""
    echo "=== Disk Usage ==="
    df -h /

    echo ""
    echo "=== Load Average ==="
    uptime

    echo ""
    echo "=== Network Connectivity ==="
    ping -c 3 8.8.8.8 || echo "Network check failed"

    echo ""
    echo "=== Recent Error Logs ==="
    journalctl -p err --since "10 minutes ago" --no-pager | tail -20 || \
      tail -20 /var/log/syslog 2>/dev/null || \
      echo "Unable to retrieve logs"

    echo ""
    echo "=== Health Check Complete ==="
  EOF
}

# Action: Check Database Status
resource "pagerduty_automation_actions_action" "check_database" {
  count = var.enable_automation_actions && var.runbook_api_key != "" ? 1 : 0

  name        = "Check Database Status"
  description = "Check database connectivity, replication status, and connection pool"

  action_type          = "script"
  action_classification = "diagnostic"

  runner = pagerduty_automation_actions_runner.runbook[0].id

  script = <<-EOF
    #!/bin/bash
    # Database Status Check Script
    # Requires appropriate database client and credentials

    echo "=== Database Status Check ==="
    echo "Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo ""

    # PostgreSQL example (customize for your database)
    if command -v psql &> /dev/null; then
      echo "=== PostgreSQL Status ==="

      echo "Connection test:"
      psql -c "SELECT 1 as connection_test;" 2>&1 | head -5

      echo ""
      echo "Active connections:"
      psql -c "SELECT count(*) as active_connections FROM pg_stat_activity WHERE state = 'active';" 2>&1

      echo ""
      echo "Replication status:"
      psql -c "SELECT client_addr, state, sent_lsn, write_lsn, replay_lsn FROM pg_stat_replication;" 2>&1 | head -10

      echo ""
      echo "Table sizes (top 5):"
      psql -c "SELECT relname, pg_size_pretty(pg_total_relation_size(relid)) as size FROM pg_catalog.pg_statio_user_tables ORDER BY pg_total_relation_size(relid) DESC LIMIT 5;" 2>&1

    else
      echo "PostgreSQL client not found. Skipping database checks."
    fi

    echo ""
    echo "=== Database Check Complete ==="
  EOF
}

# Action: Check Application Logs
resource "pagerduty_automation_actions_action" "check_logs" {
  count = var.enable_automation_actions && var.runbook_api_key != "" ? 1 : 0

  name        = "Check Application Logs"
  description = "Retrieve recent application logs for error analysis"

  action_type          = "script"
  action_classification = "diagnostic"

  runner = pagerduty_automation_actions_runner.runbook[0].id

  script = <<-EOF
    #!/bin/bash
    # Application Log Check Script

    echo "=== Application Log Analysis ==="
    echo "Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo ""

    # Check for common log locations
    LOG_DIRS=(
      "/var/log/application"
      "/var/log/app"
      "/opt/app/logs"
    )

    for dir in "$${LOG_DIRS[@]}"; do
      if [ -d "$dir" ]; then
        echo "=== Logs from $dir ==="
        echo "Recent errors (last 50 lines with ERROR):"
        find "$dir" -name "*.log" -mmin -60 -exec grep -l "ERROR\|Exception\|FATAL" {} \; | \
          xargs -I {} sh -c 'echo "--- {} ---"; tail -50 {} | grep -i "error\|exception\|fatal"' 2>/dev/null | head -100
        echo ""
      fi
    done

    # Check journalctl for systemd services
    if command -v journalctl &> /dev/null; then
      echo "=== Systemd Service Errors (last 10 minutes) ==="
      journalctl -p err --since "10 minutes ago" --no-pager | tail -50
    fi

    echo ""
    echo "=== Log Analysis Complete ==="
  EOF
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

  action_type          = "script"
  action_classification = "remediation"

  runner = pagerduty_automation_actions_runner.runbook[0].id

  script = <<-EOF
    #!/bin/bash
    # Service Restart Script with Safety Checks

    SERVICE_NAME="$${SERVICE_NAME:-application}"

    echo "=== Service Restart: $SERVICE_NAME ==="
    echo "Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo ""

    # Pre-restart health check
    echo "=== Pre-Restart Status ==="
    systemctl status "$SERVICE_NAME" 2>&1 | head -20

    echo ""
    echo "=== Initiating Graceful Restart ==="

    # Attempt graceful restart
    if systemctl restart "$SERVICE_NAME"; then
      echo "Restart command successful. Waiting for service to stabilize..."
      sleep 10

      # Post-restart health check
      echo ""
      echo "=== Post-Restart Status ==="
      systemctl status "$SERVICE_NAME" 2>&1 | head -20

      # Verify service is healthy
      if systemctl is-active --quiet "$SERVICE_NAME"; then
        echo ""
        echo "SUCCESS: Service $SERVICE_NAME is running."
      else
        echo ""
        echo "WARNING: Service may not be fully healthy. Manual verification required."
        exit 1
      fi
    else
      echo "ERROR: Failed to restart service $SERVICE_NAME"
      exit 1
    fi

    echo ""
    echo "=== Restart Complete ==="
  EOF
}

# Action: Clear Application Cache
resource "pagerduty_automation_actions_action" "clear_cache" {
  count = var.enable_automation_actions && var.runbook_api_key != "" ? 1 : 0

  name        = "Clear Application Cache"
  description = "Clear application caches (Redis, file cache, etc.)"

  action_type          = "script"
  action_classification = "remediation"

  runner = pagerduty_automation_actions_runner.runbook[0].id

  script = <<-EOF
    #!/bin/bash
    # Cache Clear Script

    echo "=== Cache Clear Operation ==="
    echo "Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo ""

    # Clear Redis cache if available
    if command -v redis-cli &> /dev/null; then
      echo "=== Clearing Redis Cache ==="
      redis-cli FLUSHDB 2>&1
      echo "Redis cache cleared."
      echo ""
    fi

    # Clear file cache
    CACHE_DIRS=(
      "/var/cache/application"
      "/tmp/app-cache"
    )

    for dir in "$${CACHE_DIRS[@]}"; do
      if [ -d "$dir" ]; then
        echo "=== Clearing $dir ==="
        rm -rf "$dir"/*
        echo "Cleared: $dir"
      fi
    done

    echo ""
    echo "=== Cache Clear Complete ==="
  EOF
}

# Action: Scale Application (Kubernetes)
resource "pagerduty_automation_actions_action" "scale_application" {
  count = var.enable_automation_actions && var.runbook_api_key != "" ? 1 : 0

  name        = "Scale Application Replicas"
  description = "Scale Kubernetes deployment replicas up to handle increased load"

  action_type          = "script"
  action_classification = "remediation"

  runner = pagerduty_automation_actions_runner.runbook[0].id

  script = <<-EOF
    #!/bin/bash
    # Kubernetes Scaling Script

    NAMESPACE="$${NAMESPACE:-production}"
    DEPLOYMENT="$${DEPLOYMENT:-api-gateway}"
    TARGET_REPLICAS="$${TARGET_REPLICAS:-5}"

    echo "=== Kubernetes Scaling Operation ==="
    echo "Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "Namespace: $NAMESPACE"
    echo "Deployment: $DEPLOYMENT"
    echo "Target Replicas: $TARGET_REPLICAS"
    echo ""

    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
      echo "ERROR: kubectl not found"
      exit 1
    fi

    # Get current status
    echo "=== Current Deployment Status ==="
    kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" 2>&1

    echo ""
    echo "=== Scaling to $TARGET_REPLICAS replicas ==="
    kubectl scale deployment "$DEPLOYMENT" -n "$NAMESPACE" --replicas="$TARGET_REPLICAS" 2>&1

    # Wait for rollout
    echo ""
    echo "=== Waiting for rollout to complete ==="
    kubectl rollout status deployment/"$DEPLOYMENT" -n "$NAMESPACE" --timeout=300s 2>&1

    echo ""
    echo "=== Final Status ==="
    kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" 2>&1
    kubectl get pods -n "$NAMESPACE" -l app="$DEPLOYMENT" 2>&1

    echo ""
    echo "=== Scaling Complete ==="
  EOF
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
