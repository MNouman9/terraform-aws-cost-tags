# terraform-aws-cost-tags Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and publish a plug-and-play Terraform module that outputs a 3-level inherited cost allocation tag map for any AWS project, with a Sentinel CLI policy that enforces required tags on all AWS resources in the plan.

**Architecture:** The root module is locals-only (zero AWS resources) — it takes 5 required inputs plus 4 optional override maps and merges them in priority order (base → org → team → resource → additional). Outputs are consumed via `provider default_tags` or directly on resource `tags` blocks. A standalone `sentinel/` directory holds the enforcement policy, mock data, and test cases that run fully offline via `sentinel test`.

**Tech Stack:** Terraform >= 1.6.0, AWS provider ~> 5.0 (examples only), Sentinel CLI, terraform-docs, Make

---

## File Map

| File | Responsibility |
|---|---|
| `versions.tf` | `required_version` constraint only — no provider block |
| `variables.tf` | All 10 input variables with `validation` blocks |
| `main.tf` | `locals` merge chain — zero resource blocks |
| `outputs.tf` | 5 output values at each inheritance level |
| `examples/minimal/main.tf` | Minimal usage with `default_tags` |
| `examples/minimal/outputs.tf` | Expose `module.cost_tags.tags` for inspection |
| `examples/complete/main.tf` | Full 3-level usage + per-resource override |
| `examples/complete/outputs.tf` | Expose all tag level outputs |
| `examples/complete/Makefile` | `lint`, `validate`, `plan`, `sentinel`, `test` targets |
| `sentinel/policies/require-cost-tags.sentinel` | Hard-mandatory tagging enforcement policy |
| `sentinel/mocks/mock-tfplan-pass.sentinel` | 6 AWS resource types with all required tags |
| `sentinel/mocks/mock-tfplan-fail.sentinel` | 6 AWS resource types missing various required tags |
| `sentinel/test/require-cost-tags/pass.hcl` | Test case asserting `main = true` |
| `sentinel/test/require-cost-tags/fail.hcl` | Test case asserting `main = false` |
| `sentinel/sentinel.hcl` | Policy set with `hard-mandatory` enforcement |
| `sentinel/README.md` | Local CLI usage instructions |
| `.terraform-docs.yml` | terraform-docs formatter config |
| `README.md` | Full module docs including AWS console cost guide |
| `CHANGELOG.md` | Version history starting at 1.0.0 |
| `LICENSE` | Apache 2.0 |
| `.gitignore` | Terraform + OS ignores |

---

## Task 1: Scaffold directory structure

**Files:**
- Create: `versions.tf`
- Create: `.gitignore`
- Create: `LICENSE`

- [ ] **Step 1: Create all required directories**

```bash
mkdir -p examples/minimal examples/complete
mkdir -p sentinel/policies sentinel/mocks sentinel/test/require-cost-tags
mkdir -p docs/superpowers/specs docs/superpowers/plans
```

- [ ] **Step 2: Write `.gitignore`**

Create `.gitignore`:

```gitignore
# Terraform
.terraform/
.terraform.lock.hcl
*.tfstate
*.tfstate.backup
*.tfplan
tfplan.binary
tfplan.json
override.tf
override.tf.json
*_override.tf
*_override.tf.json
.terraformrc
terraform.rc

# terraform-docs
# (README.md is committed — do not ignore it)

# OS
.DS_Store
Thumbs.db
```

- [ ] **Step 3: Write `versions.tf`**

Create `versions.tf`:

```hcl
terraform {
  required_version = ">= 1.6.0"
}
```

- [ ] **Step 4: Write `LICENSE`**

Create `LICENSE` with Apache 2.0 text:

```
                                 Apache License
                           Version 2.0, January 2004
                        http://www.apache.org/licenses/

   TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

   1. Definitions.

      "License" shall mean the terms and conditions for use, reproduction,
      and distribution as defined by Sections 1 through 9 of this document.

      "Licensor" shall mean the copyright owner or entity authorized by
      the copyright owner that is granting the License.

      "Legal Entity" shall mean the union of the acting entity and all
      other entities that control, are controlled by, or are in common
      control with that entity. For the purposes of this definition,
      "control" means (i) the power, direct or indirect, to cause the
      direction or management of such entity, whether by contract or
      otherwise, or (ii) ownership of fifty percent (50%) or more of the
      outstanding shares, or (iii) beneficial ownership of such entity.

      "You" (or "Your") shall mean an individual or Legal Entity
      exercising permissions granted by this License.

      "Source" form shall mean the preferred form for making modifications,
      including but not limited to software source code, documentation
      source, and configuration files.

      "Object" form shall mean any form resulting from mechanical
      transformation or translation of a Source form, including but
      not limited to compiled object code, generated documentation,
      and conversions to other media types.

      "Work" shall mean the work of authorship made available under
      the License, as indicated by a copyright notice that is included in
      or attached to the work (an example is provided in the Appendix below).

      "Derivative Works" shall mean any work, whether in Source or Object
      form, that is based on (or derived from) the Work and for which the
      editorial revisions, annotations, elaborations, or other modifications
      represent, as a whole, an original work of authorship. For the purposes
      of this License, Derivative Works shall not include works that remain
      separable from, or merely link (or bind by name) to the interfaces of,
      the Work and Derivative Works thereof.

      "Contribution" shall mean, as submitted to the Licensor for inclusion
      in the Work by the copyright owner or by an individual or Legal Entity
      authorized to submit on behalf of the copyright owner. For the purposes
      of this definition, "submitted" means any form of electronic, verbal,
      or written communication sent to the Licensor or its representatives,
      including but not limited to communication on electronic mailing lists,
      source code control systems, and issue tracking systems that are managed
      by, or on behalf of, the Licensor for the purpose of tracking and managing
      Contributions to the Work, but excluding communication that is
      conspicuously marked or designated in writing by the copyright owner
      as "Not a Contribution."

      "Contributor" shall mean Licensor and any Legal Entity on behalf of
      whom a Contribution has been received by the Licensor and included
      within the Work.

   2. Grant of Copyright License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      copyright license to reproduce, prepare Derivative Works of,
      publicly display, publicly perform, sublicense, and distribute the
      Work and such Derivative Works in Source or Object form.

   3. Grant of Patent License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      (except as stated in this section) patent license to make, have made,
      use, offer to sell, sell, import, and otherwise transfer the Work,
      where such license applies only to those patent claims licensable
      by such Contributor that are necessarily infringed by their
      Contribution(s) alone or by the combination of their Contribution(s)
      with the Work to which such Contribution(s) was submitted. If You
      institute patent litigation against any entity (including a cross-claim
      or counterclaim in a lawsuit) alleging that the Work or any Work
      incorporated within the Work constitutes direct or contributory
      patent infringement, then any patent licenses granted to You under
      this License for that Work shall terminate as of the date such
      litigation is filed.

   4. Redistribution. You may reproduce and distribute copies of the
      Work or Derivative Works thereof in any medium, with or without
      modifications, and in Source or Object form, provided that You
      meet the following conditions:

      (a) You must give any other recipients of the Work or Derivative
          Works a copy of this License; and

      (b) You must cause any modified files to carry prominent notices
          stating that You changed the files; and

      (c) You must retain, in all Source form of the Derivative Works
          that You distribute, all copyright, patent, trademark, and
          attribution notices from the Source form of the Work,
          excluding those notices that do not pertain to any part of
          the Derivative Works; and

      (d) If the Work includes a "NOTICE" text file as part of its
          distribution, You must include a readable copy of the
          attribution notices contained within such NOTICE file, in
          at least one of the following places: within a NOTICE text
          file distributed as part of the Derivative Works; within
          the Source form or documentation, if provided along with the
          Derivative Works; or, within a display generated by the
          Derivative Works, if and wherever such third-party notices
          normally appear. The contents of the NOTICE file are for
          informational purposes only and do not modify the License.
          You may add Your own attribution notices within Derivative
          Works that You distribute, alongside or in addition to the
          NOTICE text from the Work, provided that such additional
          attribution notices cannot be construed as modifying the License.

      You may add Your own license statement for Your modifications and
      may provide additional grant of rights to use, copy, modify, merge,
      publish, distribute, sublicense, and/or sell copies of Your
      modifications, or for such Derivative Works as a whole, under the
      terms and conditions of this License, if Your distribution includes
      all of the elements necessary to produce the resultant executable.

   5. Submission of Contributions. Unless You explicitly state otherwise,
      any Contribution intentionally submitted for inclusion in the Work
      by You to the Licensor shall be under the terms and conditions of
      this License, without any additional terms or conditions.
      Notwithstanding the above, nothing herein shall supersede or modify
      the terms of any separate license agreement you may have executed
      with Licensor regarding such Contributions.

   6. Trademarks. This License does not grant permission to use the trade
      names, trademarks, service marks, or product names of the Licensor,
      except as required for reasonable and customary use in describing the
      origin of the Work and reproducing the content of the NOTICE file.

   7. Disclaimer of Warranty. Unless required by applicable law or
      agreed to in writing, Licensor provides the Work (and each
      Contributor provides its Contributions) on an "AS IS" BASIS,
      WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
      implied, including, without limitation, any conditions of TITLE,
      NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A PARTICULAR
      PURPOSE. You are solely responsible for determining the
      appropriateness of using or reproducing the Work and assume any
      risks associated with Your exercise of permissions under this License.

   8. Limitation of Liability. In no event and under no legal theory,
      whether in tort (including negligence), contract, or otherwise,
      unless required by applicable law (such as deliberate and grossly
      negligent acts) or agreed to in writing, shall any Contributor be
      liable to You for damages, including any direct, indirect, special,
      incidental, or exemplary damages of any character arising as a
      result of this License or out of the use or inability to use the
      Work (including but not limited to damages for loss of goodwill,
      work stoppage, computer failure or malfunction, or all other
      commercial damages or losses), even if such Contributor has been
      advised of the possibility of such damages.

   9. Accepting Warranty or Liability. While redistributing the Work or
      Derivative Works thereof, You may choose to offer, and charge a fee
      for, acceptance of support, warranty, indemnity, or other liability
      obligations and/or rights consistent with this License. However, in
      accepting such obligations, You may offer such obligations only on
      Your own behalf and on Your sole responsibility, not on behalf of
      any other Contributor, and only if You agree to indemnify, defend,
      and hold each Contributor harmless for any liability incurred by,
      or claims asserted against, such Contributor by reason of your
      accepting any warranty or additional liability.

   END OF TERMS AND CONDITIONS

   Copyright 2026 terraform-aws-cost-tags contributors

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
```

- [ ] **Step 5: Format and commit**

```bash
terraform fmt versions.tf
git add versions.tf .gitignore LICENSE
git commit -m "chore: scaffold repo skeleton"
```

---

## Task 2: Write variables.tf

**Files:**
- Create: `variables.tf`

- [ ] **Step 1: Write `variables.tf`**

Create `variables.tf`:

```hcl
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
```

- [ ] **Step 2: Format and commit**

```bash
terraform fmt variables.tf
git add variables.tf
git commit -m "feat: add variables with validation blocks"
```

---

## Task 3: Write main.tf

**Files:**
- Create: `main.tf`

- [ ] **Step 1: Write `main.tf`**

Create `main.tf`:

```hcl
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
```

- [ ] **Step 2: Run `terraform validate`**

```bash
terraform validate
```

Expected output:
```
Success! The configuration is valid.
```

- [ ] **Step 3: Format and commit**

```bash
terraform fmt main.tf
git add main.tf
git commit -m "feat: add 3-level tag merge locals"
```

---

## Task 4: Write outputs.tf

**Files:**
- Create: `outputs.tf`

- [ ] **Step 1: Write `outputs.tf`**

Create `outputs.tf`:

```hcl
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
```

- [ ] **Step 2: Run `terraform validate`**

```bash
terraform validate
```

Expected output:
```
Success! The configuration is valid.
```

- [ ] **Step 3: Format and commit**

```bash
terraform fmt outputs.tf
git add outputs.tf
git commit -m "feat: add outputs for all tag inheritance levels"
```

---

## Task 5: Write examples/minimal

**Files:**
- Create: `examples/minimal/main.tf`
- Create: `examples/minimal/outputs.tf`

- [ ] **Step 1: Write `examples/minimal/main.tf`**

Create `examples/minimal/main.tf`:

```hcl
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

module "cost_tags" {
  source = "../../"

  org_name    = "acme"
  environment = "dev"
  project     = "myapp"
  team        = "backend-team"
  cost_center = "eng-001"
}
```

- [ ] **Step 2: Write `examples/minimal/outputs.tf`**

Create `examples/minimal/outputs.tf`:

```hcl
output "tags" {
  description = "Final merged tag map applied via default_tags."
  value       = module.cost_tags.tags
}

output "tag_keys" {
  description = "All tag key names in the merged map."
  value       = module.cost_tags.tag_keys
}
```

- [ ] **Step 3: Init and validate**

```bash
cd examples/minimal
terraform init
terraform validate
```

Expected output:
```
Initializing the backend...
...
Terraform has been successfully initialized!

Success! The configuration is valid.
```

- [ ] **Step 4: Format and commit**

```bash
terraform fmt examples/minimal/
cd ../..
git add examples/minimal/
git commit -m "feat: add examples/minimal"
```

---

## Task 6: Write examples/complete

**Files:**
- Create: `examples/complete/main.tf`
- Create: `examples/complete/outputs.tf`
- Create: `examples/complete/Makefile`

- [ ] **Step 1: Write `examples/complete/main.tf`**

Create `examples/complete/main.tf`:

```hcl
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
  # No tags block needed — all 8 tags inherited from default_tags
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
```

- [ ] **Step 2: Write `examples/complete/outputs.tf`**

Create `examples/complete/outputs.tf`:

```hcl
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
```

- [ ] **Step 3: Write `examples/complete/Makefile`**

Create `examples/complete/Makefile`:

```makefile
SENTINEL_POLICY := ../../sentinel/policies/require-cost-tags.sentinel
SENTINEL_CONFIG := ../../sentinel/sentinel.hcl

.PHONY: lint validate plan sentinel test

lint:
	terraform fmt -check -recursive ../..

validate:
	terraform validate

plan:
	terraform plan -out=tfplan.binary
	terraform show -json tfplan.binary > tfplan.json

sentinel: plan
	sentinel apply -config=$(SENTINEL_CONFIG) $(SENTINEL_POLICY)

test:
	sentinel test $(SENTINEL_POLICY)

clean:
	rm -f tfplan.binary tfplan.json
```

- [ ] **Step 4: Init and validate**

```bash
cd examples/complete
terraform init
terraform validate
```

Expected output:
```
Success! The configuration is valid.
```

- [ ] **Step 5: Format and commit**

```bash
terraform fmt examples/complete/
cd ../..
git add examples/complete/
git commit -m "feat: add examples/complete with Makefile"
```

---

## Task 7: Write Sentinel mock data (TDD — mocks before policy)

**Files:**
- Create: `sentinel/mocks/mock-tfplan-pass.sentinel`
- Create: `sentinel/mocks/mock-tfplan-fail.sentinel`
- Create: `sentinel/test/require-cost-tags/pass.hcl`
- Create: `sentinel/test/require-cost-tags/fail.hcl`

- [ ] **Step 1: Write passing mock `sentinel/mocks/mock-tfplan-pass.sentinel`**

This mock represents a plan where all AWS resources carry the 5 required tags. The policy must return `true` for this mock.

Create `sentinel/mocks/mock-tfplan-pass.sentinel`:

```python
resource_changes = {
  "aws_instance.web": {
    "address":       "aws_instance.web",
    "type":          "aws_instance",
    "name":          "web",
    "provider_name": "registry.terraform.io/hashicorp/aws",
    "change": {
      "actions": ["create"],
      "before":  null,
      "after": {
        "ami":           "ami-0c55b159cbfafe1f0",
        "instance_type": "t3.micro",
        "tags": {
          "Environment": "prod",
          "Project":     "payments",
          "Team":        "platform-team",
          "CostCenter":  "eng-001",
          "ManagedBy":   "terraform",
        },
      },
      "after_unknown": {},
    },
  },
  "aws_db_instance.primary": {
    "address":       "aws_db_instance.primary",
    "type":          "aws_db_instance",
    "name":          "primary",
    "provider_name": "registry.terraform.io/hashicorp/aws",
    "change": {
      "actions": ["create"],
      "before":  null,
      "after": {
        "engine":         "postgres",
        "instance_class": "db.t3.micro",
        "tags": {
          "Environment": "prod",
          "Project":     "payments",
          "Team":        "platform-team",
          "CostCenter":  "eng-001",
          "ManagedBy":   "terraform",
        },
      },
      "after_unknown": {},
    },
  },
  "aws_s3_bucket.assets": {
    "address":       "aws_s3_bucket.assets",
    "type":          "aws_s3_bucket",
    "name":          "assets",
    "provider_name": "registry.terraform.io/hashicorp/aws",
    "change": {
      "actions": ["create"],
      "before":  null,
      "after": {
        "bucket": "acme-prod-assets",
        "tags": {
          "Environment": "prod",
          "Project":     "payments",
          "Team":        "platform-team",
          "CostCenter":  "eng-001",
          "ManagedBy":   "terraform",
        },
      },
      "after_unknown": {},
    },
  },
  "aws_lambda_function.processor": {
    "address":       "aws_lambda_function.processor",
    "type":          "aws_lambda_function",
    "name":          "processor",
    "provider_name": "registry.terraform.io/hashicorp/aws",
    "change": {
      "actions": ["create"],
      "before":  null,
      "after": {
        "function_name": "acme-prod-processor",
        "runtime":       "nodejs20.x",
        "tags": {
          "Environment": "prod",
          "Project":     "payments",
          "Team":        "platform-team",
          "CostCenter":  "eng-001",
          "ManagedBy":   "terraform",
        },
      },
      "after_unknown": {},
    },
  },
  "aws_sqs_queue.jobs": {
    "address":       "aws_sqs_queue.jobs",
    "type":          "aws_sqs_queue",
    "name":          "jobs",
    "provider_name": "registry.terraform.io/hashicorp/aws",
    "change": {
      "actions": ["create"],
      "before":  null,
      "after": {
        "name": "acme-prod-jobs",
        "tags": {
          "Environment": "prod",
          "Project":     "payments",
          "Team":        "platform-team",
          "CostCenter":  "eng-001",
          "ManagedBy":   "terraform",
        },
      },
      "after_unknown": {},
    },
  },
  "aws_vpc.main": {
    "address":       "aws_vpc.main",
    "type":          "aws_vpc",
    "name":          "main",
    "provider_name": "registry.terraform.io/hashicorp/aws",
    "change": {
      "actions": ["create"],
      "before":  null,
      "after": {
        "cidr_block": "10.0.0.0/16",
        "tags": {
          "Environment": "prod",
          "Project":     "payments",
          "Team":        "platform-team",
          "CostCenter":  "eng-001",
          "ManagedBy":   "terraform",
        },
      },
      "after_unknown": {},
    },
  },
}
```

- [ ] **Step 2: Write failing mock `sentinel/mocks/mock-tfplan-fail.sentinel`**

This mock has resources with missing required tags. The policy must return `false` for this mock.

Create `sentinel/mocks/mock-tfplan-fail.sentinel`:

```python
resource_changes = {
  # Missing CostCenter and ManagedBy
  "aws_instance.web": {
    "address":       "aws_instance.web",
    "type":          "aws_instance",
    "name":          "web",
    "provider_name": "registry.terraform.io/hashicorp/aws",
    "change": {
      "actions": ["create"],
      "before":  null,
      "after": {
        "ami":           "ami-0c55b159cbfafe1f0",
        "instance_type": "t3.micro",
        "tags": {
          "Environment": "prod",
          "Project":     "payments",
          "Team":        "platform-team",
        },
      },
      "after_unknown": {},
    },
  },
  # Has no tags at all
  "aws_s3_bucket.untagged": {
    "address":       "aws_s3_bucket.untagged",
    "type":          "aws_s3_bucket",
    "name":          "untagged",
    "provider_name": "registry.terraform.io/hashicorp/aws",
    "change": {
      "actions": ["create"],
      "before":  null,
      "after": {
        "bucket": "acme-prod-untagged",
      },
      "after_unknown": {},
    },
  },
  # Missing only Team
  "aws_lambda_function.worker": {
    "address":       "aws_lambda_function.worker",
    "type":          "aws_lambda_function",
    "name":          "worker",
    "provider_name": "registry.terraform.io/hashicorp/aws",
    "change": {
      "actions": ["update"],
      "before": {
        "function_name": "acme-prod-worker",
        "tags": {},
      },
      "after": {
        "function_name": "acme-prod-worker",
        "tags": {
          "Environment": "prod",
          "Project":     "payments",
          "CostCenter":  "eng-001",
          "ManagedBy":   "terraform",
        },
      },
      "after_unknown": {},
    },
  },
  # Fully compliant — verifies policy only flags actual violations
  "aws_sqs_queue.compliant": {
    "address":       "aws_sqs_queue.compliant",
    "type":          "aws_sqs_queue",
    "name":          "compliant",
    "provider_name": "registry.terraform.io/hashicorp/aws",
    "change": {
      "actions": ["create"],
      "before":  null,
      "after": {
        "name": "acme-prod-compliant",
        "tags": {
          "Environment": "prod",
          "Project":     "payments",
          "Team":        "platform-team",
          "CostCenter":  "eng-001",
          "ManagedBy":   "terraform",
        },
      },
      "after_unknown": {},
    },
  },
}
```

- [ ] **Step 3: Write test case `sentinel/test/require-cost-tags/pass.hcl`**

Create `sentinel/test/require-cost-tags/pass.hcl`:

```hcl
mock "tfplan/v2" {
  module {
    source = "../../mocks/mock-tfplan-pass.sentinel"
  }
}

test {
  rules = {
    main = true
  }
}
```

- [ ] **Step 4: Write test case `sentinel/test/require-cost-tags/fail.hcl`**

Create `sentinel/test/require-cost-tags/fail.hcl`:

```hcl
mock "tfplan/v2" {
  module {
    source = "../../mocks/mock-tfplan-fail.sentinel"
  }
}

test {
  rules = {
    main = false
  }
}
```

- [ ] **Step 5: Commit mock data and test cases**

```bash
git add sentinel/mocks/ sentinel/test/
git commit -m "test: add Sentinel mock data and test cases (TDD)"
```

---

## Task 8: Write Sentinel policy

**Files:**
- Create: `sentinel/policies/require-cost-tags.sentinel`

- [ ] **Step 1: Write `sentinel/policies/require-cost-tags.sentinel`**

Create `sentinel/policies/require-cost-tags.sentinel`:

```python
# require-cost-tags.sentinel
#
# Enforces that every AWS resource being created or updated in the Terraform
# plan carries all five required cost allocation tags. Resources that have
# no `tags` attribute in the plan after-state are treated as non-compliant.
#
# Required tags: Environment, Project, Team, CostCenter, ManagedBy

import "tfplan/v2" as tfplan
import "strings"

required_tags = [
  "Environment",
  "Project",
  "Team",
  "CostCenter",
  "ManagedBy",
]

# Collect every AWS resource change that is a create or update action.
aws_resource_changes = filter tfplan.resource_changes as _, rc {
  strings.has_prefix(rc.type, "aws_") and
  (rc.change.actions contains "create" or rc.change.actions contains "update")
}

# For each AWS resource, find any required tags that are absent.
# A resource with no `tags` key at all is treated as having an empty tag map.
violations = filter aws_resource_changes as addr, rc {
  tags = rc.change.after.tags else {}
  any required_tags as t {
    not keys(tags) contains t
  }
}

# Print each violation to make CI output actionable.
print_violations = rule {
  all violations as addr, rc {
    tags    = rc.change.after.tags else {}
    missing = filter required_tags as t { not keys(tags) contains t }
    print("MISSING TAGS on", addr, "->", missing)
  }
}

main = rule {
  print_violations and
  length(violations) is 0
}
```

- [ ] **Step 2: Run `sentinel test` and verify both cases pass**

```bash
sentinel test sentinel/policies/require-cost-tags.sentinel
```

Expected output:
```
PASS - require-cost-tags.sentinel
  PASS - test/require-cost-tags/pass.hcl
  PASS - test/require-cost-tags/fail.hcl
```

If `pass.hcl` fails: a tag is missing from `mock-tfplan-pass.sentinel` — add it.
If `fail.hcl` fails (reports `true` instead of `false`): the violation filter is not catching the missing tags — re-check the `keys(tags) contains t` expression.

- [ ] **Step 3: Commit**

```bash
git add sentinel/policies/
git commit -m "feat: add Sentinel policy require-cost-tags (hard-mandatory)"
```

---

## Task 9: Write sentinel.hcl and sentinel/README.md

**Files:**
- Create: `sentinel/sentinel.hcl`
- Create: `sentinel/README.md`

- [ ] **Step 1: Write `sentinel/sentinel.hcl`**

Create `sentinel/sentinel.hcl`:

```hcl
policy "require-cost-tags" {
  source            = "./policies/require-cost-tags.sentinel"
  enforcement_level = "hard-mandatory"
}
```

- [ ] **Step 2: Write `sentinel/README.md`**

Create `sentinel/README.md`:

```markdown
# Sentinel Policy: require-cost-tags

Enforces that every AWS resource being created or updated carries all five
required cost allocation tags. Enforcement level: **hard-mandatory** (plan fails,
not just warns).

## Required Tags

| Tag | Example |
|---|---|
| `Environment` | `prod` |
| `Project` | `payments` |
| `Team` | `platform-team` |
| `CostCenter` | `eng-001` |
| `ManagedBy` | `terraform` |

## Prerequisites

Install the Sentinel CLI:

```bash
# macOS
brew install hashicorp/tap/sentinel

# Linux / CI — download from https://releases.hashicorp.com/sentinel/
```

## Running the Policy Against a Plan

```bash
# 1. Generate a plan JSON from your Terraform project
terraform plan -out=tfplan.binary
terraform show -json tfplan.binary > tfplan.json

# 2. Apply the policy (run from repo root)
sentinel apply -config=sentinel/sentinel.hcl sentinel/policies/require-cost-tags.sentinel
```

A passing result looks like:

```
Pass - require-cost-tags.sentinel
```

A failing result names each non-compliant resource and lists the missing tags:

```
MISSING TAGS on aws_instance.web -> ["CostCenter", "ManagedBy"]
Fail - require-cost-tags.sentinel

  Fail - require-cost-tags (hard-mandatory)
```

## Running Unit Tests (no AWS credentials required)

```bash
sentinel test sentinel/policies/require-cost-tags.sentinel
```

Expected output:

```
PASS - require-cost-tags.sentinel
  PASS - test/require-cost-tags/pass.hcl
  PASS - test/require-cost-tags/fail.hcl
```

## CI Integration (GitHub Actions example)

```yaml
- name: Install Sentinel
  run: |
    curl -fsSL https://releases.hashicorp.com/sentinel/0.26.3/sentinel_0.26.3_linux_amd64.zip -o sentinel.zip
    unzip sentinel.zip -d /usr/local/bin/

- name: Run Sentinel tests
  run: sentinel test sentinel/policies/require-cost-tags.sentinel

- name: Run Sentinel against plan
  run: |
    terraform plan -out=tfplan.binary
    terraform show -json tfplan.binary > tfplan.json
    sentinel apply -config=sentinel/sentinel.hcl sentinel/policies/require-cost-tags.sentinel
```

## Updating Required Tags

To add or remove a required tag, edit the `required_tags` list in
`sentinel/policies/require-cost-tags.sentinel` and update both mock files in
`sentinel/mocks/` to reflect the new requirement. Re-run `sentinel test` to verify.
```

- [ ] **Step 3: Commit**

```bash
git add sentinel/sentinel.hcl sentinel/README.md
git commit -m "feat: add sentinel.hcl policy set and usage README"
```

---

## Task 10: Write .terraform-docs.yml and README.md

**Files:**
- Create: `.terraform-docs.yml`
- Create: `README.md`

- [ ] **Step 1: Write `.terraform-docs.yml`**

Create `.terraform-docs.yml`:

```yaml
formatter: "markdown table"

output:
  file: "README.md"
  mode: replace

sort:
  enabled: true
  by: name

settings:
  anchor: true
  color: true
  default: true
  description: true
  escape: true
  html: true
  indent: 2
  required: true
  sensitive: true
  type: true

content: |-
  # terraform-aws-cost-tags

  [![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
  [![Terraform Registry](https://img.shields.io/badge/Terraform-Registry-7B42BC)](https://registry.terraform.io/)

  A plug-and-play Terraform module for AWS that produces a standardised **cost allocation tag map** with three-level inheritance (org → team → resource). It provisions **no AWS resources** — it only computes and outputs tag maps for use in `provider default_tags` or resource `tags` blocks.

  Drop it into any existing AWS Terraform project as a FinOps tool.

  ---

  ## Features

  - **Zero resources** — no AWS API calls, no provider credentials required at module level
  - **3-level tag inheritance** — org-wide → team → resource-specific, right side wins
  - **Input validation** — required tags enforced at `terraform plan` time
  - **Sentinel policy** — second enforcement layer for CI pipelines (local CLI, no Terraform Cloud required)
  - **HashiCorp Registry ready** — follows official module structure and conventions

  ---

  ## Usage

  ### Minimal

  ```hcl
  module "cost_tags" {
    source  = "YOUR_ORG/cost-tags/aws"
    version = "1.0.0"

    org_name    = "acme"
    environment = "prod"
    project     = "payments"
    team        = "platform-team"
    cost_center = "eng-001"
  }

  provider "aws" {
    region = var.aws_region

    default_tags {
      tags = module.cost_tags.tags
    }
  }
  ```

  ### Complete (3-level inheritance + per-resource override)

  ```hcl
  module "cost_tags" {
    source  = "YOUR_ORG/cost-tags/aws"
    version = "1.0.0"

    org_name    = "acme"
    environment = "prod"
    project     = "payments"
    team        = "platform-team"
    cost_center = "eng-001"

    # Level 1: org-wide additions (e.g. compliance labels)
    org_tags = {
      ComplianceLevel = "pci-dss"
      DataClass       = "confidential"
    }

    # Level 2: team additions (override org_tags on collision)
    team_tags = {
      Slack    = "#platform-alerts"
      CostCode = "P-2024-Q2"
    }
  }

  provider "aws" {
    region = var.aws_region
    default_tags {
      tags = module.cost_tags.tags
    }
  }

  # Level 3: per-resource override — charge this bucket to security team
  resource "aws_s3_bucket" "audit_logs" {
    bucket = "acme-prod-audit-logs"
    tags   = merge(module.cost_tags.tags, { CostCenter = "security-team" })
  }
  ```

  ---

  ## Viewing Costs in the AWS Console

  After running `terraform apply`, your resources will carry the cost allocation tags. Follow these steps to see attributed costs.

  ### Step 1 — Activate tags as Cost Allocation Tags (one-time per account)

  AWS does not expose user-defined tags in Cost Explorer until you activate them:

  1. Open **AWS Console → Billing and Cost Management → Cost Allocation Tags**
  2. Select the **User-defined tags** tab
  3. Find and select: `Environment`, `Project`, `Team`, `CostCenter`, `ManagedBy`
  4. Click **Activate**

  > Allow up to **24 hours** for AWS to begin attributing costs to the newly activated tags. Tags on resources created before activation are back-filled for the current billing period only.

  ### Step 2 — View costs in Cost Explorer

  1. Open **AWS Console → Billing → Cost Explorer → Launch Cost Explorer**
  2. In the **Group by** dropdown, select **Tag** and choose a key (e.g. `CostCenter`)
  3. Set the **date range** (daily or monthly granularity)
  4. Optionally add a **filter** on `Environment = prod` to scope to production only

  You will see a bar or line chart breaking down spend per tag value — for example, all charges attributed to `Team = platform-team` across all resource types.

  ### Step 3 — Set up tag-based Budget alerts

  1. Go to **Billing → Budgets → Create Budget → Cost budget**
  2. Under **Filters**, choose **Tag** and select `CostCenter` (or any other key)
  3. Enter the tag value to scope the budget (e.g. `eng-001`)
  4. Set a monthly threshold and an SNS/email alert destination

  You will receive an alert when spend for that cost center exceeds the threshold.

  ### Step 4 — Cost and Usage Report (CUR) for dashboards

  For Athena or QuickSight dashboards, enable a CUR with resource-level tagging:

  1. **Billing → Cost and Usage Reports → Create report**
  2. Enable **Include resource IDs** and **Automatically refresh**
  3. Deliver to an S3 bucket, then query via Athena or visualise in QuickSight

  Filter and group CUR data by the same tag key names (`Environment`, `Project`, `Team`, `CostCenter`) to build any FinOps dashboard your team needs.

  ---

  ## Sentinel Policy (local enforcement)

  See [`sentinel/README.md`](sentinel/README.md) for full usage instructions.

  Quick start:

  ```bash
  # Unit tests (no credentials required)
  sentinel test sentinel/policies/require-cost-tags.sentinel

  # Apply against a live plan
  terraform plan -out=tfplan.binary
  terraform show -json tfplan.binary > tfplan.json
  sentinel apply -config=sentinel/sentinel.hcl sentinel/policies/require-cost-tags.sentinel
  ```

  ---

  {{ .Requirements }}

  {{ .Inputs }}

  {{ .Outputs }}

  ---

  ## License

  [Apache 2.0](LICENSE)
```

- [ ] **Step 2: Generate `README.md` via terraform-docs**

If terraform-docs is installed:

```bash
terraform-docs .
```

Expected: `README.md` created/updated with the full content from `.terraform-docs.yml` including the auto-generated inputs and outputs tables.

If terraform-docs is **not** installed, write `README.md` manually by copying the `content` block from `.terraform-docs.yml` and replacing `{{ .Requirements }}`, `{{ .Inputs }}`, `{{ .Outputs }}` with the following:

**Requirements section:**

```markdown
## Requirements

| Name | Version |
|---|---|
| terraform | >= 1.6.0 |
```

**Inputs section** (paste this table):

```markdown
## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| org\_name | Organisation identifier used as the top-level tag hierarchy label. | `string` | n/a | yes |
| environment | Deployment environment. Must be one of: dev, sit, staging, prod. | `string` | n/a | yes |
| project | Project or product name used for cost attribution. | `string` | n/a | yes |
| team | Owning team name (e.g. platform-team, data-team). | `string` | n/a | yes |
| cost\_center | FinOps cost center code used for billing attribution (e.g. eng-001). | `string` | n/a | yes |
| managed\_by | Value for the ManagedBy tag. Identifies the provisioning tool. | `string` | `"terraform"` | no |
| org\_tags | Organisation-wide base tags. Merged over the required schema. Right side wins on key collision. | `map(string)` | `{}` | no |
| team\_tags | Team-level tags. Merged over org\_tags. Right side wins on key collision. | `map(string)` | `{}` | no |
| resource\_tags | Resource-specific tags. Merged over team\_tags. Highest priority among the named levels. | `map(string)` | `{}` | no |
| additional\_tags | Escape hatch for one-off tags that do not fit the hierarchy. Applied last — highest priority of all. | `map(string)` | `{}` | no |
```

**Outputs section** (paste this table):

```markdown
## Outputs

| Name | Description |
|---|---|
| tags | Fully merged tag map (all levels combined). Plug directly into provider default\_tags or resource tags blocks. |
| base\_tags | Required-schema tags only. No overrides applied. Useful for auditing. |
| org\_tags | Level 1 merged result: base\_tags merged with var.org\_tags. |
| team\_tags | Level 2 merged result: org\_tags merged with var.team\_tags. |
| tag\_keys | Sorted list of all tag keys in the final merged map. |
```

- [ ] **Step 3: Commit**

```bash
git add .terraform-docs.yml README.md
git commit -m "docs: add README and terraform-docs config"
```

---

## Task 11: Write CHANGELOG.md and final validation

**Files:**
- Create: `CHANGELOG.md`

- [ ] **Step 1: Write `CHANGELOG.md`**

Create `CHANGELOG.md`:

```markdown
# Changelog

All notable changes to this module will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
This module adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-04-25

### Added
- Root module with 3-level tag inheritance (org → team → resource → additional)
- Required inputs: `org_name`, `environment`, `project`, `team`, `cost_center`
- Input validation blocks enforcing non-empty strings and allowed environment values
- Optional override maps: `org_tags`, `team_tags`, `resource_tags`, `additional_tags`
- Output: `tags` (fully merged), `base_tags`, `org_tags`, `team_tags`, `tag_keys`
- `examples/minimal` — minimal usage with `default_tags`
- `examples/complete` — full 3-level inheritance with per-resource override and Makefile
- `sentinel/policies/require-cost-tags.sentinel` — hard-mandatory policy enforcing all 5 required tags on every AWS resource create/update
- Sentinel mock data and test cases for offline `sentinel test` execution
- Apache 2.0 license
```

- [ ] **Step 2: Run final `terraform validate` on all configurations**

```bash
terraform validate
cd examples/minimal && terraform validate && cd ../..
cd examples/complete && terraform validate && cd ../..
```

Expected output for each:
```
Success! The configuration is valid.
```

- [ ] **Step 3: Run final `sentinel test`**

```bash
sentinel test sentinel/policies/require-cost-tags.sentinel
```

Expected output:
```
PASS - require-cost-tags.sentinel
  PASS - test/require-cost-tags/pass.hcl
  PASS - test/require-cost-tags/fail.hcl
```

- [ ] **Step 4: Run `terraform fmt` across the entire repo**

```bash
terraform fmt -recursive .
```

Expected: no output (all files already formatted) or a list of files that were reformatted.

- [ ] **Step 5: Final commit and tag**

```bash
git add CHANGELOG.md
git commit -m "chore: add CHANGELOG and 1.0.0 release notes"
git tag v1.0.0
```

---

## Registry Publishing Checklist

After all tasks are complete and `v1.0.0` is tagged:

- [ ] Push to a **public** GitHub repository named exactly `terraform-aws-cost-tags`
- [ ] Sign in to [registry.terraform.io](https://registry.terraform.io) with your GitHub account
- [ ] Click **Publish → Module** and select the `terraform-aws-cost-tags` repo
- [ ] Confirm the module name resolves to `<YOUR_NAMESPACE>/cost-tags/aws`
- [ ] Verify the README, inputs, outputs, and examples render correctly on the registry page
