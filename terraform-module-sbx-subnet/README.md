# terraform-module-sbx-subnet

AWS Subnet Module for AWS Sandbox Automation Project

## Overview

This Terraform module creates three production-grade subnets with Network ACLs (NACLs) for the Sandbox environment:
- **Private Subnet**: For internal resources with restricted access
- **Public Subnet**: For public-facing resources
- **Firewall Subnet**: For AWS Network Firewall resources

Each subnet includes:
- Inbound/Outbound NACL rules following security best practices
- Dedicated route tables for traffic routing
- Comprehensive tagging for resource management
- Specific CIDR blocks for controlled access

## Features

- **Three Subnet Architecture**: Private, Public, and Firewall subnets
- **Security-First Design**: Default-deny NACL rules with allow-list approach
- **NACL Rules**: Pre-configured rules for each subnet type:
  - Internal VPC communication (10.10.0.0/16)
  - External access from specific IP range (203.0.113.0/24)
  - Firewall-specific communication (10.10.5.0/24)
- **Route Table Management**: Separate route tables for each subnet
- **Flexible Configuration**: All CIDR blocks and settings configurable

## Prerequisites

- Terraform >= 1.0
- AWS Provider >= 5.0
- AWS Account with appropriate IAM permissions
- VPC already created (use terraform-module-sbx-vpc)
- VPC ID available from VPC module outputs

## Usage

### Basic Usage

```hcl
module "subnets" {
  source = "path/to/terraform-module-sbx-subnet"

  aws_region    = "us-east-1"
  environment   = "Sandbox"
  vpc_id        = module.vpc.vpc_id

  private_subnet_cidr    = "10.10.1.0/24"
  public_subnet_cidr     = "10.10.2.0/24"
  firewall_subnet_cidr   = "10.10.5.0/24"
  specific_ip_cidr       = "203.0.113.0/24"
  firewall_ip_cidr       = "10.10.5.0/24"

  common_tags = {
    Project     = "AWS-AWS-Sandbox"
    CostCenter  = "Engineering"
    Owner       = "CloudOps"
  }
}
```

### With Custom IP Ranges

```hcl
module "subnets" {
  source = "path/to/terraform-module-sbx-subnet"

  aws_region    = "us-east-1"
  environment   = "Sandbox"
  vpc_id        = module.vpc.vpc_id

  private_subnet_cidr    = "10.10.10.0/24"
  public_subnet_cidr     = "10.10.20.0/24"
  firewall_subnet_cidr   = "10.10.30.0/24"
  specific_ip_cidr       = "203.0.113.0/24"
  firewall_ip_cidr       = "10.10.30.0/24"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `aws_region` | AWS region for deployment | `string` | `"us-east-1"` | No |
| `environment` | Environment name for tagging | `string` | `"Sandbox"` | No |
| `vpc_id` | VPC ID for subnet creation | `string` | N/A | **Yes** |
| `private_subnet_cidr` | CIDR block for Private Subnet | `string` | `"10.10.1.0/24"` | No |
| `public_subnet_cidr` | CIDR block for Public Subnet | `string` | `"10.10.2.0/24"` | No |
| `firewall_subnet_cidr` | CIDR block for Firewall Subnet | `string` | `"10.10.5.0/24"` | No |
| `specific_ip_cidr` | CIDR block for external access | `string` | `"203.0.113.0/24"` | No |
| `firewall_ip_cidr` | CIDR block for firewall device | `string` | `"10.10.5.0/24"` | No |
| `common_tags` | Common tags for all resources | `map(string)` | See defaults | No |

## Outputs

| Name | Description |
|------|-------------|
| `private_subnet_id` | Private Subnet ID |
| `private_subnet_arn` | Private Subnet ARN |
| `private_subnet_cidr` | Private Subnet CIDR block |
| `public_subnet_id` | Public Subnet ID |
| `public_subnet_arn` | Public Subnet ARN |
| `public_subnet_cidr` | Public Subnet CIDR block |
| `firewall_subnet_id` | Firewall Subnet ID |
| `firewall_subnet_arn` | Firewall Subnet ARN |
| `firewall_subnet_cidr` | Firewall Subnet CIDR block |
| `private_nacl_id` | Private Subnet Network ACL ID |
| `public_nacl_id` | Public Subnet Network ACL ID |
| `firewall_nacl_id` | Firewall Subnet Network ACL ID |
| `private_route_table_id` | Private Route Table ID |
| `public_route_table_id` | Public Route Table ID |
| `firewall_route_table_id` | Firewall Route Table ID |
| `all_subnet_ids` | Map of all subnet IDs |
| `all_route_table_ids` | Map of all route table IDs |

## Network Architecture

```
┌─────────────────────────────────────────────┐
│   VPC: 10.10.0.0/16                         │
│                                             │
├──────────────┬──────────────┬───────────────┤
│ Private      │ Public       │ Firewall      │
│ 10.10.1.0/24 │ 10.10.2.0/24 │ 10.10.5.0/24 │
│              │              │               │
│ NACL Rules:  │ NACL Rules:  │ NACL Rules:  │
│ In/Out       │ In/Out       │ In/Out       │
│ - VPC access │ - VPC access │ - VPC access │
│ - Specific IP│ - Specific IP│ - Firewall IP│
│ - Deny *     │ - Deny *     │ - Deny *     │
│              │              │               │
│ Route Table  │ Route Table  │ Route Table  │
└──────────────┴──────────────┴───────────────┘
```

## NACL Rules Details

### Private Subnet NACL
- **Inbound Rule 100**: Allow TCP all ports from 10.10.0.0/16 (VPC)
- **Inbound Rule 200**: Allow TCP ports 1025-65535 from 203.0.113.0/24 (Specific IPs)
- **Inbound Rule 32767**: Deny all remaining traffic
- **Outbound Rule 100**: Allow TCP all ports to 10.10.0.0/16 (VPC)
- **Outbound Rule 200**: Allow TCP ports 80,443 to 203.0.113.0/24 (Specific IPs)
- **Outbound Rule 32767**: Deny all remaining traffic

### Public Subnet NACL
- **Inbound Rule 100**: Allow TCP all ports from 10.10.0.0/16 (VPC)
- **Inbound Rule 200**: Allow TCP ports 80,443 from 203.0.113.0/24 (Specific IPs)
- **Inbound Rule 32767**: Deny all remaining traffic
- **Outbound Rule 100**: Allow TCP all ports to 10.10.0.0/16 (VPC)
- **Outbound Rule 200**: Allow TCP ports 1025-65535 to 203.0.113.0/24 (Specific IPs)
- **Outbound Rule 32767**: Deny all remaining traffic

### Firewall Subnet NACL
- **Inbound Rule 100**: Allow TCP all ports from 10.10.0.0/16 (VPC)
- **Inbound Rule 200**: Allow TCP ports 1025-65535 from 10.10.5.0/24 (Firewall IP)
- **Inbound Rule 32767**: Deny all remaining traffic
- **Outbound Rule 100**: Allow TCP all ports to 10.10.0.0/16 (VPC)
- **Outbound Rule 200**: Allow TCP all ports to 10.10.5.0/24 (Firewall IP)
- **Outbound Rule 32767**: Deny all remaining traffic

## IAM Permissions Required

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateSubnet",
        "ec2:DescribeSubnets",
        "ec2:CreateNetworkAcl",
        "ec2:DescribeNetworkAcls",
        "ec2:CreateNetworkAclEntry",
        "ec2:ReplaceNetworkAclEntry",
        "ec2:DeleteNetworkAclEntry",
        "ec2:CreateRouteTable",
        "ec2:DescribeRouteTables",
        "ec2:AssociateRouteTable",
        "ec2:DisassociateRouteTable"
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

### With VPC Module Outputs

```hcl
# Get VPC ID from VPC module
terraform apply -var="vpc_id=$(terraform -chdir=../terraform-module-sbx-vpc output -raw vpc_id)"
```

## Deployment Order

This module depends on:
1. ✅ **terraform-module-sbx-vpc** - Must be deployed first

This module is required for:
1. **terraform-module-sbx-securitygroup** - Needs subnet IDs
2. **terraform-module-sbx-firewall** - Needs firewall subnet ID
3. **CEPS-AWS-Sandbox** - Master orchestration

## Common Scenarios

### Adding Additional Subnets

To add more subnets (beyond the 3 initial ones), modify the module:

```hcl
# Add to main.tf
resource "aws_subnet" "custom_subnet" {
  vpc_id            = var.vpc_id
  cidr_block        = var.custom_subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-custom-subnet"
      Type = "Custom"
    }
  )
}
```

### Modifying NACL Rules

To update NACL rules for various scenarios:
- Add new IP ranges to `specific_ip_cidr` or `firewall_ip_cidr`
- Modify rule numbers (must be between 1-32766)
- Adjust port ranges as needed

Example: Allow HTTP (80) from a different range:
```hcl
ingress {
  protocol   = "tcp"
  rule_no    = 300
  action     = "allow"
  cidr_block = "192.168.0.0/16"  # New IP range
  from_port  = 80
  to_port    = 80
}
```

## Troubleshooting

### Subnet Creation Issues
- Verify VPC ID is correct
- Check CIDR blocks don't overlap with VPC CIDR
- Ensure availability zones are available in region

### NACL Rule Issues
- Rule numbers must be unique within inbound/outbound
- Rules are evaluated from lowest to highest number
- Deny rules (32767) act as catch-all default

### Route Table Association Issues
- Each subnet must have a route table
- Route table must be in same VPC as subnet
- Cannot associate same route table multiple times to same subnet

## Cleanup

To destroy all resources created by this module:

```bash
terraform destroy
```

## Support

For issues or questions:
1. Verify VPC exists and is accessible
2. Check CIDR block ranges don't conflict
3. Review NACL rule output for correctness
4. Check AWS service quotas for EC2 limits

## Version History

### v1.0.0
- Initial release
- Three-subnet architecture (Private, Public, Firewall)
- NACL rules implementation
- Route table management
- Production-ready configuration

## License

Internal Use Only - AWS Sandbox Automation Project

## Contributors

AWS Cloud Operations Team
