# Changelog

All notable changes to this project will be documented in this file.

## [1.0.2]() (2026-05-08)

### Features

* Add `aws_attached_policy_arns` variable to attach additional managed AWS policy ARNs (e.g. `SecurityAudit`) to the Datadog AWS integration IAM role.

## [1.0.1]() (2025-08-05)

### Changes

* Update `DataDog/datadog` requirement from `~> 3.66.0` to `~> 3.69.0`.

## [1.0.0]() (2025-07-15)

### BREAKING CHANGES

* Move module to `c0x12c` GitHub Org and deploy module to Terraform Registry.
* Remove service_quotas from the Datadog AWS integration, as it has been excluded from the list of enabled services.

## [0.1.22]() (2024-12-25)

### Features

* Initial commit with all the code
