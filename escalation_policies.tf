# MIT License - Copyright (c) fintonlabs.com
#
# escalation_policies.tf - Escalation Policy Resources
# ======================================================
# Escalation policies define the chain of responsibility when incidents occur.
# If the first responder doesn't acknowledge, the incident escalates to the next level.
#
# Key Concepts:
#   - Rules: Each level in the escalation chain
#   - Targets: Who gets notified at each level (users or schedules)
#   - Delay: How long to wait before escalating to the next level
#   - Loops: How many times to cycle through all rules before giving up
#
# Target Types:
#   - schedule_reference: Notify whoever is on-call per the schedule
#   - user_reference: Notify a specific user directly
#
# Best Practices:
#   - Start with on-call schedule, not individual users
#   - Include backup/secondary coverage in later rules
#   - Add management escalation as final rule for critical services
#   - Use meaningful delays (5-15 minutes typically)

# =============================================================================
# Primary Escalation Policy
# =============================================================================
# Standard escalation for most services:
# Level 1: Primary on-call (10 min) -> Level 2: Secondary on-call (10 min) -> Level 3: Management

resource "pagerduty_escalation_policy" "primary" {
  name        = "${var.environment} - Primary Escalation"
  description = "Standard escalation: Primary -> Secondary -> Management"
  num_loops   = var.escalation_num_loops

  # Associate with SRE team
  teams = [pagerduty_team.teams["sre"].id]

  # Level 1: Primary on-call responder
  rule {
    escalation_delay_in_minutes = var.escalation_delay_minutes

    target {
      type = "schedule_reference"
      id   = pagerduty_schedule.primary.id
    }
  }

  # Level 2: Secondary on-call responder
  rule {
    escalation_delay_in_minutes = var.escalation_delay_minutes

    target {
      type = "schedule_reference"
      id   = pagerduty_schedule.secondary.id
    }
  }

  # Level 3: Management escalation
  rule {
    escalation_delay_in_minutes = var.escalation_delay_minutes

    target {
      type = "schedule_reference"
      id   = pagerduty_schedule.management.id
    }
  }
}

# =============================================================================
# Secondary Escalation Policy
# =============================================================================
# For lower-priority services with longer delays

resource "pagerduty_escalation_policy" "secondary" {
  name        = "${var.environment} - Secondary Escalation"
  description = "Extended escalation for non-critical services"
  num_loops   = 1 # Only loop once for lower-priority

  teams = [pagerduty_team.teams["backend"].id]

  # Level 1: Business hours coverage (longer delay)
  rule {
    escalation_delay_in_minutes = 15

    target {
      type = "schedule_reference"
      id   = pagerduty_schedule.business_hours.id
    }
  }

  # Level 2: Primary on-call as backup
  rule {
    escalation_delay_in_minutes = 15

    target {
      type = "schedule_reference"
      id   = pagerduty_schedule.primary.id
    }
  }
}

# =============================================================================
# Critical Escalation Policy
# =============================================================================
# For critical services (payments, core infrastructure) with aggressive escalation

resource "pagerduty_escalation_policy" "critical" {
  name        = "${var.environment} - Critical Escalation"
  description = "Aggressive escalation for critical services with parallel notification"
  num_loops   = 3 # Loop multiple times - this is critical!

  teams = [pagerduty_team.teams["sre"].id]

  # Level 1: Immediately notify both primary AND secondary (parallel)
  rule {
    escalation_delay_in_minutes = 5 # Shorter delay for critical

    # Primary on-call
    target {
      type = "schedule_reference"
      id   = pagerduty_schedule.primary.id
    }

    # Secondary on-call simultaneously
    target {
      type = "schedule_reference"
      id   = pagerduty_schedule.secondary.id
    }
  }

  # Level 2: Global coverage + Management
  rule {
    escalation_delay_in_minutes = 5

    target {
      type = "schedule_reference"
      id   = pagerduty_schedule.follow_the_sun.id
    }

    target {
      type = "schedule_reference"
      id   = pagerduty_schedule.management.id
    }
  }

  # Level 3: All hands - specific users as final backstop
  rule {
    escalation_delay_in_minutes = 5

    # Directly notify the engineering manager
    target {
      type = "user_reference"
      id   = pagerduty_user.users["emma"].id
    }

    # And senior SRE
    target {
      type = "user_reference"
      id   = pagerduty_user.users["alice"].id
    }
  }
}

# =============================================================================
# Follow-the-Sun Escalation Policy
# =============================================================================
# For services needing 24/7 regional coverage

resource "pagerduty_escalation_policy" "follow_the_sun" {
  name        = "${var.environment} - Follow-the-Sun Escalation"
  description = "24/7 global coverage with regional handoffs"
  num_loops   = var.escalation_num_loops

  teams = [pagerduty_team.teams["platform"].id]

  # Level 1: Current region on-call
  rule {
    escalation_delay_in_minutes = var.escalation_delay_minutes

    target {
      type = "schedule_reference"
      id   = pagerduty_schedule.follow_the_sun.id
    }
  }

  # Level 2: Primary as backup
  rule {
    escalation_delay_in_minutes = var.escalation_delay_minutes

    target {
      type = "schedule_reference"
      id   = pagerduty_schedule.primary.id
    }
  }

  # Level 3: Management
  rule {
    escalation_delay_in_minutes = var.escalation_delay_minutes

    target {
      type = "schedule_reference"
      id   = pagerduty_schedule.management.id
    }
  }
}

# =============================================================================
# Direct User Escalation Policy (Example)
# =============================================================================
# Sometimes you need to escalate directly to specific users without schedules
# Useful for very small teams or specialized expertise

resource "pagerduty_escalation_policy" "direct_user" {
  name        = "${var.environment} - Direct User Escalation"
  description = "Direct escalation to specific users (no schedule)"
  num_loops   = 2

  teams = [pagerduty_team.teams["backend"].id]

  # Level 1: Primary engineer
  rule {
    escalation_delay_in_minutes = 10

    target {
      type = "user_reference"
      id   = pagerduty_user.users["bob"].id
    }
  }

  # Level 2: Secondary engineer
  rule {
    escalation_delay_in_minutes = 10

    target {
      type = "user_reference"
      id   = pagerduty_user.users["carol"].id
    }
  }

  # Level 3: Manager
  rule {
    escalation_delay_in_minutes = 10

    target {
      type = "user_reference"
      id   = pagerduty_user.users["emma"].id
    }
  }
}

# =============================================================================
# Locals for Escalation Policy References
# =============================================================================

locals {
  escalation_policy_ids = {
    primary        = pagerduty_escalation_policy.primary.id
    secondary      = pagerduty_escalation_policy.secondary.id
    critical       = pagerduty_escalation_policy.critical.id
    follow_the_sun = pagerduty_escalation_policy.follow_the_sun.id
    direct_user    = pagerduty_escalation_policy.direct_user.id
  }
}
