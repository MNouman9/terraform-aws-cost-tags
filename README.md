# terraform-aws-cost-tags

A plug-and-play Terraform module for AWS that produces a standardised cost
allocation tag map with 3-level inheritance (org → team → resource).
It **provisions no AWS resources** — it only computes and outputs tag maps
for consumption by `default_tags` or individual resource `tags` blocks.

Ships with a Sentinel CLI policy (`hard-mandatory`) for local and CI
enforcement without requiring Terraform Cloud.

## Usage

### Via `default_tags` (recommended)

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

All AWS resources in the configuration automatically receive the five required
tags without any per-resource `tags` block.

### Per-resource override

```hcl
resource "aws_lambda_function" "processor" {
  # ...
  tags = merge(module.cost_tags.tags, {
    CostCenter = "data-pipeline"
  })
}
```

### 3-level inheritance

```hcl
module "cost_tags" {
  source  = "YOUR_ORG/cost-tags/aws"
  version = "1.0.0"

  org_name    = "acme"
  environment = "prod"
  project     = "payments"
  team        = "platform-team"
  cost_center = "eng-001"

  org_tags = {
    ComplianceLabel = "sox-in-scope"
  }

  team_tags = {
    Slack    = "#platform-alerts"
    CostCode = "P-2024-Q2"
  }

  resource_tags = {
    CostCenter = "data-pipeline"
  }
}
```

Merge priority (right side wins): `base_tags` → `org_tags` → `team_tags`
→ `resource_tags` → `additional_tags`.

## Inputs

### Required

| Name | Description | Type |
|---|---|---|
| `org_name` | Organisation identifier used as the top-level tag hierarchy label. | `string` |
| `environment` | Deployment environment. Must be one of: `dev`, `sit`, `staging`, `prod`. | `string` |
| `project` | Project or product name used for cost attribution. | `string` |
| `team` | Owning team name (e.g. `platform-team`, `data-team`). | `string` |
| `cost_center` | FinOps cost center code used for billing attribution (e.g. `eng-001`). | `string` |

### Optional

| Name | Description | Type | Default |
|---|---|---|---|
| `managed_by` | Value for the `ManagedBy` tag. Identifies the provisioning tool. | `string` | `"terraform"` |
| `org_tags` | Organisation-wide base tags. Merged over the required schema. Right side wins on key collision. | `map(string)` | `{}` |
| `team_tags` | Team-level tags. Merged over `org_tags`. Right side wins on key collision. | `map(string)` | `{}` |
| `resource_tags` | Resource-specific tags. Merged over `team_tags`. Highest priority among the named levels. | `map(string)` | `{}` |
| `additional_tags` | Escape hatch for one-off tags. Applied last — highest priority of all. | `map(string)` | `{}` |

## Outputs

| Name | Description |
|---|---|
| `tags` | Fully merged tag map (all levels combined). Plug directly into `default_tags` or resource `tags` blocks. |
| `base_tags` | Required-schema tags only (`Environment`, `Project`, `Team`, `CostCenter`, `OrgName`, `ManagedBy`). No overrides applied. Useful for auditing. |
| `org_tags` | Level 1 merged result: `base_tags` merged with `var.org_tags`. |
| `team_tags` | Level 2 merged result: `org_tags` merged with `var.team_tags`. |
| `tag_keys` | Sorted list of all tag keys present in the final merged map. |

## Sentinel Policy

A `hard-mandatory` Sentinel policy is included in `sentinel/`. It fails the
Terraform plan if any AWS resource being created or updated is missing one or
more of the five required tag keys: `Environment`, `Project`, `Team`,
`CostCenter`, `ManagedBy`.

### Run locally

```bash
terraform plan -out=tfplan.binary
terraform show -json tfplan.binary > tfplan.json
sentinel apply -config=sentinel/sentinel.hcl sentinel/policies/require-cost-tags.sentinel
```

### Unit tests (offline, no plan needed)

```bash
sentinel test sentinel/policies/require-cost-tags.sentinel
```

See [`sentinel/README.md`](sentinel/README.md) for prerequisites, CI integration,
and how to update the required tag list.

## Viewing Costs in the AWS Console

After applying your Terraform configuration, AWS Cost Explorer can break down
spend by any of the five tags. Follow the steps below.

### Step 1 — Activate the tags as Cost Allocation Tags (one-time)

AWS must know which tag keys to track before they appear in billing reports.

1. Open **AWS Console → Billing → Cost Allocation Tags**.
2. Select the **User-defined** tab.
3. Find `Environment`, `Project`, `Team`, `CostCenter`, and `ManagedBy`.
4. Select all five and click **Activate**.

> Allow up to **24 hours** for AWS to begin attributing costs to newly
> activated tags.

### Step 2 — Explore costs in Cost Explorer

1. Open **AWS Console → Billing → Cost Explorer**.
2. Under **Group by**, choose **Tag** and select the key you want
   (e.g. `CostCenter`).
3. Set a date range and granularity (daily or monthly).
4. The chart shows spend per tag value — e.g. all costs attributed to
   `Team = platform-team`.

### Tag-based Budget Alerts (AWS Budgets)

1. Open **AWS Console → Billing → Budgets → Create Budget**.
2. Choose **Cost budget**.
3. Under **Filters**, select **Tag** and pick a key/value pair
   (e.g. `CostCenter = eng-001`).
4. Set a monthly threshold and configure SNS or email notifications.

This lets each team own a budget alert for their `CostCenter` value and receive
an SNS or email notification when the threshold is breached.

### Cost and Usage Report (CUR) for Athena / QuickSight

For programmatic access or custom dashboards, enable a CUR in
**Billing → Cost and Usage Reports**. The report includes a column for each
activated tag key, which you can query with Athena or visualise in QuickSight.

## Examples

- [`examples/minimal/`](examples/minimal/) — five required inputs + `default_tags` wiring
- [`examples/complete/`](examples/complete/) — full 3-level inheritance with
  per-resource override and a `Makefile` with `lint`, `validate`, `plan`,
  `sentinel`, and `test` targets

## Requirements

| Name | Version |
|---|---|
| terraform | >= 1.6.0 |

The module declares no AWS provider. Callers own their provider configuration.

## License

[Apache 2.0](LICENSE)
