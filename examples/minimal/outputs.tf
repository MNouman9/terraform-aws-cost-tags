output "tags" {
  description = "Final merged tag map applied via default_tags."
  value       = module.cost_tags.tags
}

output "tag_keys" {
  description = "All tag key names in the merged map."
  value       = module.cost_tags.tag_keys
}
