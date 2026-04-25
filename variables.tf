variable "org_name" {
  description = "Organisation identifier used as the top-level tag hierarchy label."
  type        = string

  validation {
    condition     = length(trimspace(var.org_name)) > 0
    error_message = "org_name must not be empty or whitespace-only."
  }
}

variable "environment" {
  description = "Deployment environment. Must be one of: dev, sit, staging, prod."
  type        = string

  validation {
    condition     = contains(["dev", "sit", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, sit, staging, prod."
  }
}

variable "project" {
  description = "Project or product name used for cost attribution."
  type        = string

  validation {
    condition     = length(trimspace(var.project)) > 0
    error_message = "project must not be empty or whitespace-only."
  }
}

variable "team" {
  description = "Owning team name (e.g. platform-team, data-team)."
  type        = string

  validation {
    condition     = length(trimspace(var.team)) > 0
    error_message = "team must not be empty or whitespace-only."
  }
}

variable "cost_center" {
  description = "FinOps cost center code used for billing attribution (e.g. eng-001)."
  type        = string

  validation {
    condition     = length(trimspace(var.cost_center)) > 0
    error_message = "cost_center must not be empty or whitespace-only."
  }
}

variable "managed_by" {
  description = "Value for the ManagedBy tag. Identifies the provisioning tool."
  type        = string
  default     = "terraform"
}

variable "org_tags" {
  description = "Organisation-wide base tags. Merged over the required schema. Right side wins on key collision."
  type        = map(string)
  default     = {}
}

variable "team_tags" {
  description = "Team-level tags. Merged over org_tags. Right side wins on key collision."
  type        = map(string)
  default     = {}
}

variable "resource_tags" {
  description = "Resource-specific tags. Merged over team_tags. Highest priority among the named levels."
  type        = map(string)
  default     = {}
}

variable "additional_tags" {
  description = "Escape hatch for one-off tags that do not fit the hierarchy. Applied last — highest priority of all."
  type        = map(string)
  default     = {}
}
