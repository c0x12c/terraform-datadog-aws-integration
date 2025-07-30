# Datadog GCP integration module

Terraform module which creates Datadog GCP integration and service account resources on GCP.

## Usage

### Create Artifact Registry

```hcl
locals {
  aws_services_enabled = {
    "elasticache"                    = true
    "rds"                            = true
  }
}

module "datadog_aws_integration" {
  source = "github.com/spartan-stratos/terraform-modules//datadog/aws-integration?ref=v0.1.22"

  aws_services_enabled = local.aws_services_enabled
}
```

## Examples

- [Example](./examples/complete/)

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.8 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.75 |
| <a name="requirement_datadog"></a> [datadog](#requirement\_datadog) | ~> 3.66.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.6.0 |
| <a name="provider_datadog"></a> [datadog](#provider\_datadog) | 3.66.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.datadog_aws_integration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.datadog_aws_integration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.datadog_aws_integration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [datadog_integration_aws_account.sandbox](https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/integration_aws_account) | resource |
| [aws_caller_identity.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.datadog_aws_integration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.datadog_aws_integration_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_services_enabled"></a> [aws\_services\_enabled](#input\_aws\_services\_enabled) | A map of AWS services with their enabled/disabled metric collection for specific AWS namespaces for this AWS account only. Reference: https://docs.datadoghq.com/integrations/#cat-aws. | `map(bool)` | `null` | no |
| <a name="input_datadog_aws_integration_iam_role"></a> [datadog\_aws\_integration\_iam\_role](#input\_datadog\_aws\_integration\_iam\_role) | Name of the IAM role used for integrating Datadog with AWS. | `string` | `"DatadogAWSIntegrationRole"` | no |
| <a name="input_datadog_permissions"></a> [datadog\_permissions](#input\_datadog\_permissions) | List of AWS IAM permissions required for Datadog integration with AWS services. Reference: https://docs.datadoghq.com/integrations/amazon_web_services/#aws-integration-iam-policy. | `list(string)` | `null` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
