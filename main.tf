locals {
  base_tags = {
    Environment = var.environment
    Project     = var.project
    Team        = var.team
    CostCenter  = var.cost_center
    OrgName     = var.org_name
    ManagedBy   = var.managed_by
  }

  level1_tags = merge(local.base_tags, var.org_tags)
  level2_tags = merge(local.level1_tags, var.team_tags)
  level3_tags = merge(local.level2_tags, var.resource_tags)
  merged_tags = merge(local.level3_tags, var.additional_tags)
}
