# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Production-ready Terraform examples for PagerDuty infrastructure configuration. Demonstrates best practices for managing users, teams, schedules, escalation policies, services, event orchestrations, incident workflows, and automation actions.

## Quick Start

```bash
# 1. Set authentication
export PAGERDUTY_TOKEN="your-api-token"

# 2. Copy and customize variables
cp terraform.tfvars.example terraform.tfvars

# 3. Initialize and apply
terraform init
terraform plan
terraform apply
```

## Common Commands

```bash
terraform init                    # Initialize provider
terraform validate                # Validate configuration
terraform fmt -recursive          # Format all .tf files
terraform plan                    # Preview changes
terraform apply                   # Apply changes
terraform destroy                 # Remove all resources
terraform output -json            # Get outputs (including sensitive)
terraform output service_integration_keys  # Get integration keys
```

## File Structure

| File | Purpose |
|------|---------|
| `versions.tf` | Terraform and provider version constraints |
| `variables.tf` | All input variable definitions with validation |
| `users.tf` | User accounts, contact methods, notification rules |
| `teams.tf` | Team definitions and hierarchy |
| `team_membership.tf` | User-team associations with roles |
| `schedules.tf` | On-call schedules (weekly, follow-the-sun, business hours) |
| `escalation_policies.tf` | Escalation chains (primary, critical, management) |
| `services.tf` | Technical services, integrations, business services, dependencies |
| `event_orchestrations.tf` | Event routing, transformation, suppression rules |
| `incident_workflows.tf` | Automated response workflows and triggers |
| `automation_actions.tf` | Runbook automation runners and diagnostic/remediation scripts |
| `outputs.tf` | Resource IDs, integration keys, URLs |
| `terraform.tfvars.example` | Example variable values (copy to terraform.tfvars) |

## Architecture

```
Users (5) ──────┬──► Teams (5) ──────────────────────────────────┐
                │                                                 │
                └──► Schedules (5) ──► Escalation Policies (5) ──┼──► Services (6)
                     - Primary             - Primary              │    - API Gateway
                     - Secondary           - Secondary            │    - User Service
                     - Follow-the-sun      - Critical             │    - Payment Service
                     - Business Hours      - Follow-the-sun       │    - Notification Service
                     - Management          - Direct User          │    - Analytics Service
                                                                  │    - Database Primary
                                                                  │
Event Orchestration ─────────────────────────────────────────────►│
  - Global Router (routes by source/content)                      │
  - Service Orchestrations (severity, suppression)                │
  - Unrouted Handler                                              │
                                                                  │
Incident Workflows ◄──────────────────────────────────────────────┤
  - Critical Response (auto-trigger)                              │
  - Customer Communication (manual)                               │
  - Management Escalation (manual)                                │
  - Database Incident (auto-trigger)                              │
  - Post-Incident Review                                          │
                                                                  │
Automation Actions ◄──────────────────────────────────────────────┘
  - Check Health, Check Database, Check Logs (diagnostic)
  - Restart Service, Clear Cache, Scale Application (remediation)
```

## Key Resource Patterns

### Dynamic Resources (from variables)
Users, teams, and services are created from maps in `variables.tf`. Add/remove by modifying the variable:

```hcl
# Add a new user in terraform.tfvars
users = {
  existing_user = { ... }
  new_user = {
    name      = "New Person"
    email     = "new@example.com"
    role      = "user"
    job_title = "Engineer"
    time_zone = "America/New_York"
  }
}
```

### Feature Toggles
Optional features can be enabled/disabled:

```hcl
enable_event_orchestration = true   # Requires appropriate license
enable_incident_workflows  = true   # Requires appropriate license
enable_automation_actions  = false  # Requires Automation Actions license
```

### Resource References
Resources reference each other using locals:

```hcl
# In escalation_policies.tf
target {
  type = "schedule_reference"
  id   = pagerduty_schedule.primary.id
}

# Cross-file references via locals
escalation_policy = local.escalation_policy_ids[each.value.escalation_policy_key]
```

## PagerDuty Resources Reference

| Resource | Description |
|----------|-------------|
| `pagerduty_user` | User accounts with roles |
| `pagerduty_team` | User groupings |
| `pagerduty_team_membership` | User-team associations |
| `pagerduty_schedule` | On-call rotations |
| `pagerduty_escalation_policy` | Alert routing chains |
| `pagerduty_service` | Technical services |
| `pagerduty_service_integration` | Events API, email, vendor integrations |
| `pagerduty_business_service` | Business-level services for impact analysis |
| `pagerduty_service_dependency` | Service relationship mapping |
| `pagerduty_event_orchestration` | Global event routing |
| `pagerduty_event_orchestration_router` | Route events to services |
| `pagerduty_event_orchestration_service` | Per-service event processing |
| `pagerduty_incident_workflow` | Automated response actions |
| `pagerduty_incident_workflow_trigger` | When workflows execute |
| `pagerduty_automation_actions_runner` | Runbook Automation connection |
| `pagerduty_automation_actions_action` | Diagnostic/remediation scripts |

## Sending Test Events

```bash
# Get integration key
ROUTING_KEY=$(terraform output -raw service_integration_keys | jq -r '.api_gateway')

# Send test event
curl -X POST https://events.pagerduty.com/v2/enqueue \
  -H "Content-Type: application/json" \
  -d '{
    "routing_key": "'$ROUTING_KEY'",
    "event_action": "trigger",
    "payload": {
      "summary": "Test alert from Terraform",
      "source": "terraform-test",
      "severity": "info"
    }
  }'
```

## Documentation

- [PagerDuty Terraform Provider](https://registry.terraform.io/providers/PagerDuty/pagerduty/latest/docs)
- [Events API v2](https://developer.pagerduty.com/docs/events-api-v2/overview/)
- [PagerDuty REST API](https://developer.pagerduty.com/api-reference/)
