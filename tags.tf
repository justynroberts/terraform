# MIT License - Copyright (c) fintonlabs.com
#
# tags.tf - Tags and Tag Assignments
# ====================================
# Tags provide a flexible way to categorize and filter PagerDuty resources.
# They can be applied to users, teams, and escalation policies.
#
# Tag Use Cases:
#   - Environment classification (production, staging, development)
#   - Geographic regions (us-east, eu-west, apac)
#   - Service tiers (tier-1, tier-2, tier-3)
#   - Compliance requirements (pci, hipaa, sox)
#   - Cost centers or business units
#
# Tag Best Practices:
#   - Use consistent naming conventions (lowercase, hyphens)
#   - Create a tag taxonomy before implementation
#   - Avoid creating too many tags (leads to confusion)
#   - Document tag meanings and usage guidelines

# =============================================================================
# Environment Tags
# =============================================================================
# Classify resources by deployment environment

resource "pagerduty_tag" "production" {
  label = "production"
}

resource "pagerduty_tag" "staging" {
  label = "staging"
}

resource "pagerduty_tag" "development" {
  label = "development"
}

# =============================================================================
# Service Tier Tags
# =============================================================================
# Classify by criticality/SLA tier

resource "pagerduty_tag" "tier_1" {
  label = "tier-1-critical"
}

resource "pagerduty_tag" "tier_2" {
  label = "tier-2-important"
}

resource "pagerduty_tag" "tier_3" {
  label = "tier-3-standard"
}

# =============================================================================
# Region Tags
# =============================================================================
# Geographic classification for follow-the-sun and regional teams

resource "pagerduty_tag" "region_americas" {
  label = "region-americas"
}

resource "pagerduty_tag" "region_emea" {
  label = "region-emea"
}

resource "pagerduty_tag" "region_apac" {
  label = "region-apac"
}

# =============================================================================
# Compliance Tags
# =============================================================================
# Tag resources subject to specific compliance requirements

resource "pagerduty_tag" "compliance_pci" {
  label = "compliance-pci"
}

resource "pagerduty_tag" "compliance_hipaa" {
  label = "compliance-hipaa"
}

resource "pagerduty_tag" "compliance_sox" {
  label = "compliance-sox"
}

# =============================================================================
# Team Function Tags
# =============================================================================
# Classify teams by function

resource "pagerduty_tag" "function_engineering" {
  label = "engineering"
}

resource "pagerduty_tag" "function_operations" {
  label = "operations"
}

resource "pagerduty_tag" "function_security" {
  label = "security"
}

# =============================================================================
# Tag Assignments - Teams
# =============================================================================
# Assign tags to teams based on their function and region

resource "pagerduty_tag_assignment" "sre_engineering" {
  tag_id      = pagerduty_tag.function_engineering.id
  entity_type = "teams"
  entity_id   = pagerduty_team.teams["sre"].id
}

resource "pagerduty_tag_assignment" "sre_operations" {
  tag_id      = pagerduty_tag.function_operations.id
  entity_type = "teams"
  entity_id   = pagerduty_team.teams["sre"].id
}

resource "pagerduty_tag_assignment" "platform_engineering" {
  tag_id      = pagerduty_tag.function_engineering.id
  entity_type = "teams"
  entity_id   = pagerduty_team.teams["platform"].id
}

resource "pagerduty_tag_assignment" "backend_engineering" {
  tag_id      = pagerduty_tag.function_engineering.id
  entity_type = "teams"
  entity_id   = pagerduty_team.teams["backend"].id
}

# =============================================================================
# Tag Assignments - Users (by region)
# =============================================================================
# Tag users based on their timezone/region

resource "pagerduty_tag_assignment" "alice_americas" {
  tag_id      = pagerduty_tag.region_americas.id
  entity_type = "users"
  entity_id   = pagerduty_user.users["alice"].id
}

resource "pagerduty_tag_assignment" "bob_americas" {
  tag_id      = pagerduty_tag.region_americas.id
  entity_type = "users"
  entity_id   = pagerduty_user.users["bob"].id
}

resource "pagerduty_tag_assignment" "carol_emea" {
  tag_id      = pagerduty_tag.region_emea.id
  entity_type = "users"
  entity_id   = pagerduty_user.users["carol"].id
}

resource "pagerduty_tag_assignment" "david_apac" {
  tag_id      = pagerduty_tag.region_apac.id
  entity_type = "users"
  entity_id   = pagerduty_user.users["david"].id
}

resource "pagerduty_tag_assignment" "emma_americas" {
  tag_id      = pagerduty_tag.region_americas.id
  entity_type = "users"
  entity_id   = pagerduty_user.users["emma"].id
}

# =============================================================================
# Tag Assignments - Escalation Policies
# =============================================================================
# Tag escalation policies by environment and tier

resource "pagerduty_tag_assignment" "primary_ep_production" {
  tag_id      = pagerduty_tag.production.id
  entity_type = "escalation_policies"
  entity_id   = pagerduty_escalation_policy.primary.id
}

resource "pagerduty_tag_assignment" "critical_ep_tier1" {
  tag_id      = pagerduty_tag.tier_1.id
  entity_type = "escalation_policies"
  entity_id   = pagerduty_escalation_policy.critical.id
}

resource "pagerduty_tag_assignment" "critical_ep_production" {
  tag_id      = pagerduty_tag.production.id
  entity_type = "escalation_policies"
  entity_id   = pagerduty_escalation_policy.critical.id
}

# =============================================================================
# Locals for Tag References
# =============================================================================

locals {
  tag_ids = {
    # Environment
    production  = pagerduty_tag.production.id
    staging     = pagerduty_tag.staging.id
    development = pagerduty_tag.development.id

    # Tiers
    tier_1 = pagerduty_tag.tier_1.id
    tier_2 = pagerduty_tag.tier_2.id
    tier_3 = pagerduty_tag.tier_3.id

    # Regions
    americas = pagerduty_tag.region_americas.id
    emea     = pagerduty_tag.region_emea.id
    apac     = pagerduty_tag.region_apac.id

    # Compliance
    pci   = pagerduty_tag.compliance_pci.id
    hipaa = pagerduty_tag.compliance_hipaa.id
    sox   = pagerduty_tag.compliance_sox.id

    # Functions
    engineering = pagerduty_tag.function_engineering.id
    operations  = pagerduty_tag.function_operations.id
    security    = pagerduty_tag.function_security.id
  }
}
