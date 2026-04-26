# Changelog

All notable changes to this module will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-04-25

### Added

- `main.tf` — locals-only 3-level tag merge (org → team → resource). Zero AWS resources provisioned.
- `variables.tf` — five required inputs (`org_name`, `environment`, `project`, `team`, `cost_center`) with validation blocks. Five optional inputs (`managed_by`, `org_tags`, `team_tags`, `resource_tags`, `additional_tags`). All `map(string)` inputs use `nullable = false` to prevent null breaking `merge()`.
- `outputs.tf` — five outputs: `tags`, `base_tags`, `org_tags`, `team_tags`, `tag_keys`.
- `versions.tf` — requires Terraform `>= 1.6.0`.
- `examples/minimal/` — five required inputs with `default_tags` wiring.
- `examples/complete/` — full 3-level inheritance with per-resource override and `Makefile`.
- `sentinel/policies/require-cost-tags.sentinel` — `hard-mandatory` policy that blocks any AWS create/update missing one of: `Environment`, `Project`, `Team`, `CostCenter`, `ManagedBy`.
- `sentinel/mocks/` — pass and fail mock data covering six resource types.
- `sentinel/policies/test/require-cost-tags/` — unit test cases for both pass and fail variants.
- `sentinel/sentinel.hcl` — policy set declaration.
- `sentinel/README.md` — local CLI workflow, unit test instructions, CI integration example.
- `README.md` — usage patterns, inputs/outputs reference, Sentinel guide, AWS console cost-viewing guide (Cost Explorer, Budgets, CUR).
- `.terraform-docs.yml` — terraform-docs configuration for README generation.
- `LICENSE` — Apache 2.0.

[1.0.0]: https://github.com/YOUR_ORG/terraform-aws-cost-tags/releases/tag/v1.0.0
