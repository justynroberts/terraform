# MIT License - Copyright (c) fintonlabs.com
#
# response_plays.tf - Response Play Resources
# =============================================
# Response Plays are predefined incident response actions that can be
# triggered with a single click during an incident.
#
# NOTE: Response Plays have been deprecated by PagerDuty in favor of
# Incident Workflows. This file is included for reference and for
# organizations still using Response Plays.
#
# Migration Path:
#   Response Plays -> Incident Workflows (see incident_workflows.tf)
#
# Response Play Capabilities:
#   - Add responders from schedules or specific users
#   - Add subscribers for status updates
#   - Send status updates
#   - Start conference bridges
#   - Post to Slack channels
#
# Use Cases:
#   - Major Incident Response: Rally the team quickly
#   - Customer Escalation: Notify stakeholders
#   - Executive Briefing: Add management to incident

# =============================================================================
# Response Play: Major Incident Response
# =============================================================================
# One-click action to mobilize the entire incident response team

resource "pagerduty_response_play" "major_incident" {
  name        = "Major Incident Response"
  description = "Mobilize full incident response team for major incidents"
  from        = pagerduty_user.users["emma"].email

  # Add responders from schedules
  responder {
    type = "schedule_reference"
    id   = pagerduty_schedule.primary.id
  }

  responder {
    type = "schedule_reference"
    id   = pagerduty_schedule.secondary.id
  }

  # Add subscribers who will receive status updates
  subscriber {
    type = "user_reference"
    id   = pagerduty_user.users["emma"].id
  }

  # Conference bridge settings
  conference_number = "+1-555-123-4567"
  conference_url    = "https://meet.example.com/incident-bridge"

  # Routing determines who can run this play
  runnability = "services" # Can be: services, teams, responders
}

# =============================================================================
# Response Play: Customer Impact Escalation
# =============================================================================
# Notify customer-facing teams and stakeholders

resource "pagerduty_response_play" "customer_escalation" {
  name        = "Customer Impact Escalation"
  description = "Engage customer success and communications teams"
  from        = pagerduty_user.users["emma"].email

  # Add specific users for customer communication
  responder {
    type = "user_reference"
    id   = pagerduty_user.users["emma"].id
  }

  # Add subscribers for status updates
  subscriber {
    type = "team_reference"
    id   = pagerduty_team.leadership.id
  }

  runnability = "services"
}

# =============================================================================
# Response Play: Database Emergency
# =============================================================================
# Specialized response for database emergencies

resource "pagerduty_response_play" "database_emergency" {
  name        = "Database Emergency Response"
  description = "Mobilize database specialists for critical DB issues"
  from        = pagerduty_user.users["alice"].email

  # Add DBA/data team responders
  responder {
    type = "user_reference"
    id   = pagerduty_user.users["alice"].id
  }

  responder {
    type = "user_reference"
    id   = pagerduty_user.users["bob"].id
  }

  # Management notification
  subscriber {
    type = "user_reference"
    id   = pagerduty_user.users["emma"].id
  }

  conference_url = "https://meet.example.com/db-emergency"
  runnability    = "services"
}

# =============================================================================
# Response Play: Security Incident
# =============================================================================
# Security-specific incident response

resource "pagerduty_response_play" "security_incident" {
  name        = "Security Incident Response"
  description = "Engage security team for potential security incidents"
  from        = pagerduty_user.users["emma"].email

  # Security team responders
  responder {
    type = "team_reference"
    id   = pagerduty_team.teams["sre"].id
  }

  # Notify leadership
  subscriber {
    type = "user_reference"
    id   = pagerduty_user.users["emma"].id
  }

  # Secure conference bridge
  conference_number = "+1-555-999-0000"
  conference_url    = "https://secure-meet.example.com/security"

  runnability = "responders" # Only responders can trigger
}

# =============================================================================
# Locals for Response Play References
# =============================================================================

locals {
  response_play_ids = {
    major_incident      = pagerduty_response_play.major_incident.id
    customer_escalation = pagerduty_response_play.customer_escalation.id
    database_emergency  = pagerduty_response_play.database_emergency.id
    security_incident   = pagerduty_response_play.security_incident.id
  }
}

# =============================================================================
# Migration Notes: Response Plays to Incident Workflows
# =============================================================================
#
# Response Plays are being replaced by Incident Workflows, which offer:
#   - More flexible trigger conditions (automatic, manual, conditional)
#   - Better integration with modern tools (Slack, Teams, Jira)
#   - Step-based execution with error handling
#   - More action types available
#
# To migrate:
# 1. Review existing Response Plays and their actions
# 2. Create equivalent Incident Workflows in incident_workflows.tf
# 3. Test workflows thoroughly
# 4. Update documentation and training
# 5. Remove Response Plays once workflows are verified
#
# See incident_workflows.tf for modern workflow examples.
