# MIT License - Copyright (c) fintonlabs.com
#
# incident_workflows.tf - Incident Workflow Resources
# =====================================================
# Incident Workflows automate response actions when incidents occur.
# They can be triggered manually or automatically based on conditions.
#
# Workflow Components:
#   - Steps: Actions to execute (send notifications, create channels, etc.)
#   - Triggers: When the workflow runs (manual, conditional, etc.)
#
# Common Actions:
#   - pagerduty.com:incident-workflows:send-status-update:1
#   - pagerduty.com:incident-workflows:add-responders:1
#   - pagerduty.com:incident-workflows:add-conference-bridge:1
#   - pagerduty.com:incident-workflows:create-slack-channel:1
#   - pagerduty.com:incident-workflows:send-slack-message:1
#   - pagerduty.com:incident-workflows:create-incident-task:1
#   - pagerduty.com:incident-workflows:run-script:1 (Automation Actions)
#
# Trigger Types:
#   - manual: Responder manually triggers from incident
#   - conditional: Automatically triggers when conditions are met
#
# IMPORTANT: Some actions require additional integrations (Slack, Zoom, etc.)
# to be configured in PagerDuty before they can be used.

# =============================================================================
# Incident Workflow - Critical Incident Response
# =============================================================================
# Automated response for critical/P1 incidents:
#   1. Send status update to stakeholders
#   2. Add additional responders
#   3. Create response tasks

resource "pagerduty_incident_workflow" "critical_response" {
  count = var.enable_incident_workflows ? 1 : 0

  name        = "${var.environment} - Critical Incident Response"
  description = "Automated response workflow for critical incidents (P1/SEV1)"

  # Step 1: Send initial status update
  step {
    name   = "Send Initial Status Update"
    action = "pagerduty.com:incident-workflows:send-status-update:1"

    input {
      name  = "Message"
      value = "Critical incident detected. Response team has been engaged. Initial investigation is underway. Next update in 15 minutes."
    }
  }

  # Step 2: Add additional responders from secondary schedule
  step {
    name   = "Add Secondary Responders"
    action = "pagerduty.com:incident-workflows:add-responders:1"

    input {
      name  = "Responders"
      value = jsonencode([{
        type = "schedule_reference"
        id   = pagerduty_schedule.secondary.id
      }])
    }

    input {
      name  = "Message"
      value = "You are being added to a critical incident. Please join the response immediately."
    }
  }
}

# Trigger: Automatically run for critical/P1 incidents
resource "pagerduty_incident_workflow_trigger" "critical_auto" {
  count = var.enable_incident_workflows ? 1 : 0

  type     = "conditional"
  workflow = pagerduty_incident_workflow.critical_response[0].id

  # Apply to specific high-priority services
  subscribed_to_all_services = false
  services = [
    pagerduty_service.services["payment_service"].id,
    pagerduty_service.services["api_gateway"].id,
    pagerduty_service.database_primary.id,
  ]

  # Trigger condition: Priority is P1 or severity is critical
  condition = "incident.priority matches 'P1' or incident.urgency matches 'high'"
}

# =============================================================================
# Incident Workflow - Customer Communication
# =============================================================================
# Manual workflow for sending customer-facing updates

resource "pagerduty_incident_workflow" "customer_communication" {
  count = var.enable_incident_workflows ? 1 : 0

  name        = "${var.environment} - Customer Communication"
  description = "Send status updates to customers and stakeholders (manual trigger)"

  # Step 1: Send status update
  step {
    name   = "Send Customer Status Update"
    action = "pagerduty.com:incident-workflows:send-status-update:1"

    input {
      name  = "Message"
      value = "We are aware of an issue affecting our services and are actively working on a resolution. We will provide updates as more information becomes available."
    }
  }
}

# Manual trigger for customer communication
resource "pagerduty_incident_workflow_trigger" "customer_communication_manual" {
  count = var.enable_incident_workflows ? 1 : 0

  type     = "manual"
  workflow = pagerduty_incident_workflow.customer_communication[0].id

  subscribed_to_all_services = true
}

# =============================================================================
# Incident Workflow - Post-Incident Review
# =============================================================================
# Triggered when incident is resolved to kick off post-incident process

resource "pagerduty_incident_workflow" "post_incident" {
  count = var.enable_incident_workflows ? 1 : 0

  name        = "${var.environment} - Post-Incident Review"
  description = "Send resolution update when incident is resolved"

  # Send resolution status update
  step {
    name   = "Send Resolution Update"
    action = "pagerduty.com:incident-workflows:send-status-update:1"

    input {
      name  = "Message"
      value = "Incident has been resolved. A post-incident review will be scheduled within 48 hours. Thank you for your patience."
    }
  }
}

# =============================================================================
# Incident Workflow - Escalation to Management
# =============================================================================
# Manual workflow for escalating to management with context

resource "pagerduty_incident_workflow" "management_escalation" {
  count = var.enable_incident_workflows ? 1 : 0

  name        = "${var.environment} - Escalate to Management"
  description = "Manually escalate incident to engineering management"

  # Step 1: Add management as responders
  step {
    name   = "Add Management Responders"
    action = "pagerduty.com:incident-workflows:add-responders:1"

    input {
      name  = "Responders"
      value = jsonencode([{
        type = "schedule_reference"
        id   = pagerduty_schedule.management.id
      }])
    }

    input {
      name  = "Message"
      value = "Management escalation requested. Please review incident status and provide guidance."
    }
  }

  # Step 2: Send escalation status
  step {
    name   = "Send Escalation Status"
    action = "pagerduty.com:incident-workflows:send-status-update:1"

    input {
      name  = "Message"
      value = "Incident has been escalated to engineering management for additional support and decision-making."
    }
  }
}

# Manual trigger for management escalation
resource "pagerduty_incident_workflow_trigger" "management_escalation_manual" {
  count = var.enable_incident_workflows ? 1 : 0

  type     = "manual"
  workflow = pagerduty_incident_workflow.management_escalation[0].id

  subscribed_to_all_services = true
}

# =============================================================================
# Incident Workflow - Database Incident Specific
# =============================================================================
# Specialized workflow for database-related incidents

resource "pagerduty_incident_workflow" "database_incident" {
  count = var.enable_incident_workflows ? 1 : 0

  name        = "${var.environment} - Database Incident Response"
  description = "Specialized response workflow for database incidents"

  # Send database incident status update
  step {
    name   = "Send Database Incident Update"
    action = "pagerduty.com:incident-workflows:send-status-update:1"

    input {
      name  = "Message"
      value = "Database incident detected. DBA team has been notified. Checking connection pools, replication status, and backup availability."
    }
  }

  # Add DBA responders
  step {
    name   = "Notify Additional DBA"
    action = "pagerduty.com:incident-workflows:add-responders:1"

    input {
      name  = "Responders"
      value = jsonencode([{
        type = "user_reference"
        id   = pagerduty_user.users["alice"].id
      }])
    }

    input {
      name  = "Message"
      value = "Database incident in progress. Your expertise is requested."
    }
  }
}

# Conditional trigger for database service incidents
resource "pagerduty_incident_workflow_trigger" "database_incident_auto" {
  count = var.enable_incident_workflows ? 1 : 0

  type     = "conditional"
  workflow = pagerduty_incident_workflow.database_incident[0].id

  subscribed_to_all_services = false
  services = [
    pagerduty_service.database_primary.id,
  ]

  condition = "incident.urgency matches 'high'"
}

# =============================================================================
# Locals for Workflow References
# =============================================================================

locals {
  workflow_ids = var.enable_incident_workflows ? {
    critical_response      = pagerduty_incident_workflow.critical_response[0].id
    customer_communication = pagerduty_incident_workflow.customer_communication[0].id
    post_incident          = pagerduty_incident_workflow.post_incident[0].id
    management_escalation  = pagerduty_incident_workflow.management_escalation[0].id
    database_incident      = pagerduty_incident_workflow.database_incident[0].id
  } : {}
}
