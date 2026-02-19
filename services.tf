# MIT License - Copyright (c) fintonlabs.com
#
# services.tf - PagerDuty Service Resources
# ==========================================
# Services represent the components of your infrastructure that can experience
# incidents. Each service has an escalation policy and can receive events from
# various integrations (monitoring tools, custom applications, etc.).
#
# Service Configuration:
#   - escalation_policy: Required - defines who gets notified
#   - alert_creation: How alerts are grouped into incidents
#   - auto_resolve_timeout: Auto-resolve after X seconds if no activity
#   - acknowledgement_timeout: Return to triggered state if not resolved
#
# Alert Creation Modes:
#   - create_alerts_and_incidents: Each alert creates an incident (default)
#   - create_incidents: Alerts are grouped into a single incident
#
# Urgency Levels:
#   - high: Immediate notification per user's high-urgency rules
#   - low: Notification per user's low-urgency rules (often delayed)
#   - severity_based: Urgency determined by incoming event severity
#   - use_support_hours: High during support hours, low otherwise

# =============================================================================
# Service Resources
# =============================================================================
# Creates services dynamically from the var.services map

resource "pagerduty_service" "services" {
  for_each = var.services

  name        = "${var.environment} - ${each.value.name}"
  description = each.value.description

  # Link to appropriate escalation policy
  escalation_policy = local.escalation_policy_ids[each.value.escalation_policy_key]

  # Alert behavior
  alert_creation = each.value.alert_creation

  # Timeout settings (in seconds)
  # Set to null to disable timeouts
  auto_resolve_timeout    = each.value.auto_resolve_timeout
  acknowledgement_timeout = each.value.acknowledgement_timeout

  # Incident urgency configuration
  incident_urgency_rule {
    type    = "constant"
    urgency = each.value.urgency
  }
}

# =============================================================================
# Service Integrations - Events API v2
# =============================================================================
# Events API v2 is the recommended integration for custom applications.
# It provides a routing key (integration key) that you use to send events.
#
# After creation, find the routing key in outputs or the PagerDuty UI.
# Send events via: https://events.pagerduty.com/v2/enqueue

resource "pagerduty_service_integration" "events_api_v2" {
  for_each = var.services

  name    = "Events API v2"
  type    = "events_api_v2_inbound_integration"
  service = pagerduty_service.services[each.key].id
}

# =============================================================================
# Service Integrations - Email Integration
# =============================================================================
# Email integrations allow services to receive alerts via email.
# Useful for legacy systems that only support email notifications.
#
# The integration creates a unique email address like:
# <service-key>@<subdomain>.pagerduty.com

resource "pagerduty_service_integration" "email" {
  for_each = var.services

  name    = "Email Integration"
  type    = "generic_email_inbound_integration"
  service = pagerduty_service.services[each.key].id

  # Email parsing mode (optional)
  # integration_email = "custom-alias@your-subdomain.pagerduty.com"
}

# =============================================================================
# Additional Service Examples with Specific Configurations
# =============================================================================

# High-criticality service with support hours urgency
resource "pagerduty_service" "database_primary" {
  name              = "${var.environment} - Primary Database"
  description       = "Primary PostgreSQL database cluster"
  escalation_policy = pagerduty_escalation_policy.critical.id

  alert_creation          = "create_alerts_and_incidents"
  auto_resolve_timeout    = null # Never auto-resolve database alerts
  acknowledgement_timeout = 600  # 10 minutes

  # Use support hours to determine urgency
  incident_urgency_rule {
    type = "use_support_hours"

    during_support_hours {
      type    = "constant"
      urgency = "high"
    }

    outside_support_hours {
      type    = "constant"
      urgency = "high" # Still high for database - it's critical
    }
  }

  # Define support hours
  support_hours {
    type         = "fixed_time_per_day"
    time_zone    = var.default_timezone
    start_time   = "09:00:00"
    end_time     = "18:00:00"
    days_of_week = [1, 2, 3, 4, 5] # Monday through Friday
  }
}

# Datadog integration example
resource "pagerduty_service_integration" "datadog_database" {
  name    = "Datadog"
  service = pagerduty_service.database_primary.id
  vendor  = data.pagerduty_vendor.datadog.id
}

# Prometheus/Alertmanager integration example
resource "pagerduty_service_integration" "prometheus_database" {
  name    = "Prometheus Alertmanager"
  service = pagerduty_service.database_primary.id
  vendor  = data.pagerduty_vendor.prometheus.id
}

# =============================================================================
# Vendor Data Sources
# =============================================================================
# PagerDuty has pre-built integrations for common monitoring tools.
# Use data sources to look up vendor IDs for these integrations.

data "pagerduty_vendor" "datadog" {
  name = "Datadog"
}

data "pagerduty_vendor" "prometheus" {
  name = "Prometheus"
}

data "pagerduty_vendor" "cloudwatch" {
  name = "Amazon CloudWatch"
}

data "pagerduty_vendor" "splunk" {
  name = "Splunk"
}

# =============================================================================
# Business Services
# =============================================================================
# Business services represent user-facing applications and are used for:
#   - Service dependencies (technical services support business services)
#   - Status pages
#   - Impact analysis
#
# They don't have escalation policies - they're for visualization and reporting.

resource "pagerduty_business_service" "ecommerce_platform" {
  name        = "${var.environment} - E-Commerce Platform"
  description = "Customer-facing e-commerce application"
  team        = pagerduty_team.teams["platform"].id
}

resource "pagerduty_business_service" "mobile_app" {
  name        = "${var.environment} - Mobile Application"
  description = "iOS and Android mobile applications"
  team        = pagerduty_team.teams["backend"].id
}

# =============================================================================
# Service Dependencies
# =============================================================================
# Define relationships between technical and business services.
# This enables impact analysis: when a technical service has an incident,
# you can see which business services are affected.

resource "pagerduty_service_dependency" "ecommerce_api" {
  dependency {
    dependent_service {
      id   = pagerduty_business_service.ecommerce_platform.id
      type = "business_service"
    }
    supporting_service {
      id   = pagerduty_service.services["api_gateway"].id
      type = "service"
    }
  }
}

resource "pagerduty_service_dependency" "ecommerce_payment" {
  dependency {
    dependent_service {
      id   = pagerduty_business_service.ecommerce_platform.id
      type = "business_service"
    }
    supporting_service {
      id   = pagerduty_service.services["payment_service"].id
      type = "service"
    }
  }
}

resource "pagerduty_service_dependency" "ecommerce_user" {
  dependency {
    dependent_service {
      id   = pagerduty_business_service.ecommerce_platform.id
      type = "business_service"
    }
    supporting_service {
      id   = pagerduty_service.services["user_service"].id
      type = "service"
    }
  }
}

resource "pagerduty_service_dependency" "ecommerce_database" {
  dependency {
    dependent_service {
      id   = pagerduty_business_service.ecommerce_platform.id
      type = "business_service"
    }
    supporting_service {
      id   = pagerduty_service.database_primary.id
      type = "service"
    }
  }
}

# =============================================================================
# Locals for Service References
# =============================================================================

locals {
  service_ids = {
    for key, service in pagerduty_service.services : key => service.id
  }

  # Map of service integration keys (routing keys) for Events API v2
  service_integration_keys = {
    for key, integration in pagerduty_service_integration.events_api_v2 :
    key => integration.integration_key
  }

  # All services including the static one
  all_service_ids = merge(
    local.service_ids,
    {
      database_primary = pagerduty_service.database_primary.id
    }
  )
}
