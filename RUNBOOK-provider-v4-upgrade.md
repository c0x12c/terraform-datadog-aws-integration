# Runbook: Datadog Terraform Provider Upgrade v3 → v4

## Overview

The Datadog Terraform provider jumped from `~> 3.81.0` to `~> 4.9.0`.  
v4.0.0 introduced breaking changes that removed the deprecated `datadog_integration_aws` resource family and require migration to `datadog_integration_aws_account`.

---

## Breaking Changes

### Removed resources (v4.0.0)
| Removed resource | Replacement |
|---|---|
| `datadog_integration_aws` | `datadog_integration_aws_account` |
| `datadog_integration_aws_lambda_arn` | `datadog_integration_aws_account` (via `logs_config.lambda_forwarder`) |
| `datadog_integration_aws_log_collection` | `datadog_integration_aws_account` (via `logs_config`) |
| `datadog_integration_aws_tag_filter` | `datadog_integration_aws_account` (via `metrics_config.tag_filters`) |

### Other breaking changes in v4.0.0

- Minimum Terraform version raised to **1.1.5**
- `datadog_application_key` data source removed (use resource instead)
- `datadog_monitor`: `locked` field removed; use `restriction_policy` resource
- `datadog_integration_aws_event_bridge`: upgraded to v2 API

---

## Attribute Migration Map

### `datadog_integration_aws` → `datadog_integration_aws_account`

| Old attribute | New location | Notes |
|---|---|---|
| `account_id` | `aws_account_id` | Direct rename |
| `role_name` | `auth_config.aws_auth_config_role.role_name` | Now nested |
| `extended_resource_collection_enabled` | `resources_config.extended_collection` | Renamed, nested |
| `metrics_collection_enabled` | `metrics_config.enabled` | Renamed, nested |
| `account_specific_namespace_rules` (map(bool)) | `metrics_config.namespace_filters.include_only` or `exclude_only` | Type change: map → list of AWS namespace strings |
| `external_id` (computed) | `auth_config.aws_auth_config_role.external_id` | Still computed; Datadog auto-generates if omitted |

### New required blocks (use empty block for provider defaults)

```hcl
aws_partition  = "aws"          # required top-level attribute
aws_regions {}                  # empty = include all regions
logs_config    { lambda_forwarder {} }
metrics_config { namespace_filters {} }
resources_config {}
traces_config  { xray_services {} }
```

### Namespace filter format change

Old (`account_specific_namespace_rules`):
```hcl
account_specific_namespace_rules = {
  "elasticache" = true
  "rds"         = true
  "ec2"         = false
}
```

New (`namespace_filters`):
```hcl
metrics_config {
  namespace_filters {
    include_only = ["AWS/ElastiCache", "AWS/RDS"]
  }
}
```

Common service name → AWS namespace mapping:

| Old key | AWS namespace |
|---|---|
| `elasticache` | `AWS/ElastiCache` |
| `rds` | `AWS/RDS` |
| `ec2` | `AWS/EC2` |
| `lambda` | `AWS/Lambda` |
| `s3` | `AWS/S3` |
| `ecs` | `AWS/ECS` |
| `dynamodb` | `AWS/DynamoDB` |
| `kinesis` | `AWS/Kinesis` |
| `sqs` | `AWS/SQS` |
| `sns` | `AWS/SNS` |
| `elb` / `application_elb` | `AWS/ApplicationELB` |
| `network_elb` | `AWS/NetworkELB` |
| `redshift` | `AWS/Redshift` |
| `es` | `AWS/ES` |
| `cloudfront` | `AWS/CloudFront` |

Full list: use the `datadog_integration_aws_available_namespaces` data source or the [Datadog API](https://docs.datadoghq.com/api/latest/aws-integration/).

---

## Changes Made in This Repository

### `versions.tf`
- `~> 3.81.0` → `~> 4.9.0`

### `main.tf`
- Replaced `resource "datadog_integration_aws" "sandbox"` with `resource "datadog_integration_aws_account" "sandbox"`
- Restructured flat attributes into nested blocks (`auth_config`, `metrics_config`, `resources_config`, etc.)
- Updated `external_id` reference: `datadog_integration_aws.sandbox.external_id` → `datadog_integration_aws_account.sandbox.auth_config.aws_auth_config_role.external_id`

### `variables.tf`
- Removed: `aws_services_enabled` (`map(bool)`)
- Added: `namespace_filters_include_only` (`list(string)`, default `["AWS/ElastiCache", "AWS/RDS"]`)
- Added: `namespace_filters_exclude_only` (`list(string)`, default `null`)

### `main.tf` — mutual exclusivity guard
A `lifecycle.precondition` on `datadog_integration_aws_account` enforces that `namespace_filters_include_only` and `namespace_filters_exclude_only` are never both set:

```hcl
lifecycle {
  precondition {
    condition     = !(var.namespace_filters_include_only != null && var.namespace_filters_exclude_only != null)
    error_message = "namespace_filters_include_only and namespace_filters_exclude_only are mutually exclusive; set only one."
  }
}
```

### `locals.tf`
- Removed: `aws_services_enabled` local map (no longer needed; namespace selection moved to variable)
- Consolidated specific `elasticache:DescribeCacheClusters`, `elasticache:ListTagsForResource`, `elasticache:DescribeEvents` permissions into existing wildcards `elasticache:Describe*` and `elasticache:List*` — no net permissions change

### `examples/complete/main.tf`
- Replaced `aws_services_enabled` map with `namespace_filters_include_only = ["AWS/ElastiCache", "AWS/RDS"]`

---

## Upgrade Procedure

### Step 1 — Update provider version

The `versions.tf` already pins `~> 4.9.0`. Run:

```bash
terraform init -upgrade
```

### Step 2 — Import existing integration into new resource

The old state key is `datadog_integration_aws.sandbox`. The new resource type requires a re-import because the resource type name changed.

First, retrieve your Datadog AWS Account Config ID:

```bash
# Using Datadog API — replace DD_API_KEY and DD_APP_KEY with your credentials
curl -s "https://api.datadoghq.com/api/v2/integration/aws/accounts" \
  -H "DD-API-KEY: ${DD_API_KEY}" \
  -H "DD-APPLICATION-KEY: ${DD_APP_KEY}" \
  | jq '.data[] | select(.attributes.aws_account_id == "<YOUR_AWS_ACCOUNT_ID>") | .id'
```

Remove the old resource from state and import under the new address:

```bash
# Remove old resource from state
terraform state rm datadog_integration_aws.sandbox

# Import into new resource (use the ID returned from the API call above)
terraform import datadog_integration_aws_account.sandbox "<datadog-aws-account-config-id>"
```

### Step 3 — Validate the plan

```bash
terraform plan
```

Expected: no destructive changes. The plan should show only in-place attribute updates (if any) reflecting the new schema defaults.

### Step 4 — Apply

```bash
terraform apply
```

### Step 5 — Verify in Datadog UI

1. Navigate to **Integrations → AWS** in Datadog.
2. Confirm the AWS account still appears and the integration status is healthy.
3. Check that metric collection is active for the expected namespaces (`AWS/ElastiCache`, `AWS/RDS` by default).

---

## Rollback

If the upgrade causes issues:

1. Revert `versions.tf` to `~> 3.81.0`
2. Revert `main.tf`, `variables.tf`, `locals.tf`, and examples to the previous state (use git)
3. Remove the new state entry and restore the old one:

```bash
terraform state rm datadog_integration_aws_account.sandbox
# Restore old state from a backup (terraform state push backup.tfstate) or re-import
terraform import datadog_integration_aws.sandbox "<aws_account_id>"
```

4. Run `terraform init -upgrade` to downgrade the provider lock file
5. Run `terraform plan` to confirm the state is clean

---

## References

- [Datadog Provider v4.0.0 Release Notes](https://github.com/DataDog/terraform-provider-datadog/releases/tag/v4.0.0)
- [datadog_integration_aws_account resource docs](https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/integration_aws_account)
- [datadog_integration_aws_available_namespaces data source](https://registry.terraform.io/providers/DataDog/datadog/latest/docs/data-sources/integration_aws_available_namespaces)
- [AWS Integration IAM Policy](https://docs.datadoghq.com/integrations/amazon_web_services/#aws-integration-iam-policy)
