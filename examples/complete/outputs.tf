output "tags" {
  description = "Fully merged tag map (all levels)."
  value       = module.cost_tags.tags
}

output "base_tags" {
  description = "Required-schema tags only, no overrides."
  value       = module.cost_tags.base_tags
}

output "org_tags" {
  description = "Base + org-level merged tags."
  value       = module.cost_tags.org_tags
}

output "team_tags" {
  description = "Org + team-level merged tags."
  value       = module.cost_tags.team_tags
}

output "tag_keys" {
  description = "All tag key names in the final merged map."
  value       = module.cost_tags.tag_keys
}
