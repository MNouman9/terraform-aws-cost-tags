output "tags" {
  description = "Fully merged tag map (all levels combined). Plug directly into provider default_tags or resource tags blocks."
  value       = local.merged_tags
}

output "base_tags" {
  description = "Required-schema tags only (Environment, Project, Team, CostCenter, OrgName, ManagedBy). No overrides applied. Useful for auditing."
  value       = local.base_tags
}

output "org_tags" {
  description = "Level 1 merged result: base_tags merged with var.org_tags."
  value       = local.level1_tags
}

output "team_tags" {
  description = "Level 2 merged result: org_tags merged with var.team_tags."
  value       = local.level2_tags
}

output "tag_keys" {
  description = "Sorted list of all tag keys present in the final merged map. Use for auditing or Sentinel mock generation."
  value       = sort(keys(local.merged_tags))
}
