# MIT License - Copyright (c) fintonlabs.com
#
# rulesets.tf - Event Rules and Rulesets (Legacy)
# =================================================
# Rulesets provide event routing and transformation before Event Orchestration
# existed. While Event Orchestration is now preferred, Rulesets are still
# widely used and supported.
#
# MIGRATION NOTE:
#   PagerDuty recommends migrating to Event Orchestration for new implementations.
#   See event_orchestrations.tf for the modern approach.
#
# Ruleset Hierarchy:
#   1. Global Rulesets: Process events before service-level rules
#   2. Service Event Rules: Process events at the service level
#
# Rule Capabilities:
#   - Route events to services
#   - Set severity/priority
#   - Suppress/drop events
#   - Extract and transform fields
#   - Add annotations
#   - Set deduplication keys

# =============================================================================
# Global Ruleset
# =============================================================================
# Processes all incoming events before service routing

resource "pagerduty_ruleset" "global" {
  count = var.enable_rulesets ? 1 : 0

  name = "${var.environment} - Global Event Rules"

  team {
    id = pagerduty_team.teams["sre"].id
  }
}

# =============================================================================
# Ruleset Rules - Event Routing
# =============================================================================

# Rule 1: Route critical payment alerts with high priority
resource "pagerduty_ruleset_rule" "payment_critical" {
  ruleset  = pagerduty_ruleset.global[0].id
  count    = var.enable_rulesets ? 1 : 0
  position = 0

  conditions {
    operator = "and"

    subconditions {
      operator = "contains"
      parameter {
        path  = "payload.source"
        value = "payment"
      }
    }

    subconditions {
      operator = "contains"
      parameter {
        path  = "payload.severity"
        value = "critical"
      }
    }
  }

  actions {
    route {
      value = pagerduty_service.services["payment_service"].id
    }

    severity {
      value = "critical"
    }

    priority {
      value = data.pagerduty_priority.p1.id
    }

    annotate {
      value = "Critical payment alert - immediate attention required"
    }
  }
}

# Rule 2: Route database alerts
resource "pagerduty_ruleset_rule" "database_alerts" {
  ruleset  = pagerduty_ruleset.global[0].id
  count    = var.enable_rulesets ? 1 : 0
  position = 1

  conditions {
    operator = "or"

    subconditions {
      operator = "contains"
      parameter {
        path  = "payload.source"
        value = "database"
      }
    }

    subconditions {
      operator = "contains"
      parameter {
        path  = "payload.source"
        value = "postgres"
      }
    }

    subconditions {
      operator = "contains"
      parameter {
        path  = "payload.source"
        value = "mysql"
      }
    }
  }

  actions {
    route {
      value = pagerduty_service.database_primary.id
    }

    severity {
      value = "critical"
    }
  }
}

# Rule 3: Suppress test/development alerts
resource "pagerduty_ruleset_rule" "suppress_test" {
  ruleset  = pagerduty_ruleset.global[0].id
  count    = var.enable_rulesets ? 1 : 0
  position = 2

  conditions {
    operator = "or"

    subconditions {
      operator = "contains"
      parameter {
        path  = "payload.source"
        value = "test"
      }
    }

    subconditions {
      operator = "contains"
      parameter {
        path  = "payload.source"
        value = "dev"
      }
    }

    subconditions {
      operator = "equals"
      parameter {
        path  = "payload.custom_details.environment"
        value = "development"
      }
    }
  }

  actions {
    suppress {
      value = true
    }
  }
}

# Rule 4: Route API gateway alerts
resource "pagerduty_ruleset_rule" "api_gateway" {
  ruleset  = pagerduty_ruleset.global[0].id
  count    = var.enable_rulesets ? 1 : 0
  position = 3

  conditions {
    operator = "or"

    subconditions {
      operator = "contains"
      parameter {
        path  = "payload.source"
        value = "api-gateway"
      }
    }

    subconditions {
      operator = "contains"
      parameter {
        path  = "payload.source"
        value = "kong"
      }
    }

    subconditions {
      operator = "contains"
      parameter {
        path  = "payload.source"
        value = "nginx"
      }
    }
  }

  actions {
    route {
      value = pagerduty_service.services["api_gateway"].id
    }
  }
}

# Rule 5: Set low priority for warning-level alerts
resource "pagerduty_ruleset_rule" "warning_low_priority" {
  ruleset  = pagerduty_ruleset.global[0].id
  count    = var.enable_rulesets ? 1 : 0
  position = 4

  conditions {
    operator = "and"

    subconditions {
      operator = "equals"
      parameter {
        path  = "payload.severity"
        value = "warning"
      }
    }
  }

  actions {
    severity {
      value = "warning"
    }

    priority {
      value = data.pagerduty_priority.p4.id
    }
  }
}

# Rule 6: Catch-all rule - route to default service
resource "pagerduty_ruleset_rule" "catch_all" {
  ruleset  = pagerduty_ruleset.global[0].id
  count    = var.enable_rulesets ? 1 : 0
  position = 99

  # No conditions - matches everything not caught above
  conditions {
    operator = "and"
    # Empty conditions match all events
  }

  actions {
    route {
      value = pagerduty_service.services["api_gateway"].id
    }

    severity {
      value = "info"
    }

    annotate {
      value = "Routed via catch-all rule - review routing configuration"
    }
  }
}

# =============================================================================
# Service Event Rules (Per-Service Rules) - COMMENTED
# =============================================================================
# Service event rules use payload.* paths (not event.*)
# Uncomment and customize as needed
#
# resource "pagerduty_service_event_rule" "api_suppress_4xx" {
#   service  = pagerduty_service.services["api_gateway"].id
#   position = 0
#
#   conditions {
#     operator = "and"
#
#     subconditions {
#       operator = "contains"
#       parameter {
#         path  = "payload.custom_details.status_code"
#         value = "4"
#       }
#     }
#   }
#
#   actions {
#     suppress {
#       value = true
#     }
#   }
# }

# =============================================================================
# Locals for Ruleset References
# =============================================================================

locals {
  ruleset_ids = var.enable_rulesets ? {
    global = pagerduty_ruleset.global[0].id
  } : {}

  ruleset_rule_ids = var.enable_rulesets ? {
    payment_critical     = pagerduty_ruleset_rule.payment_critical[0].id
    database_alerts      = pagerduty_ruleset_rule.database_alerts[0].id
    suppress_test        = pagerduty_ruleset_rule.suppress_test[0].id
    api_gateway          = pagerduty_ruleset_rule.api_gateway[0].id
    warning_low_priority = pagerduty_ruleset_rule.warning_low_priority[0].id
    catch_all            = pagerduty_ruleset_rule.catch_all[0].id
  } : {}
}

# =============================================================================
# Migration Guide: Rulesets to Event Orchestration
# =============================================================================
#
# Event Orchestration provides several advantages over Rulesets:
#   - More intuitive UI for building rules
#   - Better support for complex conditions
#   - Cache variables for cross-event state
#   - Service-level orchestrations with more actions
#   - Better integration with incident workflows
#
# Migration Steps:
# 1. Document current ruleset logic
# 2. Create equivalent orchestration rules in event_orchestrations.tf
# 3. Test with sample events
# 4. Migrate event sources to orchestration routing key
# 5. Monitor for any missed events
# 6. Disable/remove old rulesets after verification
#
# Both systems can coexist during migration.
