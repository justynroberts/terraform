# MIT License - Copyright (c) fintonlabs.com
#
# schedules.tf - On-Call Schedule Resources
# ==========================================
# Schedules define who is on-call at any given time. They're the foundation
# of incident routing and ensure 24/7 coverage for your services.
#
# Schedule Components:
#   - Layers: Define rotation patterns (who rotates when)
#   - Overrides: Temporary changes for vacations, swaps, etc.
#   - Restrictions: Limit when a layer is active (business hours, weekends)
#
# Common Patterns:
#   - Weekly rotation: One person per week
#   - Daily rotation: One person per day
#   - Follow-the-sun: Multiple layers for different timezones
#   - Business hours + After hours: Different coverage for work vs off-hours
#
# IMPORTANT: Schedule times are in UTC unless you specify a timezone.
# Always set time_zone to avoid confusion.

# =============================================================================
# Primary On-Call Schedule (Weekly Rotation)
# =============================================================================
# Standard weekly rotation for the primary responder team
# Users rotate every Monday at 9 AM local time

resource "pagerduty_schedule" "primary" {
  name        = "${var.environment} - Primary On-Call"
  description = "Primary on-call rotation for critical services"
  time_zone   = var.default_timezone

  # Associate with SRE team
  teams = [pagerduty_team.teams["sre"].id]

  # Layer 1: Primary responders on weekly rotation
  layer {
    name                         = "Primary Rotation"
    start                        = var.schedule_start_time
    rotation_virtual_start       = var.schedule_start_time
    rotation_turn_length_seconds = 604800 # 7 days in seconds

    # Users in rotation order
    users = [
      pagerduty_user.users["alice"].id,
      pagerduty_user.users["bob"].id,
      pagerduty_user.users["carol"].id,
    ]
  }
}

# =============================================================================
# Secondary On-Call Schedule (Weekly Rotation)
# =============================================================================
# Backup responders who can assist if primary is overwhelmed or unavailable

resource "pagerduty_schedule" "secondary" {
  name        = "${var.environment} - Secondary On-Call"
  description = "Secondary/backup on-call rotation"
  time_zone   = var.default_timezone

  teams = [pagerduty_team.teams["sre"].id]

  layer {
    name                         = "Secondary Rotation"
    start                        = var.schedule_start_time
    rotation_virtual_start       = var.schedule_start_time
    rotation_turn_length_seconds = 604800 # 7 days

    # Offset rotation so secondary is different from primary
    users = [
      pagerduty_user.users["david"].id,
      pagerduty_user.users["carol"].id,
      pagerduty_user.users["alice"].id,
    ]
  }
}

# =============================================================================
# Follow-the-Sun Schedule (Multi-Layer)
# =============================================================================
# 24/7 coverage using multiple layers for different regions/timezones.
# Each layer is restricted to specific hours, creating seamless global coverage.

resource "pagerduty_schedule" "follow_the_sun" {
  name        = "${var.environment} - Follow-the-Sun"
  description = "24/7 global coverage with regional handoffs"
  time_zone   = "UTC" # Use UTC as base for follow-the-sun

  teams = [pagerduty_team.teams["platform"].id]

  # Americas coverage (14:00-22:00 UTC / 9 AM - 5 PM ET)
  layer {
    name                         = "Americas"
    start                        = var.schedule_start_time
    rotation_virtual_start       = var.schedule_start_time
    rotation_turn_length_seconds = 604800

    users = [
      pagerduty_user.users["alice"].id,
      pagerduty_user.users["bob"].id,
    ]

    # Restrict to Americas business hours (UTC)
    restriction {
      type              = "weekly_restriction"
      start_day_of_week = 1 # Monday
      start_time_of_day = "14:00:00"
      duration_seconds  = 28800 # 8 hours
    }
    restriction {
      type              = "weekly_restriction"
      start_day_of_week = 2 # Tuesday
      start_time_of_day = "14:00:00"
      duration_seconds  = 28800
    }
    restriction {
      type              = "weekly_restriction"
      start_day_of_week = 3 # Wednesday
      start_time_of_day = "14:00:00"
      duration_seconds  = 28800
    }
    restriction {
      type              = "weekly_restriction"
      start_day_of_week = 4 # Thursday
      start_time_of_day = "14:00:00"
      duration_seconds  = 28800
    }
    restriction {
      type              = "weekly_restriction"
      start_day_of_week = 5 # Friday
      start_time_of_day = "14:00:00"
      duration_seconds  = 28800
    }
  }

  # EMEA coverage (06:00-14:00 UTC / 7 AM - 3 PM UK)
  layer {
    name                         = "EMEA"
    start                        = var.schedule_start_time
    rotation_virtual_start       = var.schedule_start_time
    rotation_turn_length_seconds = 604800

    users = [
      pagerduty_user.users["carol"].id,
    ]

    restriction {
      type              = "weekly_restriction"
      start_day_of_week = 1
      start_time_of_day = "06:00:00"
      duration_seconds  = 28800
    }
    restriction {
      type              = "weekly_restriction"
      start_day_of_week = 2
      start_time_of_day = "06:00:00"
      duration_seconds  = 28800
    }
    restriction {
      type              = "weekly_restriction"
      start_day_of_week = 3
      start_time_of_day = "06:00:00"
      duration_seconds  = 28800
    }
    restriction {
      type              = "weekly_restriction"
      start_day_of_week = 4
      start_time_of_day = "06:00:00"
      duration_seconds  = 28800
    }
    restriction {
      type              = "weekly_restriction"
      start_day_of_week = 5
      start_time_of_day = "06:00:00"
      duration_seconds  = 28800
    }
  }

  # APAC coverage (22:00-06:00 UTC / Morning JST)
  layer {
    name                         = "APAC"
    start                        = var.schedule_start_time
    rotation_virtual_start       = var.schedule_start_time
    rotation_turn_length_seconds = 604800

    users = [
      pagerduty_user.users["david"].id,
    ]

    restriction {
      type              = "weekly_restriction"
      start_day_of_week = 1
      start_time_of_day = "22:00:00"
      duration_seconds  = 28800
    }
    restriction {
      type              = "weekly_restriction"
      start_day_of_week = 2
      start_time_of_day = "22:00:00"
      duration_seconds  = 28800
    }
    restriction {
      type              = "weekly_restriction"
      start_day_of_week = 3
      start_time_of_day = "22:00:00"
      duration_seconds  = 28800
    }
    restriction {
      type              = "weekly_restriction"
      start_day_of_week = 4
      start_time_of_day = "22:00:00"
      duration_seconds  = 28800
    }
    restriction {
      type              = "weekly_restriction"
      start_day_of_week = 5
      start_time_of_day = "22:00:00"
      duration_seconds  = 28800
    }
  }
}

# =============================================================================
# Business Hours Schedule
# =============================================================================
# Active only during business hours (9 AM - 6 PM, Monday-Friday)

resource "pagerduty_schedule" "business_hours" {
  name        = "${var.environment} - Business Hours"
  description = "Coverage during standard business hours only"
  time_zone   = var.default_timezone

  teams = [pagerduty_team.teams["backend"].id]

  layer {
    name                         = "Business Hours Coverage"
    start                        = var.schedule_start_time
    rotation_virtual_start       = var.schedule_start_time
    rotation_turn_length_seconds = 86400 # Daily rotation

    users = [
      pagerduty_user.users["david"].id,
      pagerduty_user.users["carol"].id,
    ]

    # Monday through Friday, 9 AM to 6 PM
    restriction {
      type              = "weekly_restriction"
      start_day_of_week = 1 # Monday
      start_time_of_day = "09:00:00"
      duration_seconds  = 32400 # 9 hours
    }
    restriction {
      type              = "weekly_restriction"
      start_day_of_week = 2
      start_time_of_day = "09:00:00"
      duration_seconds  = 32400
    }
    restriction {
      type              = "weekly_restriction"
      start_day_of_week = 3
      start_time_of_day = "09:00:00"
      duration_seconds  = 32400
    }
    restriction {
      type              = "weekly_restriction"
      start_day_of_week = 4
      start_time_of_day = "09:00:00"
      duration_seconds  = 32400
    }
    restriction {
      type              = "weekly_restriction"
      start_day_of_week = 5
      start_time_of_day = "09:00:00"
      duration_seconds  = 32400
    }
  }
}

# =============================================================================
# Management Escalation Schedule
# =============================================================================
# Engineering managers available for critical escalations

resource "pagerduty_schedule" "management" {
  name        = "${var.environment} - Management Escalation"
  description = "Engineering management for critical incident escalations"
  time_zone   = var.default_timezone

  teams = [pagerduty_team.leadership.id]

  layer {
    name                         = "Management Rotation"
    start                        = var.schedule_start_time
    rotation_virtual_start       = var.schedule_start_time
    rotation_turn_length_seconds = 604800 # Weekly

    users = [
      pagerduty_user.users["emma"].id,
    ]
  }
}

# =============================================================================
# Locals for Schedule References
# =============================================================================

locals {
  schedule_ids = {
    primary         = pagerduty_schedule.primary.id
    secondary       = pagerduty_schedule.secondary.id
    follow_the_sun  = pagerduty_schedule.follow_the_sun.id
    business_hours  = pagerduty_schedule.business_hours.id
    management      = pagerduty_schedule.management.id
  }
}
