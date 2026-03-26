# terraform-module-sbx-vpc

AWS VPC Module for AON Sandbox Automation Project

## Overview

This Terraform module creates a complete VPC infrastructure with:
- VPC with configurable CIDR block
- VPC Flow Logs to CloudWatch Logs for traffic monitoring
- VPC Endpoints for S3 (Gateway)
- VPC Endpoints for DynamoDB (Gateway)
- DNS hostnames and DNS support enabled

## Features

- **Production-Ready**: Includes VPC Flow Logs for monitoring and compliance
- **VPC Endpoints**: Gateway endpoints for S3 and DynamoDB to reduce data transfer costs
- **Flexible Configuration**: All major settings configurable via variables
- **Input Validation**: Built-in validation for critical inputs
- **Security**: Support for DNS resolution and hostname settings
- **Tagging**: Comprehensive tagging strategy for resource organization

## Prerequisites

- Terraform >= 1.0
- AWS Provider >= 5.0
- AWS Account with appropriate IAM permissions
- VPC should not already exist in the target account

## Usage

### Basic Usage

```hcl
module "vpc" {
  source = "path/to/terraform-module-sbx-vpc"

  aws_region     = "us-east-1"
  environment    = "Sandbox"
  vpc_cidr_block = "10.10.0.0/16"

  common_tags = {
    Project   = "AON-AWS-Sandbox"
    CostCenter = "Engineering"
    Owner     = "CloudOps"
  }
}
```

### With Custom Settings

```hcl
module "vpc" {
  source = "path/to/terraform-module-sbx-vpc"

  aws_region                   = "us-east-1"
  environment                  = "Sandbox"
  vpc_cidr_block              = "10.10.0.0/16"
  enable_s3_endpoint          = true
  enable_dynamodb_endpoint    = true
  vpc_flow_logs_retention_days = 30

  common_tags = {
    Project     = "AON-AWS-Sandbox"
    CostCenter  = "Engineering"
    Owner       = "CloudOps"
    Environment = "Production"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `aws_region` | AWS region for deployment | `string` | `"us-east-1"` | No |
| `environment` | Environment name for tagging | `string` | `"Sandbox"` | No |
| `vpc_cidr_block` | CIDR block for VPC | `string` | `"10.10.0.0/16"` | No |
| `enable_dns_hostnames` | Enable DNS hostnames in VPC | `bool` | `true` | No |
| `enable_dns_support` | Enable DNS support in VPC | `bool` | `true` | No |
| `enable_s3_endpoint` | Enable S3 Gateway VPC Endpoint | `bool` | `true` | No |
| `enable_dynamodb_endpoint` | Enable DynamoDB Gateway VPC Endpoint | `bool` | `true` | No |
| `vpc_flow_logs_retention_days` | CloudWatch Logs retention in days | `number` | `30` | No |
| `route_table_ids` | Route table IDs for VPC endpoints | `list(string)` | `[]` | No |
| `common_tags` | Common tags for all resources | `map(string)` | See defaults | No |

## Outputs

| Name | Description |
|------|-------------|
| `vpc_id` | VPC ID |
| `vpc_cidr_block` | VPC CIDR block |
| `vpc_arn` | VPC ARN |
| `s3_endpoint_id` | S3 Gateway VPC Endpoint ID |
| `s3_endpoint_arn` | S3 Gateway VPC Endpoint ARN |
| `dynamodb_endpoint_id` | DynamoDB Gateway VPC Endpoint ID |
| `dynamodb_endpoint_arn` | DynamoDB Gateway VPC Endpoint ARN |
| `flow_log_group_name` | CloudWatch Log Group name for VPC Flow Logs |
| `flow_log_group_arn` | CloudWatch Log Group ARN |
| `availability_zones` | Available zones in the region |
| `account_id` | AWS Account ID |

## Network Architecture

```
┌─────────────────────────────────┐
│   VPC: 10.10.0.0/16             │
│                                 │
│  ├─ S3 Gateway Endpoint         │
│  ├─ DynamoDB Gateway Endpoint   │
│  └─ VPC Flow Logs (CloudWatch)  │
│                                 │
└─────────────────────────────────┘
```

## IAM Permissions Required

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVpc",
        "ec2:DescribeVpcs",
        "ec2:DescribeAvailabilityZones",
        "ec2:CreateVpcEndpoint",
        "ec2:DescribeVpcEndpoints",
        "ec2:ModifyVpcEndpoint",
        "logs:CreateLogGroup",
        "logs:DescribeLogGroups",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "iam:CreateRole",
        "iam:PutRolePolicy",
        "ec2:CreateFlowLogs",
        "ec2:DescribeFlowLogs"
      ],
      "Resource": "*"
    }
  ]
}
```

## Deployment Instructions

### Local Testing

```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Format code
terraform fmt -recursive

# Review plan
terraform plan

# Apply configuration
terraform apply
```

### Azure DevOps Pipeline

The module is designed to be used in Azure DevOps pipelines. See `CEPS-AWS-Sandbox` master repository for pipeline configuration.

## Terraform Plan Output Example

```
Terraform will perform the following actions:

  # aws_vpc.sandbox_vpc will be created
  + resource "aws_vpc" "sandbox_vpc" {
      + cidr_block           = "10.10.0.0/16"
      + enable_dns_hostnames = true
      + enable_dns_support   = true
      ...
    }

  # aws_vpc_endpoint.s3_gateway[0] will be created
  + resource "aws_vpc_endpoint" "s3_gateway" {
      ...
    }

  # aws_vpc_endpoint.dynamodb_gateway[0] will be created
  + resource "aws_vpc_endpoint" "dynamodb_gateway" {
      ...
    }

  # aws_cloudwatch_log_group.vpc_flow_logs_group will be created
  + resource "aws_cloudwatch_log_group" "vpc_flow_logs_group" {
      ...
    }
```

## Outputs After Apply

After successful `terraform apply`, you will get:
- VPC ID to use in subnet configuration
- VPC Endpoint IDs for S3 and DynamoDB
- CloudWatch Log Group name for monitoring
- AWS Account ID and availability zones

## Cleanup

To destroy all resources created by this module:

```bash
terraform destroy
```

## Module Dependencies

This module is a foundation module with no internal dependencies on other sandbox modules. However, it should be created first before:
- terraform-module-sbx-subnet
- terraform-module-sbx-securitygroup
- terraform-module-sbx-firewall

## Support

For issues or questions:
1. Check the Terraform plan output
2. Review AWS CloudWatch Logs for VPC Flow Logs
3. Verify IAM permissions
4. Check AWS service quotas

## Version History

### v1.0.0
- Initial release
- VPC infrastructure with VPC Endpoints
- VPC Flow Logs integration
- Production-ready configuration

## License

Internal Use Only - AON Sandbox Automation Project

## Contributors

AON Cloud Operations Team
