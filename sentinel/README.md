# Sentinel Policy: require-cost-tags

Enforces that every AWS resource being **created or updated** in a Terraform plan
carries all five required cost allocation tags. The policy is `hard-mandatory` —
the plan is blocked, not just warned.

## Required Tags

| Tag | Description |
|---|---|
| `Environment` | Deployment tier (`dev`, `sit`, `staging`, `prod`) |
| `Project` | Product or system name |
| `Team` | Owning team |
| `CostCenter` | Billing code |
| `ManagedBy` | Always `terraform` |

## Prerequisites

Install the [Sentinel CLI](https://docs.hashicorp.com/sentinel/intro/getting-started/install):

```bash
# macOS (Homebrew)
brew install hashicorp/tap/sentinel

# Linux / WSL — download the binary from releases.hashicorp.com
curl -Lo sentinel.zip https://releases.hashicorp.com/sentinel/<VERSION>/sentinel_<VERSION>_linux_amd64.zip
unzip sentinel.zip && sudo mv sentinel /usr/local/bin/
```

## Running the Policy Locally

```bash
# 1. Generate the plan JSON
terraform plan -out=tfplan.binary
terraform show -json tfplan.binary > tfplan.json

# 2. Apply the policy against the plan
sentinel apply -config=sentinel/sentinel.hcl sentinel/policies/require-cost-tags.sentinel
```

A passing run prints `Pass - require-cost-tags.sentinel`.

A failing run lists every non-compliant resource and the tags it is missing:

```
MISSING TAGS on aws_instance.web -> [CostCenter ManagedBy]
Fail - require-cost-tags.sentinel
```

## Unit Tests (fully offline, no plan needed)

```bash
sentinel test sentinel/policies/require-cost-tags.sentinel
```

Expected output:

```
PASS - sentinel/policies/require-cost-tags.sentinel
  PASS - sentinel/policies/test/require-cost-tags/fail.hcl
  PASS - sentinel/policies/test/require-cost-tags/pass.hcl
1 tests completed
```

## File Layout

```
sentinel/
├── sentinel.hcl                            # Policy set, enforcement_level = hard-mandatory
├── policies/
│   ├── require-cost-tags.sentinel          # Policy source
│   └── test/
│       └── require-cost-tags/
│           ├── pass.hcl                    # Assert main = true (all resources tagged)
│           └── fail.hcl                    # Assert main = false (resources missing tags)
└── mocks/
    ├── mock-tfplan-pass.sentinel           # 6 resources, all 5 tags present
    └── mock-tfplan-fail.sentinel           # 4 resources, 3 non-compliant + 1 compliant
```

## CI Integration (GitHub Actions example)

```yaml
- name: Install Sentinel
  run: |
    curl -Lo sentinel.zip https://releases.hashicorp.com/sentinel/0.40.0/sentinel_0.40.0_linux_amd64.zip
    unzip sentinel.zip && sudo mv sentinel /usr/local/bin/

- name: Run Sentinel policy
  run: sentinel test sentinel/policies/require-cost-tags.sentinel
```

## Updating the Required Tag List

Edit `required_tags` at the top of `policies/require-cost-tags.sentinel`, then update
both mock files and re-run `sentinel test` to confirm all cases still pass.
