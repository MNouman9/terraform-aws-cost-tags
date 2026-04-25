terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "aws_region" {
  description = "AWS region to deploy resources into."
  type        = string
  default     = "us-east-1"
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = module.cost_tags.tags
  }
}

# ─── 3-level tag inheritance ────────────────────────────────────────────────
#
#  Level 0 (base):    Environment, Project, Team, CostCenter, OrgName, ManagedBy
#  Level 1 (org):     ComplianceLevel, DataClass  (org-wide additions)
#  Level 2 (team):    Slack, CostCode             (team additions)
#  Level 3 (resource) not used at module level here — see per-resource example below

module "cost_tags" {
  source = "../../"

  org_name    = "acme"
  environment = "prod"
  project     = "payments"
  team        = "platform-team"
  cost_center = "eng-001"

  org_tags = {
    ComplianceLevel = "pci-dss"
    DataClass       = "confidential"
  }

  team_tags = {
    Slack    = "#platform-alerts"
    CostCode = "P-2024-Q2"
  }
}

# ─── Resources inherit all tags via default_tags ────────────────────────────

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  # No tags block needed — all tags inherited from default_tags
}

# ─── Per-resource tag override ──────────────────────────────────────────────
#
# This S3 bucket's cost is charged to the security team, not the default
# platform-team cost center. Use merge() to override a single tag:

resource "aws_s3_bucket" "audit_logs" {
  bucket = "acme-prod-audit-logs"

  tags = merge(module.cost_tags.tags, {
    CostCenter = "security-team"
  })
}
