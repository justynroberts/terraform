# MIT License - Copyright (c) fintonlabs.com
#
# event_orchestrations.tf - Event Orchestration Resources
# =========================================================
# Event Orchestration is PagerDuty's powerful event processing engine.
# It allows you to route, transform, and enrich events before they create incidents.
#
# Orchestration Types:
#   1. Global Orchestration: Routes events to services based on event content
#   2. Service Orchestration: Processes events within a specific service
#   3. Unrouted Orchestration: Catches events that don't match any routing rules
#
# Common Use Cases:
#   - Route events to different services based on source or content
#   - Suppress noisy/duplicate alerts
#   - Enrich events with additional context
#   - Set severity/priority based on event content
#   - Trigger automation or webhooks
#
# IMPORTANT: Event Orchestration requires Events API v2 integration keys,
# not service integration keys.

# =============================================================================
# Global Event Orchestration
# =============================================================================
# The main orchestration that receives all events and routes them to services.
# Events are sent to the orchestration's routing key, then rules determine
# which service receives each event.

resource "pagerduty_event_orchestration" "main" {
  count = var.enable_event_orchestration ? 1 : 0

  name        = var.orchestration_name
  description = "Main event orchestration for ${var.environment} environment"
  team        = pagerduty_team.teams["sre"].id
}

# =============================================================================
# Global Orchestration Router
# =============================================================================
# Routes events to different services based on event content.
# Events not matching any rule go to the catch_all destination.

resource "pagerduty_event_orchestration_router" "main" {
  count = var.enable_event_orchestration ? 1 : 0

  event_orchestration = pagerduty_event_orchestration.main[0].id

  # Define routing rules
  set {
    id = "start"

    # Rule 1: Route payment-related events to Payment Service
    rule {
      label = "Payment Events"

      condition {
        expression = "event.source matches part 'payment'"
      }
      condition {
        expression = "event.custom_details.service matches 'payment'"
      }

      actions {
        route_to = pagerduty_service.services["payment_service"].id
      }
    }

    # Rule 2: Route API errors to API Gateway service
    rule {
      label = "API Gateway Events"

      condition {
        expression = "event.source matches part 'api-gateway'"
      }
      condition {
        expression = "event.custom_details.component matches 'gateway'"
      }

      actions {
        route_to = pagerduty_service.services["api_gateway"].id
      }
    }

    # Rule 3: Route user/auth events to User Service
    rule {
      label = "User Service Events"

      condition {
        expression = "event.source matches part 'auth'"
      }
      condition {
        expression = "event.source matches part 'user'"
      }
      condition {
        expression = "event.custom_details.service matches 'user'"
      }

      actions {
        route_to = pagerduty_service.services["user_service"].id
      }
    }

    # Rule 4: Route database events to Database service
    rule {
      label = "Database Events"

      condition {
        expression = "event.source matches part 'database'"
      }
      condition {
        expression = "event.source matches part 'postgres'"
      }
      condition {
        expression = "event.source matches part 'mysql'"
      }

      actions {
        route_to = pagerduty_service.database_primary.id
      }
    }

    # Rule 5: Route notification events to Notification Service
    rule {
      label = "Notification Events"

      condition {
        expression = "event.source matches part 'notification'"
      }
      condition {
        expression = "event.source matches part 'email'"
      }
      condition {
        expression = "event.source matches part 'sms'"
      }

      actions {
        route_to = pagerduty_service.services["notification_service"].id
      }
    }
  }

  # Default destination for events not matching any rule
  catch_all {
    actions {
      route_to = pagerduty_service.services["api_gateway"].id
    }
  }
}

# =============================================================================
# Service Orchestration - API Gateway
# =============================================================================
# Processes events for a specific service. Use this for:
#   - Setting severity based on error codes
#   - Suppressing known/expected alerts
#   - Adding annotations and context
#   - Triggering automation

resource "pagerduty_event_orchestration_service" "api_gateway" {
  count = var.enable_event_orchestration ? 1 : 0

  service                                = pagerduty_service.services["api_gateway"].id
  enable_event_orchestration_for_service = true

  set {
    id = "start"

    # Rule 1: Suppress 4xx errors during maintenance windows
    rule {
      label = "Suppress 4xx During Maintenance"

      condition {
        expression = "event.custom_details.status_code matches regex '^4[0-9]{2}$'"
      }
      condition {
        expression = "event.custom_details.maintenance == 'true'"
      }

      actions {
        suppress = true
      }
    }

    # Rule 2: Set critical severity for 5xx errors
    rule {
      label = "Critical 5xx Errors"

      condition {
        expression = "event.custom_details.status_code matches regex '^5[0-9]{2}$'"
      }

      actions {
        severity = "critical"

        # Add helpful annotation
        annotate = "Server error detected. Check application logs and recent deployments."

        # Set priority (requires priorities to be enabled)
        # priority = data.pagerduty_priority.p1.id
      }
    }

    # Rule 3: Set warning severity for high latency
    rule {
      label = "High Latency Warning"

      condition {
        expression = "event.custom_details.latency_ms > 5000"
      }

      actions {
        severity = "warning"
        annotate = "High latency detected. Response time exceeded 5 seconds."
      }
    }

    # Rule 4: Deduplicate frequent alerts (same source within 5 minutes)
    rule {
      label = "Deduplicate Frequent Alerts"

      condition {
        expression = "event.custom_details.dedup_key != ''"
      }

      actions {
        # Use custom dedup key if provided
        event_action = "trigger"
      }
    }
  }

  # Catch-all for unmatched events
  catch_all {
    actions {
      severity = "info" # Default to info severity
    }
  }
}

# =============================================================================
# Service Orchestration - Payment Service (Critical)
# =============================================================================
# More aggressive rules for critical payment processing

resource "pagerduty_event_orchestration_service" "payment" {
  count = var.enable_event_orchestration ? 1 : 0

  service                                = pagerduty_service.services["payment_service"].id
  enable_event_orchestration_for_service = true

  set {
    id = "start"

    # Rule 1: Critical - Payment failures
    rule {
      label = "Payment Failures - Critical"

      condition {
        expression = "event.summary matches part 'payment failed'"
      }
      condition {
        expression = "event.custom_details.error_type matches 'payment_failure'"
      }

      actions {
        severity = "critical"
        annotate = "PAYMENT FAILURE: Immediate investigation required. Check payment gateway status and recent changes."

        # Trigger a webhook for automated runbook
        # automation_action {
        #   name = "Payment Failure Runbook"
        #   url  = "https://automation.example.com/webhooks/payment-failure"
        #   auto_send = true
        # }
      }
    }

    # Rule 2: Warning - Payment delays
    rule {
      label = "Payment Delays"

      condition {
        expression = "event.custom_details.processing_time_ms > 10000"
      }

      actions {
        severity = "warning"
        annotate = "Payment processing exceeded 10 second threshold."
      }
    }

    # Rule 3: Suppress test transactions
    rule {
      label = "Suppress Test Transactions"

      condition {
        expression = "event.custom_details.environment matches 'test'"
      }
      condition {
        expression = "event.custom_details.transaction_type matches 'test'"
      }

      actions {
        suppress = true
      }
    }
  }

  catch_all {
    actions {
      severity = "warning" # Payment events default to warning
    }
  }
}

# =============================================================================
# Global Orchestration - Unrouted Events
# =============================================================================
# Handle events that don't match any routing rules.
# These events would otherwise be lost.

resource "pagerduty_event_orchestration_unrouted" "main" {
  count = var.enable_event_orchestration ? 1 : 0

  event_orchestration = pagerduty_event_orchestration.main[0].id

  set {
    id = "start"

    # Rule 1: Alert on unrouted critical events
    rule {
      label = "Unrouted Critical Events"

      condition {
        expression = "event.severity matches 'critical'"
      }

      actions {
        severity = "critical"
        annotate = "UNROUTED EVENT: This critical event did not match any routing rules. Please review orchestration configuration."

        # Extract relevant fields for debugging
        extraction {
          target   = "event.custom_details.original_source"
          source   = "event.source"
        }
      }
    }

    # Rule 2: Log unrouted events for analysis
    rule {
      label = "Log All Unrouted"

      # No conditions - matches everything not caught above
      actions {
        severity = "info"
        annotate = "Unrouted event - review routing rules if this event should have been routed to a service."
      }
    }
  }

  catch_all {
    actions {
      severity = "info"
    }
  }
}

# =============================================================================
# Locals for Orchestration References
# =============================================================================

locals {
  orchestration_id = var.enable_event_orchestration ? pagerduty_event_orchestration.main[0].id : null

  # Orchestration routing key for sending events
  orchestration_routing_key = var.enable_event_orchestration ? pagerduty_event_orchestration.main[0].integration[0].id : null
}
