# MIT License - Copyright (c) fintonlabs.com
#
# users.tf - PagerDuty User Resources
# ====================================
# This file creates user accounts in PagerDuty. Users are the foundation of
# your incident response - they're assigned to teams, schedules, and escalation policies.
#
# User Roles:
#   - admin: Full access to account settings and all resources
#   - user: Standard responder access (default)
#   - limited_user: Restricted access, cannot acknowledge/resolve incidents
#   - observer: Read-only access to incidents and services
#   - restricted_access: No default access, must be granted per-team
#
# IMPORTANT: Each user requires a unique email address. The email is used for:
#   - Login authentication
#   - Default notification channel
#   - User identification across the platform

# =============================================================================
# User Resources
# =============================================================================
# Creates users dynamically from the var.users map. This approach allows you to:
#   - Add/remove users by modifying the variable
#   - Override defaults in terraform.tfvars
#   - Maintain consistent user configuration

resource "pagerduty_user" "users" {
  for_each = var.users

  name      = each.value.name
  email     = each.value.email
  role      = each.value.role
  job_title = each.value.job_title
  time_zone = each.value.time_zone

  # Optional: Add a description for the user
  description = "Managed by Terraform - ${var.environment} environment"
}

# =============================================================================
# User Contact Methods
# =============================================================================
# Contact methods define how users receive notifications. Each user can have
# multiple contact methods (email, phone, SMS). The email contact method is
# created automatically when the user is created.
#
# Contact Method Types:
#   - email_contact_method: Email notifications
#   - phone_contact_method: Voice call notifications
#   - sms_contact_method: SMS text notifications
#   - push_notification_contact_method: Mobile app push

# Example: Add SMS contact method for users (uncomment and customize as needed)
#
# resource "pagerduty_user_contact_method" "sms" {
#   for_each = var.users
#
#   user_id      = pagerduty_user.users[each.key].id
#   type         = "sms_contact_method"
#   country_code = "+1"
#   address      = "5551234567" # Replace with actual phone numbers
#   label        = "Mobile"
# }

# =============================================================================
# User Notification Rules
# =============================================================================
# Notification rules control when and how users are notified about incidents.
# Rules are evaluated in order - the first matching rule determines notification timing.
#
# Common patterns:
#   - Immediate notification for high-urgency incidents
#   - Delayed notification for low-urgency incidents
#   - Escalating notification (email first, then SMS, then phone)

# Note: Notification rules are created automatically by PagerDuty when users are created.
# Custom notification rules can be managed via the API or UI.
# The pagerduty_user_notification_rule resource requires looking up the contact_method ID
# which is created automatically - see data sources below for how to reference them.

# Example: Look up a user's default email contact method
# data "pagerduty_user_contact_method" "email" {
#   for_each = var.users
#   user_id  = pagerduty_user.users[each.key].id
#   type     = "email_contact_method"
#   label    = "Default"
# }

# Example: Create custom notification rule (requires contact_method data source)
# resource "pagerduty_user_notification_rule" "immediate_email" {
#   for_each = var.users
#
#   user_id                = pagerduty_user.users[each.key].id
#   start_delay_in_minutes = 0
#   urgency                = "high"
#
#   contact_method {
#     type = "email_contact_method"
#     id   = data.pagerduty_user_contact_method.email[each.key].id
#   }
# }

# =============================================================================
# Locals for User References
# =============================================================================
# These locals provide convenient lookups for user IDs used elsewhere

locals {
  # Map of user keys to their IDs for easy reference
  user_ids = {
    for key, user in pagerduty_user.users : key => user.id
  }

  # List of all user IDs (useful for schedules)
  all_user_ids = values(pagerduty_user.users)[*].id
}
