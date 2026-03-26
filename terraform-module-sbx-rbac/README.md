# terraform-module-sbx-rbac

AWS IAM/RBAC Module for AWS Sandbox Automation Project

## Overview

This Terraform module creates production-grade IAM roles, policies, and groups for the Sandbox environment with proper access control and cost management capabilities.

## Features

- **Service Roles**: EC2, Lambda, RDS roles with least-privilege access
- **IAM Groups**: Developers (full access) and Viewers (read-only)
- **Cost Control**: Roles and policies for budget enforcement and resource shutdown
- **SCP Ready**: Service Control Policies for restricting resource creation
- **Comprehensive Policies**: Read-only, developer, and cost management policies

## Prerequisites

- Terraform >= 1.0
- AWS Provider >= 5.0
- AWS Account with IAM permissions

## Usage

### Basic Usage

```hcl
module "rbac" {
  source = "path/to/terraform-module-sbx-rbac"

  aws_region  = "us-east-1"
  environment = "Sandbox"

  common_tags = {
    Project     = "AWS-AWS-Sandbox"
    CostCenter  = "Engineering"
    Owner       = "CloudOps"
  }
}
```

## Key Components

### Service Roles
1. **EC2 Instance Role**: For EC2 instances with SSM, CloudWatch, and S3 access
2. **Lambda Execution Role**: For Lambda functions with VPC and CloudWatch access
3. **RDS Monitoring Role**: For enhanced RDS monitoring
4. **Cost Control Role**: For Lambda/SSM to stop resources and manage costs

### IAM Groups
1. **sandbox-developers**: Full developer access to resources
2. **sandbox-viewers**: Read-only access for auditing

### Policies
1. **Developer Policy**: Create, modify, delete resources (with tags)
2. **Read-Only Policy**: Describe and Get operations only
3. **Cost Budget Policy**: Budget and cost explorer access
4. **Restrict Resource Creation**: SCP to freeze new resource creation

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `aws_region` | AWS region | `string` | `"us-east-1"` |
| `environment` | Environment name | `string` | `"Sandbox"` |
| `enable_ec2_instance_role` | Enable EC2 role | `bool` | `true` |
| `enable_lambda_execution_role` | Enable Lambda role | `bool` | `true` |
| `enable_rds_monitoring_role` | Enable RDS role | `bool` | `true` |
| `enable_cost_control_role` | Enable cost control role | `bool` | `true` |
| `enable_sandbox_groups` | Enable IAM groups | `bool` | `true` |
| `common_tags` | Common tags | `map(string)` | See defaults |

## Outputs

| Name | Description |
|------|-------------|
| `ec2_instance_role_arn` | EC2 instance role ARN |
| `lambda_execution_role_arn` | Lambda execution role ARN |
| `cost_control_role_arn` | Cost control role ARN |
| `developer_policy_arn` | Developer policy ARN |
| `read_only_policy_arn` | Read-only policy ARN |

## Deployment

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

## IAM Group Membership

To add users to groups:

```bash
# Add user to developers group
aws iam add-user-to-group --user-name john.doe --group-name Sandbox-developers

# Add user to viewers group
aws iam add-user-to-group --user-name jane.smith --group-name Sandbox-viewers
```

## Cost Control Features

The module creates roles for:
- Shutting down EC2 instances when budget threshold exceeded
- Stopping RDS instances to save costs
- Restricting new resource creation via SCPs
- Publishing alerts to SNS

## Service Control Policy

The SCP policy restricts:
- EC2 instance creation when budget exceeded
- RDS database creation when budget exceeded
- Applies only within the Sandbox region

## Cleanup

```bash
terraform destroy
```

## Version History

### v1.0.0
- Initial release
- Service roles (EC2, Lambda, RDS)
- IAM groups and policies
- Cost control automation support

## License

Internal Use Only - AWS Sandbox Automation Project

## Contributors

AWS Cloud Operations Team
