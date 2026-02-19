# MIT License - Copyright (c) fintonlabs.com
#
# team_membership.tf - User-Team Associations
# =============================================
# Team memberships link users to teams with specific roles.
# A user can belong to multiple teams with different roles in each.
#
# Membership Roles:
#   - manager: Full team management (add/remove members, manage schedules)
#   - responder: Can respond to incidents and view team resources (default)
#   - observer: Read-only access to team resources
#
# Best Practices:
#   - Assign at least one manager per team
#   - Use responder role for on-call engineers
#   - Use observer role for stakeholders who need visibility

# =============================================================================
# Team Membership Configuration
# =============================================================================
# Define user-team associations with their roles

locals {
  # Define team memberships as a map for easy management
  # Format: "user_key-team_key" = { user = "user_key", team = "team_key", role = "role" }
  team_memberships = {
    # Platform Engineering Team
    "alice-platform" = {
      user = "alice"
      team = "platform"
      role = "responder"
    }
    "bob-platform" = {
      user = "bob"
      team = "platform"
      role = "manager"
    }

    # Backend Services Team
    "bob-backend" = {
      user = "bob"
      team = "backend"
      role = "responder"
    }
    "carol-backend" = {
      user = "carol"
      team = "backend"
      role = "manager"
    }
    "david-backend" = {
      user = "david"
      team = "backend"
      role = "responder"
    }

    # SRE Team
    "alice-sre" = {
      user = "alice"
      team = "sre"
      role = "manager"
    }
    "carol-sre" = {
      user = "carol"
      team = "sre"
      role = "responder"
    }

    # Leadership Team (Emma as Engineering Manager)
    "emma-leadership" = {
      user = "emma"
      team = "leadership"
      role = "manager"
    }
  }
}

# =============================================================================
# Team Membership Resources
# =============================================================================
# Creates memberships from the local map

resource "pagerduty_team_membership" "memberships" {
  for_each = local.team_memberships

  user_id = pagerduty_user.users[each.value.user].id
  team_id = lookup(local.all_team_ids, each.value.team, pagerduty_team.teams[each.value.team].id)
  role    = each.value.role
}

# =============================================================================
# Example: Bulk Add All Users to a Team
# =============================================================================
# Uncomment to add all users to the SRE team as observers
# Useful for creating visibility across the organization

# resource "pagerduty_team_membership" "all_users_sre_observers" {
#   for_each = var.users
#
#   user_id = pagerduty_user.users[each.key].id
#   team_id = pagerduty_team.teams["sre"].id
#   role    = "observer"
# }

# =============================================================================
# Example: Default Team for All Users
# =============================================================================
# Some organizations want all users in a company-wide team

# resource "pagerduty_team" "company_wide" {
#   name        = "All Engineers"
#   description = "Company-wide team including all engineering staff"
# }

# resource "pagerduty_team_membership" "all_engineers" {
#   for_each = var.users
#
#   user_id = pagerduty_user.users[each.key].id
#   team_id = pagerduty_team.company_wide.id
#   role    = "responder"
# }
