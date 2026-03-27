# ============================================================================
# Terraform Values - terraform-module-sbx-subnet
# Multi-AZ & Dynamic Subnets
# ============================================================================

aws_region             = "us-east-1"
environment            = "Sandbox"

# Multi-AZ Configuration
num_availability_zones = 2
num_private_subnets    = 2
num_public_subnets     = 2

# Subnet CIDR blocks (lists for dynamic configuration)
private_subnet_cidr_blocks = [
  "10.10.1.0/24",
  "10.10.2.0/24"
]

public_subnet_cidr_blocks = [
  "10.10.11.0/24",
  "10.10.12.0/24"
]

# Static CIDR blocks (firewall is always one subnet)
firewall_subnet_cidr = "10.10.21.0/24"
specific_ip_cidr     = "203.0.113.0/24"   # External/Specific IP CIDR
firewall_ip_cidr     = "10.10.21.0/24"    # Firewall device IP range

common_tags = {
  Project     = "AWS-AWS-Sandbox"
  CostCenter  = "Engineering"
  Owner       = "CloudOps"
  CreatedBy   = "Terraform"
}
