# MIT License - Copyright (c) fintonlabs.com
#
# teams.tf - PagerDuty Team Resources
# ====================================
# Teams group users together for organizational purposes and permission management.
# Teams can own services, schedules, and escalation policies.
#
# Team Benefits:
#   - Organize users by function, product, or region
#   - Control access to services and incidents
#   - Filter on-call schedules and dashboards
#   - Enable team-specific analytics and reporting
#
# Best Practices:
#   - Create teams that mirror your organizational structure
#   - Use descriptive names and descriptions
#   - Consider creating parent teams for hierarchical structures

# =============================================================================
# Team Resources
# =============================================================================
# Creates teams dynamically from the var.teams map

resource "pagerduty_team" "teams" {
  for_each = var.teams

  name        = each.value.name
  description = each.value.description

  # Optional: Set a parent team for hierarchical structure
  # parent = pagerduty_team.parent_team.id
}

# =============================================================================
# Additional Static Teams
# =============================================================================
# Sometimes you need teams that don't fit the dynamic pattern.
# Here are examples of commonly needed teams.

# Leadership team for executive escalations
resource "pagerduty_team" "leadership" {
  name        = "Leadership"
  description = "Engineering leadership team for critical escalations"
}

# On-call coordinators team
resource "pagerduty_team" "oncall_coordinators" {
  name        = "On-Call Coordinators"
  description = "Team responsible for managing on-call rotations and schedules"
}

# =============================================================================
# Locals for Team References
# =============================================================================

locals {
  # Map of team keys to their IDs
  team_ids = {
    for key, team in pagerduty_team.teams : key => team.id
  }

  # Include static teams in a combined map
  all_team_ids = merge(
    local.team_ids,
    {
      leadership          = pagerduty_team.leadership.id
      oncall_coordinators = pagerduty_team.oncall_coordinators.id
    }
  )
}
