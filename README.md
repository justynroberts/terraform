# PagerDuty Terraform Examples

Production-ready Terraform configuration for PagerDuty infrastructure. This repository provides comprehensive examples demonstrating best practices for managing your entire PagerDuty environment as code.

## What's Included

| Resource | Count | Description |
|----------|-------|-------------|
| Users | 5 | Team members with notification rules |
| Teams | 5 | Organizational groupings (Platform, Backend, SRE, Leadership, On-Call Coordinators) |
| Schedules | 5 | Weekly rotation, follow-the-sun, business hours, management |
| Escalation Policies | 5 | Primary, secondary, critical, follow-the-sun, direct user |
| Services | 6 | API Gateway, User, Payment, Notification, Analytics, Database |
| Business Services | 2 | E-Commerce Platform, Mobile App (with dependencies) |
| Event Orchestration | 1 | Global routing with service-level rules |
| Incident Workflows | 5 | Critical response, customer comms, management escalation |
| Automation Actions | 6 | Health checks, log analysis, restart, cache clear, scale |

## Managed Resources

This configuration manages the following PagerDuty resources:

### Core Resources
| Resource | Terraform Type | Description |
|----------|---------------|-------------|
| **Users** | `pagerduty_user` | User accounts with roles (admin, user, observer) |
| **Teams** | `pagerduty_team` | Organizational groupings for users and services |
| **Team Memberships** | `pagerduty_team_membership` | User-to-team associations with roles (manager, responder, observer) |
| **Schedules** | `pagerduty_schedule` | On-call rotations with layers and restrictions |
| **Escalation Policies** | `pagerduty_escalation_policy` | Multi-level escalation chains |
| **Services** | `pagerduty_service` | Technical services that receive alerts |
| **Service Integrations** | `pagerduty_service_integration` | Events API, vendor integrations (Datadog, Prometheus, etc.) |

### Business Context
| Resource | Terraform Type | Description |
|----------|---------------|-------------|
| **Business Services** | `pagerduty_business_service` | Business-level services for impact analysis |
| **Service Dependencies** | `pagerduty_service_dependency` | Relationship mapping between services |
| **Tags** | `pagerduty_tag` | Labels for organizing resources |
| **Tag Assignments** | `pagerduty_tag_assignment` | Apply tags to teams, users, or services |
| **Priorities** | `pagerduty_priority` (data) | P1-P5 incident priority levels |

### Event Processing
| Resource | Terraform Type | Description |
|----------|---------------|-------------|
| **Event Orchestration** | `pagerduty_event_orchestration` | Global event routing engine |
| **Orchestration Router** | `pagerduty_event_orchestration_router` | Route events to services based on content |
| **Service Orchestration** | `pagerduty_event_orchestration_service` | Per-service event transformation and suppression |
| **Unrouted Orchestration** | `pagerduty_event_orchestration_unrouted` | Handle events that don't match routing rules |
| **Alert Grouping** | `pagerduty_alert_grouping_setting` | Intelligent, time-based, or content-based grouping |

### Incident Response
| Resource | Terraform Type | Description |
|----------|---------------|-------------|
| **Incident Workflows** | `pagerduty_incident_workflow` | Automated response sequences |
| **Workflow Triggers** | `pagerduty_incident_workflow_trigger` | Conditions that start workflows |
| **Custom Fields** | `pagerduty_incident_custom_field` | Additional incident metadata fields |
| **Field Options** | `pagerduty_incident_custom_field_option` | Predefined values for custom fields |

### Automation
| Resource | Terraform Type | Description |
|----------|---------------|-------------|
| **Automation Runner** | `pagerduty_automation_actions_runner` | Connection to Runbook Automation |
| **Automation Actions** | `pagerduty_automation_actions_action` | Diagnostic and remediation scripts |

### Integrations & Extensions
| Resource | Terraform Type | Description |
|----------|---------------|-------------|
| **Extensions** | `pagerduty_extension` | Webhook integrations for external systems |
| **Slack Connections** | `pagerduty_slack_connection` | Native Slack V2 integration |
| **Webhook Subscriptions** | `pagerduty_webhook_subscription` | V3 outbound webhooks |
| **Add-ons** | `pagerduty_addon` | UI extensions (dashboards, runbooks) |

### Operations
| Resource | Terraform Type | Description |
|----------|---------------|-------------|
| **Maintenance Windows** | `pagerduty_maintenance_window` | Scheduled maintenance periods |
| **Rulesets** | `pagerduty_ruleset` | Legacy event rules (use Event Orchestration instead) |
| **Ruleset Rules** | `pagerduty_ruleset_rule` | Individual rules within rulesets |
| **Service Event Rules** | `pagerduty_service_event_rule` | Per-service event processing rules |

### Vendor Integrations (Data Sources)
| Vendor | Description |
|--------|-------------|
| Datadog | APM and infrastructure monitoring |
| Prometheus | Metrics and alerting |
| CloudWatch | AWS monitoring |
| Splunk | Log analysis |

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.0
- PagerDuty account with API access
- PagerDuty API token ([create here](https://support.pagerduty.com/docs/generating-api-keys))

### Optional Features

Some features require additional PagerDuty licenses:
- **Event Orchestration**: Included in most plans
- **Incident Workflows**: Requires Business plan or higher
- **Automation Actions**: Requires Automation Actions add-on

## Quick Start

### 1. Clone and Configure

```bash
git clone https://github.com/your-org/pagerduty-terraform-examples.git
cd pagerduty-terraform-examples

# Set your API token
export PAGERDUTY_TOKEN="your-api-token-here"

# Copy example variables
cp terraform.tfvars.example terraform.tfvars
```

### 2. Customize Variables

Edit `terraform.tfvars` to configure:
- User names and emails
- Team structure
- Service names and escalation mappings
- Timezone settings
- Feature toggles

### 3. Deploy

```bash
# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Apply configuration
terraform apply
```

### 4. Verify

```bash
# View created resources
terraform output summary

# Get service integration keys (for sending events)
terraform output -json service_integration_keys
```

## File Structure

```
.
├── versions.tf              # Terraform & provider versions
├── variables.tf             # Input variable definitions
├── terraform.tfvars.example # Example configuration values
├── users.tf                 # User accounts & notification rules
├── teams.tf                 # Team definitions
├── team_membership.tf       # User-team associations
├── schedules.tf             # On-call schedules
├── escalation_policies.tf   # Escalation chains
├── services.tf              # Services, integrations, dependencies
├── event_orchestrations.tf  # Event routing & transformation
├── incident_workflows.tf    # Automated response workflows
├── automation_actions.tf    # Diagnostic & remediation scripts
├── outputs.tf               # Resource IDs & integration keys
├── CLAUDE.md                # AI assistant guidance
└── README.md                # This file
```

## Configuration Guide

### Adding Users

Add entries to the `users` map in `terraform.tfvars`:

```hcl
users = {
  john = {
    name      = "John Doe"
    email     = "john.doe@company.com"
    role      = "user"           # user, admin, limited_user, observer
    job_title = "SRE"
    time_zone = "America/New_York"
  }
}
```

### Adding Services

Add entries to the `services` map:

```hcl
services = {
  my_service = {
    name                  = "My New Service"
    description           = "Description of the service"
    escalation_policy_key = "primary"  # Must match key in escalation_policies
    urgency               = "high"     # high or low
  }
}
```

### Configuring Schedules

Modify `schedules.tf` to adjust:
- Rotation length (`rotation_turn_length_seconds`)
- Coverage windows (restrictions)
- User assignments

### Feature Toggles

Enable/disable optional features:

```hcl
enable_event_orchestration = true   # Event routing rules
enable_incident_workflows  = true   # Automated workflows
enable_automation_actions  = false  # Requires additional license
```

## Sending Test Events

After deployment, test your configuration:

```bash
# Get the integration key
ROUTING_KEY=$(terraform output -json service_integration_keys | jq -r '.api_gateway')

# Send a test event
curl -X POST https://events.pagerduty.com/v2/enqueue \
  -H "Content-Type: application/json" \
  -d '{
    "routing_key": "'$ROUTING_KEY'",
    "event_action": "trigger",
    "payload": {
      "summary": "Test alert - please ignore",
      "source": "terraform-test",
      "severity": "info",
      "custom_details": {
        "environment": "test"
      }
    }
  }'
```

## Schedule Patterns

### Weekly Rotation
Standard 7-day rotation where one person is on-call per week.

### Follow-the-Sun
24/7 coverage with regional handoffs:
- Americas: 14:00-22:00 UTC
- EMEA: 06:00-14:00 UTC
- APAC: 22:00-06:00 UTC

### Business Hours
Coverage during work hours only (Mon-Fri, 9 AM - 6 PM).

## Escalation Patterns

### Standard (Primary)
1. Primary on-call (10 min) → 2. Secondary (10 min) → 3. Management

### Critical
1. Primary + Secondary simultaneously (5 min) → 2. Global + Management (5 min) → 3. Specific engineers

### Direct User
Escalates to specific users without schedules.

## Event Orchestration

Routes events based on content:
- `payment` in source → Payment Service
- `api-gateway` in source → API Gateway
- `database` or `postgres` → Database Service
- Unmatched → Default service

Service-level orchestration handles:
- Severity assignment based on error codes
- Suppression during maintenance
- Deduplication

## Security Notes

- Never commit `terraform.tfvars` with real values
- Use environment variables for sensitive data: `export TF_VAR_pagerduty_token="..."`
- Integration keys are sensitive - treat them like passwords
- Review automation action scripts before enabling

## Troubleshooting

### "User email already exists"
Users with existing emails cannot be recreated. Import them:
```bash
terraform import 'pagerduty_user.users["key"]' USER_ID
```

### "Schedule layer must have at least one user"
Ensure all referenced users exist before creating schedules.

### "Escalation policy has no targets"
Schedules must be created before escalation policies that reference them.

## Resources

- [PagerDuty Terraform Provider Docs](https://registry.terraform.io/providers/PagerDuty/pagerduty/latest/docs)
- [PagerDuty Events API v2](https://developer.pagerduty.com/docs/events-api-v2/overview/)
- [PagerDuty REST API Reference](https://developer.pagerduty.com/api-reference/)
- [Event Orchestration Guide](https://support.pagerduty.com/docs/event-orchestration)
- [Incident Workflows Guide](https://support.pagerduty.com/docs/incident-workflows)

## License

MIT License - See individual files for copyright notices.
