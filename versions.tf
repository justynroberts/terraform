# MIT License - Copyright (c) fintonlabs.com
#
# versions.tf - Terraform and Provider Version Constraints
# ==========================================================
# This file defines the required Terraform version and provider dependencies.
# Always pin provider versions to avoid unexpected breaking changes.

terraform {
  # Minimum Terraform version required
  # We use >= 1.0 for modern HCL features and improved state management
  required_version = ">= 1.0"

  required_providers {
    pagerduty = {
      source = "PagerDuty/pagerduty"
      # Pin to major version 3.x for stability
      # Check https://registry.terraform.io/providers/PagerDuty/pagerduty/latest
      # for the latest version and changelog
      version = "~> 3.0"
    }
  }
}

# =============================================================================
# PagerDuty Provider Configuration
# =============================================================================
# The provider authenticates using an API token. There are two token types:
#
# 1. REST API Token (recommended for automation):
#    - Created in PagerDuty: Integrations > API Access Keys > Create New API Key
#    - Set via: export PAGERDUTY_TOKEN="your-token"
#
# 2. User Token (for user-specific operations):
#    - Created in PagerDuty: User Settings > Create API User Token
#    - Set via: export PAGERDUTY_USER_TOKEN="your-user-token"
#
# SECURITY: Never hardcode tokens in Terraform files. Use environment variables
# or a secrets manager like HashiCorp Vault.
# =============================================================================

provider "pagerduty" {
  # Token is read from PAGERDUTY_TOKEN environment variable by default
  # Uncomment below to explicitly pass the token variable:
  # token = var.pagerduty_token

  # Optional: Skip credential validation during plan (useful for CI/CD)
  # skip_credentials_validation = true
}
