# terraform-module-sbx-subnet

AWS Subnet Module for AWS Sandbox Automation Project - Multi-AZ & Dynamic Configuration

## Overview

This Terraform module creates **dynamic, multi-AZ production-grade subnets** with Network ACLs (NACLs) for the Sandbox environment. It supports:

- **Multi-AZ Deployment**: Deploy across 1-4 Availability Zones for fault tolerance
- **Dynamic Subnet Counts**: Create 1-4 private and 1-4 public subnets independently
- **Automatic AZ Distribution**: Subnets automatically distributed across AZs using round-robin
- **Static Firewall Subnet**: Firewall subnet always created (1 per deployment)
- **Per-Subnet NACLs & Route Tables**: Each subnet gets its own NACL and route table
- **Flexible CIDR Blocks**: Configurable CIDR blocks via list variables

### Subnet Types

- **Private Subnets**: For internal resources with restricted access (1-4 per deployment)
- **Public Subnets**: For public-facing resources, internet gateway enabled (1-4 per deployment)
- **Firewall Subnet**: For AWS Network Firewall resources (always 1, static)

Each subnet includes:
- Dedicated Network ACL (NACL) with security best practices
- Dedicated route table for traffic routing
- Automatic AZ assignment and tagging
- Comprehensive tagging for resource management

## Features

- **Dynamic Multi-AZ Architecture**: Deploy across multiple availability zones
- **Scalable Subnet Configuration**: Add/remove subnets without code changes
- **Automatic AZ Distribution**: Round-robin assignment across availability zones
- **Security-First Design**: Default-deny NACL rules with allow-list approach
- **Per-Subnet NACLs**: Each subnet type has its own network ACL rules:
  - Internal VPC communication (10.10.0.0/16)
  - External access from specific IP range (203.0.113.0/24)
  - Firewall-specific communication (10.10.21.0/24)
- **Route Table Management**: Dedicated route table per subnet
- **Flexible Configuration**: Use count meta-argument for dynamic resource creation
- **Comprehensive Outputs**: Splat syntax outputs for resource lists organized by type/AZ

## Prerequisites

- Terraform >= 1.0
- AWS Provider >= 5.0
- AWS Account with appropriate IAM permissions
- VPC already created (use terraform-module-sbx-vpc)
- VPC ID available from VPC module outputs

## Usage

### Basic Multi-AZ Usage (2 AZs, 2 Private, 2 Public)

```hcl
module "subnets" {
  source = "path/to/terraform-module-sbx-subnet"

  aws_region = "us-east-1"
  environment = "Sandbox"
  vpc_id     = module.vpc.vpc_id

  # Multi-AZ Configuration
  num_availability_zones = 2             # Deploy across 2 AZs
  num_private_subnets    = 2             # Create 2 private subnets
  num_public_subnets     = 2             # Create 2 public subnets

  # Private Subnet CIDR blocks
  private_subnet_cidr_blocks = [
    "10.10.1.0/24",                      # Private subnet in AZ-1
    "10.10.2.0/24"                       # Private subnet in AZ-2
  ]

  # Public Subnet CIDR blocks
  public_subnet_cidr_blocks = [
    "10.10.11.0/24",                     # Public subnet in AZ-1
    "10.10.12.0/24"                      # Public subnet in AZ-2
  ]

  # Static firewall subnet (always 1)
  firewall_subnet_cidr = "10.10.21.0/24"
  specific_ip_cidr     = "203.0.113.0/24"
  firewall_ip_cidr     = "10.10.21.0/24"

  common_tags = {
    Project     = "AWS-AWS-Sandbox"
    CostCenter  = "Engineering"
    Owner       = "CloudOps"
  }
}
```

### High-Availability Configuration (3 AZs, 3 Subnets Each)

```hcl
module "subnets" {
  source = "path/to/terraform-module-sbx-subnet"

  aws_region = "us-east-1"
  environment = "Sandbox"
  vpc_id     = module.vpc.vpc_id

  num_availability_zones = 3
  num_private_subnets    = 3
  num_public_subnets     = 3

  private_subnet_cidr_blocks = [
    "10.10.1.0/24",
    "10.10.2.0/24",
    "10.10.3.0/24"
  ]

  public_subnet_cidr_blocks = [
    "10.10.11.0/24",
    "10.10.12.0/24",
    "10.10.13.0/24"
  ]

  firewall_subnet_cidr = "10.10.21.0/24"
  specific_ip_cidr     = "203.0.113.0/24"
  firewall_ip_cidr     = "10.10.21.0/24"
}
```

### Single-AZ Configuration (Development/Testing)

```hcl
module "subnets" {
  source = "path/to/terraform-module-sbx-subnet"

  aws_region = "us-east-1"
  environment = "Sandbox"
  vpc_id     = module.vpc.vpc_id

  num_availability_zones = 1              # Single AZ
  num_private_subnets    = 1              # Single private subnet
  num_public_subnets     = 1              # Single public subnet

  private_subnet_cidr_blocks = [
    "10.10.1.0/24"
  ]

  public_subnet_cidr_blocks = [
    "10.10.11.0/24"
  ]

  firewall_subnet_cidr = "10.10.21.0/24"
  specific_ip_cidr     = "203.0.113.0/24"
  firewall_ip_cidr     = "10.10.21.0/24"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `aws_region` | AWS region for deployment | `string` | `"us-east-1"` | No |
| `environment` | Environment name for tagging | `string` | `"Sandbox"` | No |
| `vpc_id` | VPC ID for subnet creation | `string` | N/A | **Yes** |
| `num_availability_zones` | Number of AZs to use (1-4) | `number` | `2` | No |
| `num_private_subnets` | Number of private subnets (1-4) | `number` | `2` | No |
| `num_public_subnets` | Number of public subnets (1-4) | `number` | `2` | No |
| `private_subnet_cidr_blocks` | List of private subnet CIDR blocks | `list(string)` | `["10.10.1.0/24", "10.10.2.0/24"]` | No |
| `public_subnet_cidr_blocks` | List of public subnet CIDR blocks | `list(string)` | `["10.10.11.0/24", "10.10.12.0/24"]` | No |
| `firewall_subnet_cidr` | CIDR block for Firewall Subnet (static) | `string` | `"10.10.21.0/24"` | No |
| `specific_ip_cidr` | CIDR block for external access | `string` | `"203.0.113.0/24"` | No |
| `firewall_ip_cidr` | CIDR block for firewall device | `string` | `"10.10.21.0/24"` | No |
| `common_tags` | Common tags for all resources | `map(string)` | See defaults | No |

## Outputs

### Private Subnet Outputs (Lists)

| Name | Description |
|------|-------------|
| `private_subnet_ids` | List of private subnet IDs |
| `private_subnet_arns` | List of private subnet ARNs |
| `private_subnet_cidrs` | List of private subnet CIDR blocks |
| `private_subnet_azs` | List of private subnet availability zones |

### Public Subnet Outputs (Lists)

| Name | Description |
|------|-------------|
| `public_subnet_ids` | List of public subnet IDs |
| `public_subnet_arns` | List of public subnet ARNs |
| `public_subnet_cidrs` | List of public subnet CIDR blocks |
| `public_subnet_azs` | List of public subnet availability zones |

### Firewall Subnet Outputs (Static)

| Name | Description |
|------|-------------|
| `firewall_subnet_id` | Firewall subnet ID (always 1) |
| `firewall_subnet_arn` | Firewall subnet ARN |
| `firewall_subnet_cidr` | Firewall subnet CIDR block |
| `firewall_subnet_az` | Firewall subnet availability zone |

### Network ACL Outputs

| Name | Description |
|------|-------------|
| `private_nacl_ids` | List of private NACL IDs |
| `public_nacl_ids` | List of public NACL IDs |
| `firewall_nacl_id` | Firewall NACL ID (static) |

### Route Table Outputs

| Name | Description |
|------|-------------|
| `private_route_table_ids` | List of private route table IDs |
| `public_route_table_ids` | List of public route table IDs |
| `firewall_route_table_id` | Firewall route table ID (static) |

### Summary Outputs

| Name | Description |
|------|-------------|
| `subnets_by_az` | Map of subnets organized by availability zone |
| `subnet_count_summary` | Summary of subnet configuration and counts |
| `all_subnet_ids` | All subnet IDs organized by type |
| `all_route_table_ids` | All route table IDs organized by type |

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
