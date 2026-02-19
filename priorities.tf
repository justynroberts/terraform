# MIT License - Copyright (c) fintonlabs.com
#
# priorities.tf - Incident Priority Configuration
# =================================================
# Priorities help triage incidents by severity. PagerDuty supports up to 5
# priority levels (P1-P5), which must be enabled in your account settings.
#
# Priority Levels (typical convention):
#   P1 - Critical: Complete service outage, revenue impact
#   P2 - High: Major functionality impaired, significant user impact
#   P3 - Medium: Partial service degradation, workaround available
#   P4 - Low: Minor issue, minimal impact
#   P5 - Informational: No immediate impact, awareness only
#
# PREREQUISITES:
#   1. Priorities must be enabled in PagerDuty account settings
#   2. Priority names must match exactly (case-sensitive)
#
# Enable priorities: Settings > Account Settings > Priorities
#
# NOTE: Priorities are looked up via data sources (not created by Terraform)
# because they are account-level settings configured in the PagerDuty UI.

# =============================================================================
# Priority Data Sources
# =============================================================================
# Look up existing priorities by name. These are used to:
#   - Set incident priority in event orchestration rules
#   - Trigger workflows based on priority
#   - Filter incidents in the UI

data "pagerduty_priority" "p1" {
  name = "P1"
}

data "pagerduty_priority" "p2" {
  name = "P2"
}

data "pagerduty_priority" "p3" {
  name = "P3"
}

data "pagerduty_priority" "p4" {
  name = "P4"
}

data "pagerduty_priority" "p5" {
  name = "P5"
}

# =============================================================================
# Locals for Priority References
# =============================================================================

locals {
  # Map priority names to IDs for easy reference
  priority_ids = {
    p1 = data.pagerduty_priority.p1.id
    p2 = data.pagerduty_priority.p2.id
    p3 = data.pagerduty_priority.p3.id
    p4 = data.pagerduty_priority.p4.id
    p5 = data.pagerduty_priority.p5.id
  }

  # Priority descriptions for documentation
  priority_descriptions = {
    p1 = "Critical - Complete outage, immediate action required"
    p2 = "High - Major impact, urgent response needed"
    p3 = "Medium - Partial degradation, timely response needed"
    p4 = "Low - Minor issue, can be scheduled"
    p5 = "Informational - No immediate action required"
  }
}
