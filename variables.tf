# MIT License - Copyright (c) fintonlabs.com
#
# variables.tf - Input Variable Definitions
# ==========================================
# This file defines all configurable inputs for the PagerDuty infrastructure.
# Override these values in terraform.tfvars or via environment variables.
#
# Environment variable format: TF_VAR_<variable_name>
# Example: export TF_VAR_pagerduty_token="your-token"

# =============================================================================
# Authentication
# =============================================================================

variable "pagerduty_token" {
  description = "PagerDuty API token for authentication. Create at: Integrations > API Access Keys"
  type        = string
  sensitive   = true
  default     = null # Will use PAGERDUTY_TOKEN env var if not set
}

# =============================================================================
# Organization Settings
# =============================================================================

variable "default_timezone" {
  description = "Default timezone for schedules. See: https://developer.pagerduty.com/docs/1afe25e9c94cb-types#time-zone"
  type        = string
  default     = "America/New_York"
}

variable "environment" {
  description = "Environment name used as prefix for resources (e.g., prod, staging, dev)"
  type        = string
  default     = "demo"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.environment))
    error_message = "Environment must be lowercase alphanumeric with hyphens only."
  }
}

# =============================================================================
# User Configuration
# =============================================================================

variable "users" {
  description = "Map of users to create in PagerDuty"
  type = map(object({
    name     = string
    email    = string
    role     = optional(string, "user")
    job_title = optional(string, "")
    time_zone = optional(string, "America/New_York")
  }))
  default = {
    alice = {
      name      = "Alice Chen"
      email     = "alice.chen@example.com"
      role      = "user"
      job_title = "Senior SRE"
      time_zone = "America/New_York"
    }
    bob = {
      name      = "Bob Smith"
      email     = "bob.smith@example.com"
      role      = "user"
      job_title = "Platform Engineer"
      time_zone = "America/Los_Angeles"
    }
    carol = {
      name      = "Carol Williams"
      email     = "carol.williams@example.com"
      role      = "user"
      job_title = "DevOps Engineer"
      time_zone = "Europe/London"
    }
    david = {
      name      = "David Kumar"
      email     = "david.kumar@example.com"
      role      = "user"
      job_title = "Software Engineer"
      time_zone = "Asia/Tokyo"
    }
    emma = {
      name      = "Emma Garcia"
      email     = "emma.garcia@example.com"
      role      = "admin"
      job_title = "Engineering Manager"
      time_zone = "America/Chicago"
    }
  }
}

# =============================================================================
# Team Configuration
# =============================================================================

variable "teams" {
  description = "Map of teams to create"
  type = map(object({
    name        = string
    description = optional(string, "")
  }))
  default = {
    platform = {
      name        = "Platform Engineering"
      description = "Infrastructure and platform services team"
    }
    backend = {
      name        = "Backend Services"
      description = "API and backend service development team"
    }
    sre = {
      name        = "Site Reliability Engineering"
      description = "SRE team responsible for production reliability"
    }
    leadership = {
      name        = "Engineering Leadership"
      description = "Engineering managers and directors"
    }
  }
}

# =============================================================================
# Service Configuration
# =============================================================================

variable "services" {
  description = "Map of technical services to create"
  type = map(object({
    name                    = string
    description             = optional(string, "")
    escalation_policy_key   = string
    alert_creation          = optional(string, "create_alerts_and_incidents")
    auto_resolve_timeout    = optional(number, 14400)   # 4 hours in seconds
    acknowledgement_timeout = optional(number, 1800)    # 30 minutes in seconds
    urgency                 = optional(string, "high")
  }))
  default = {
    api_gateway = {
      name                  = "API Gateway"
      description           = "Main API gateway handling all external traffic"
      escalation_policy_key = "primary"
      urgency               = "high"
    }
    user_service = {
      name                  = "User Service"
      description           = "User authentication and profile management"
      escalation_policy_key = "primary"
      urgency               = "high"
    }
    payment_service = {
      name                  = "Payment Service"
      description           = "Payment processing and billing"
      escalation_policy_key = "critical"
      urgency               = "high"
    }
    notification_service = {
      name                  = "Notification Service"
      description           = "Email, SMS, and push notification delivery"
      escalation_policy_key = "secondary"
      urgency               = "low"
    }
    analytics_service = {
      name                  = "Analytics Service"
      description           = "Data analytics and reporting"
      escalation_policy_key = "secondary"
      urgency               = "low"
    }
  }
}

# =============================================================================
# Schedule Configuration
# =============================================================================

variable "schedule_rotation_length_days" {
  description = "Default rotation length in days for on-call schedules"
  type        = number
  default     = 7 # Weekly rotation
}

variable "schedule_start_time" {
  description = "Start time for schedules in RFC3339 format (date portion will be adjusted)"
  type        = string
  default     = "2024-01-01T09:00:00-05:00"
}

# =============================================================================
# Escalation Policy Configuration
# =============================================================================

variable "escalation_delay_minutes" {
  description = "Default delay in minutes before escalating to next level"
  type        = number
  default     = 10
}

variable "escalation_num_loops" {
  description = "Number of times to loop through the escalation policy before giving up"
  type        = number
  default     = 2
}

# =============================================================================
# Event Orchestration Configuration
# =============================================================================

variable "enable_event_orchestration" {
  description = "Whether to create event orchestration resources"
  type        = bool
  default     = true
}

variable "orchestration_name" {
  description = "Name for the main event orchestration"
  type        = string
  default     = "Main Event Orchestration"
}

# =============================================================================
# Incident Workflow Configuration
# =============================================================================

variable "enable_incident_workflows" {
  description = "Whether to create incident workflow resources"
  type        = bool
  default     = true
}

# =============================================================================
# Automation Actions Configuration
# =============================================================================

variable "enable_automation_actions" {
  description = "Whether to create automation action resources (requires Process Automation license)"
  type        = bool
  default     = false # Disabled by default as it requires additional licensing
}

variable "runbook_api_key" {
  description = "API key for Runbook Automation runner (required if enable_automation_actions is true)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "runbook_base_uri" {
  description = "Base URI for Runbook Automation (e.g., your-org.runbook.pagerduty.com)"
  type        = string
  default     = ""
}

# =============================================================================
# Tags / Labels
# =============================================================================

variable "tags" {
  description = "Common tags to apply to resources that support tagging"
  type        = map(string)
  default = {
    managed_by = "terraform"
    repository = "pagerduty-terraform-examples"
  }
}
