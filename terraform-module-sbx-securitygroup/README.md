# terraform-module-sbx-securitygroup

AWS Security Group Module for AON Sandbox Automation Project

## Overview

This Terraform module creates production-grade security groups for the Sandbox environment, implementing least-privilege access principles:

- **Private SG**: For internal compute resources (EC2, ECS, Lambda)
- **Public SG**: For public-facing resources (ALB, CloudFront)
- **Firewall SG**: For AWS Network Firewall resources
- **Database SG**: For RDS, Aurora, and other database services
- **Management SG**: For bastion hosts and management tools

## Features

- **Security-First Design**: Implements least-privilege access
- **Multiple Resource Types**: Separate security groups for different resource categories
- **Inter-SG Communication**: Rules for cross-security group communication
- **Flexible IP Ranges**: Configurable CIDR blocks for external and firewall access
- **Production-Ready**: Includes DNS, HTTPS, SSH/RDP rules
- **Comprehensive Tagging**: For resource organization and cost tracking

## prerequisites

- Terraform >= 1.0
- AWS Provider >= 5.0
- AWS Account with appropriate IAM permissions
- VPC already created (use terraform-module-sbx-vpc)
- VPC ID available from VPC module outputs

## Usage

### Basic Usage

```hcl
module "security_groups" {
  source = "path/to/terraform-module-sbx-securitygroup"

  aws_region      = "us-east-1"
  environment     = "Sandbox"
  vpc_id          = module.vpc.vpc_id
  vpc_cidr_block  = "10.10.0.0/16"

  private_subnet_cidr = "10.10.1.0/24"
  specific_ip_cidr    = "203.0.113.0/24"
  firewall_ip_cidr    = "10.10.5.0/24"

  common_tags = {
    Project     = "AON-AWS-Sandbox"
    CostCenter  = "Engineering"
    Owner       = "CloudOps"
  }
}
```

### With Optional Flags

```hcl
module "security_groups" {
  source = "path/to/terraform-module-sbx-securitygroup"

  aws_region           = "us-east-1"
  environment          = "Sandbox"
  vpc_id               = module.vpc.vpc_id
  vpc_cidr_block       = "10.10.0.0/16"
  
  enable_database_sg   = true   # Include database security group
  enable_management_sg = true   # Include management/bastion security group

  private_subnet_cidr  = "10.10.1.0/24"
  specific_ip_cidr     = "203.0.113.0/24"
  firewall_ip_cidr     = "10.10.5.0/24"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `aws_region` | AWS region for deployment | `string` | `"us-east-1"` | No |
| `environment` | Environment name for tagging | `string` | `"Sandbox"` | No |
| `vpc_id` | VPC ID for security group creation | `string` | N/A | **Yes** |
| `vpc_cidr_block` | VPC CIDR block | `string` | `"10.10.0.0/16"` | No |
| `private_subnet_cidr` | CIDR block for private subnet | `string` | `"10.10.1.0/24"` | No |
| `specific_ip_cidr` | CIDR block for external access | `string` | `"203.0.113.0/24"` | No |
| `firewall_ip_cidr` | CIDR block for firewall device | `string` | `"10.10.5.0/24"` | No |
| `enable_database_sg` | Enable database security group | `bool` | `true` | No |
| `enable_management_sg` | Enable management security group | `bool` | `true` | No |
| `common_tags` | Common tags for all resources | `map(string)` | See defaults | No |

## Outputs

| Name | Description |
|------|-------------|
| `private_sg_id` | Private Security Group ID |
| `private_sg_arn` | Private Security Group ARN |
| `public_sg_id` | Public Security Group ID |
| `public_sg_arn` | Public Security Group ARN |
| `firewall_sg_id` | Firewall Security Group ID |
| `firewall_sg_arn` | Firewall Security Group ARN |
| `database_sg_id` | Database Security Group ID |
| `database_sg_arn` | Database Security Group ARN |
| `management_sg_id` | Management/Bastion Security Group ID |
| `management_sg_arn` | Management/Bastion Security Group ARN |
| `all_security_groups` | Map of all security group IDs |

## Security Group Details

### Private SG (Compute Resources)
**Ingress:**
- TCP all ports from VPC (10.10.0.0/16)
- TCP 80, 443 from Specific IPs (203.0.113.0/24)

**Egress:**
- TCP all ports to VPC (10.10.0.0/16)
- TCP 443 to Specific IPs (203.0.113.0/24)
- UDP 53 (DNS) to anywhere
- TCP 443 (HTTPS) to anywhere

### Public SG (Public-Facing Resources)
**Ingress:**
- TCP all ports from VPC (10.10.0.0/16)
- TCP 80 from Specific IPs (203.0.113.0/24)
- TCP 443 from Specific IPs (203.0.113.0/24)

**Egress:**
- TCP all ports to VPC (10.10.0.0/16)
- TCP all ports to Specific IPs (203.0.113.0/24)
- UDP 53 (DNS) to anywhere
- TCP 443 (HTTPS) to anywhere

### Firewall SG
**Ingress:**
- TCP all ports from VPC (10.10.0.0/16)
- TCP 1025-65535 from Firewall IPs (10.10.5.0/24)

**Egress:**
- TCP all ports to VPC (10.10.0.0/16)
- TCP all ports to Firewall IPs (10.10.5.0/24)
- UDP 53 (DNS) to anywhere

### Database SG
**Ingress:**
- TCP 3306 (MySQL) from Private subnet (10.10.1.0/24)
- TCP 5432 (PostgreSQL) from Private subnet (10.10.1.0/24)
- TCP all ports from VPC (10.10.0.0/16)

**Egress:**
- All traffic to anywhere

### Management/Bastion SG
**Ingress:**
- TCP 22 (SSH) from Specific IPs (203.0.113.0/24)
- TCP 3389 (RDP) from Specific IPs (203.0.113.0/24)
- All traffic from VPC (10.10.0.0/16)

**Egress:**
- All traffic to anywhere

## Inter-SG Communication Rules

- **Private → Database**: Allow TCP 3306-5432 for database connections
- **Public → Private**: Allow all TCP traffic for application communication
- **Private ← Public**: Allow inbound traffic from public SG

## IAM Permissions Required

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateSecurityGroup",
        "ec2:DescribeSecurityGroups",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:AuthorizeSecurityGroupEgress",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupEgress",
        "ec2:DeleteSecurityGroup",
        "ec2:CreateSecurityGroupRule",
        "ec2:DeleteSecurityGroupRule"
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

## Deployment Order

This module depends on:
1. **terraform-module-sbx-vpc** - Must be deployed first
2. **terraform-module-sbx-subnet** - Optional (for subnet CIDR references)

This module is required for:
1. **EC2, RDS, ECS, Lambda** deployments
2. **terraform-module-sbx-firewall** - May reference these SGs

## Network Diagram

```
┌──────────────────────────────────────────────┐
│        VPC: 10.10.0.0/16                     │
│                                              │
│ ┌─────────────────────────────────────────┐ │
│ │ Private Subnet: 10.10.1.0/24            │ │
│ │ ┌──────────┐     ┌──────────┐          │ │
│ │ │ EC2      │     │ Lambda   │          │ │
│ │ │ Private  │────→│ Private  │          │ │
│ │ │ SG       │     │ SG       │          │ │
│ │ └──────────┘     └──────────┘          │ │
│ │       ↓                                  │ │
│ │   ┌──────────┐                         │ │
│ │   │ RDS      │ ← Database SG           │ │
│ │   └──────────┘                         │ │
│ └─────────────────────────────────────────┘ │
│                     ↑                        │
│ ┌─────────────────────────────────────────┐ │
│ │ Public Subnet: 10.10.2.0/24             │ │
│ │ ┌──────────┐     ┌──────────┐          │ │
│ │ │ ALB      │     │ CloudFront          │ │
│ │ │ Public   │────→│ Public SG │         │ │
│ │ │ SG       │     │          │         │ │
│ │ └──────────┘     └──────────┘          │ │
│ └─────────────────────────────────────────┘ │
│                     ↑                        │
│                203.0.113.0/24               │
│                (Specific IPs)               │
│                                              │
│ ┌─────────────────────────────────────────┐ │
│ │ Firewall Subnet: 10.10.5.0/24           │ │
│ │ ┌──────────────┐                       │ │
│ │ │ Network FW   │ ← Firewall SG         │ │
│ │ │ 10.10.5.0/24 │                       │ │
│ │ └──────────────┘                       │ │
│ └─────────────────────────────────────────┘ │
└──────────────────────────────────────────────┘
```

## Common Scenarios

### Adding Custom Ingress Rules

To add custom rules to a security group:

```hcl
resource "aws_security_group_rule" "custom_rule" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8"]
  security_group_id = module.security_groups.private_sg_id
  description       = "Allow port 8080 from internal"
}
```

### Allowing NFS Traffic

For EFS access:

```hcl
resource "aws_security_group_rule" "efs_nfs" {
  type              = "ingress"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  cidr_blocks       = ["10.10.1.0/24"]  # Private subnet
  security_group_id = module.security_groups.private_sg_id
  description       = "Allow NFS from Private subnet"
}
```

### Allowing Database Access from Specific SG

```hcl
resource "aws_security_group_rule" "db_from_app" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = module.security_groups.database_sg_id
  source_security_group_id = module.security_groups.private_sg_id
  description              = "Allow PostgreSQL from App SG"
}
```

## Troubleshooting

### "Security group does not exist" Error
- Verify VPC ID is correct
- Ensure VPC exists before creating security groups
- Check AWS permissions

### Rules Not Working
- Verify security group is attached to resource
- Check NACLs also allow the traffic
- Review both ingress and egress rules
- Verify CIDR blocks are correct

### Connectivity Issues
- Check both source and destination security groups
- Verify Network ACLs allow traffic
- Test with `nc` or `telnet` from source to destination
- Review AWS VPC Flow Logs

## Cleanup

To destroy all security groups created by this module:

```bash
terraform destroy
```

## Version History

### v1.0.0
- Initial release
- Five security groups (Private, Public, Firewall, Database, Management)
- Inter-SG communication rules
- Production-ready configuration

## License

Internal Use Only - AON Sandbox Automation Project

## Contributors

AON Cloud Operations Team
