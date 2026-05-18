module "datadog_aws_integration" {
  source = "../../"

  namespace_filters_include_only = ["AWS/ElastiCache", "AWS/RDS"]
}
