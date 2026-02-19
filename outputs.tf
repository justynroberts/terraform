# MIT License - Copyright (c) fintonlabs.com
#
# outputs.tf - Output Values
# ===========================
# These outputs expose important values from the created resources.
# Use these to:
#   - Configure monitoring tools with integration keys
#   - Reference resource IDs in other Terraform configurations
#   - Verify resource creation
#
# Sensitive outputs (like integration keys) are marked as sensitive
# and won't be displayed in console output by default.
# Use `terraform output -json` to retrieve them.

# =============================================================================
# User Outputs
# =============================================================================

output "user_ids" {
  description = "Map of user keys to their PagerDuty user IDs"
  value       = local.user_ids
}

output "user_details" {
  description = "User details including name and email"
  value = {
    for key, user in pagerduty_user.users : key => {
      id    = user.id
      name  = user.name
      email = user.email
      role  = user.role
    }
  }
}

# =============================================================================
# Team Outputs
# =============================================================================

output "team_ids" {
  description = "Map of team keys to their PagerDuty team IDs"
  value       = local.all_team_ids
}

# =============================================================================
# Schedule Outputs
# =============================================================================

output "schedule_ids" {
  description = "Map of schedule names to their PagerDuty schedule IDs"
  value       = local.schedule_ids
}

output "schedule_urls" {
  description = "Direct URLs to view schedules in PagerDuty web UI"
  value = {
    primary        = "https://app.pagerduty.com/schedules/${pagerduty_schedule.primary.id}"
    secondary      = "https://app.pagerduty.com/schedules/${pagerduty_schedule.secondary.id}"
    follow_the_sun = "https://app.pagerduty.com/schedules/${pagerduty_schedule.follow_the_sun.id}"
    business_hours = "https://app.pagerduty.com/schedules/${pagerduty_schedule.business_hours.id}"
    management     = "https://app.pagerduty.com/schedules/${pagerduty_schedule.management.id}"
  }
}

# =============================================================================
# Escalation Policy Outputs
# =============================================================================

output "escalation_policy_ids" {
  description = "Map of escalation policy names to their IDs"
  value       = local.escalation_policy_ids
}

# =============================================================================
# Service Outputs
# =============================================================================

output "service_ids" {
  description = "Map of service keys to their PagerDuty service IDs"
  value       = local.all_service_ids
}

output "service_urls" {
  description = "Direct URLs to view services in PagerDuty web UI"
  value = {
    for key, service in pagerduty_service.services : key => "https://app.pagerduty.com/services/${service.id}"
  }
}

# =============================================================================
# Integration Keys (Sensitive)
# =============================================================================
# These are the routing keys needed to send events to PagerDuty.
# Keep these secure - anyone with the key can trigger incidents.

output "service_integration_keys" {
  description = "Events API v2 integration keys for each service (use to send events)"
  value       = local.service_integration_keys
  sensitive   = true
}

# Email integration output - uncomment if using email integrations
# output "service_email_addresses" {
#   description = "Email integration addresses for each service"
#   value = {
#     for key, integration in pagerduty_service_integration.email :
#     key => integration.integration_email
#   }
# }

# =============================================================================
# Event Orchestration Outputs
# =============================================================================

output "orchestration_id" {
  description = "Main event orchestration ID"
  value       = local.orchestration_id
}

output "orchestration_routing_key" {
  description = "Routing key for sending events to the orchestration"
  value       = local.orchestration_routing_key
  sensitive   = true
}

# =============================================================================
# Business Service Outputs
# =============================================================================

output "business_service_ids" {
  description = "Business service IDs for service graph and impact analysis"
  value = {
    ecommerce_platform = pagerduty_business_service.ecommerce_platform.id
    mobile_app         = pagerduty_business_service.mobile_app.id
  }
}

# =============================================================================
# Incident Workflow Outputs
# =============================================================================

output "workflow_ids" {
  description = "Incident workflow IDs"
  value       = local.workflow_ids
}

# =============================================================================
# Automation Actions Outputs
# =============================================================================

output "automation_runner_id" {
  description = "Automation Actions runner ID"
  value       = local.automation_runner_id
}

output "automation_action_ids" {
  description = "Automation Action IDs for diagnostic and remediation actions"
  value       = local.automation_action_ids
}

# =============================================================================
# Quick Reference Outputs
# =============================================================================

output "quick_reference" {
  description = "Quick reference for common operations"
  value = {
    environment = var.environment

    send_test_event = <<-EOT
      # Send a test event to the API Gateway service:
      curl -X POST https://events.pagerduty.com/v2/enqueue \
        -H "Content-Type: application/json" \
        -d '{
          "routing_key": "<integration_key>",
          "event_action": "trigger",
          "payload": {
            "summary": "Test alert from Terraform",
            "source": "terraform-test",
            "severity": "info"
          }
        }'
    EOT

    documentation_links = {
      terraform_provider = "https://registry.terraform.io/providers/PagerDuty/pagerduty/latest/docs"
      events_api_v2      = "https://developer.pagerduty.com/docs/events-api-v2/overview/"
      rest_api           = "https://developer.pagerduty.com/api-reference/"
    }
  }
}

# =============================================================================
# Summary Output
# =============================================================================

output "summary" {
  description = "Summary of all created resources"
  value = {
    users              = length(pagerduty_user.users)
    teams              = length(pagerduty_team.teams) + 2 # +2 for static teams
    schedules          = 5
    escalation_policies = 5
    services           = length(pagerduty_service.services) + 1 # +1 for database
    business_services  = 2
    service_integrations = length(pagerduty_service_integration.events_api_v2) * 2 # Events + Email
    event_orchestration_enabled  = var.enable_event_orchestration
    incident_workflows_enabled   = var.enable_incident_workflows
    automation_actions_enabled   = var.enable_automation_actions
  }
}
