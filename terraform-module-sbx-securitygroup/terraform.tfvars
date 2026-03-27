# ============================================================================
# Terraform Values - terraform-module-sbx-securitygroup
# ============================================================================

aws_region           = "us-east-1"
environment          = "Sandbox"
vpc_id               = "vpc-xxxxxxxxxxxxx" # Replace with actual VPC ID
vpc_cidr_block       = "10.10.0.0/16"

# Private subnet CIDR blocks (list format for multi-AZ support)
private_subnet_cidr = [
  "10.10.1.0/24",
  "10.10.2.0/24"
]

specific_ip_cidr     = "203.0.113.0/24"
firewall_ip_cidr     = "10.10.21.0/24"
enable_database_sg   = true
enable_management_sg = true

common_tags = {
  Project     = "AWS-AWS-Sandbox"
  CostCenter  = "Engineering"
  Owner       = "CloudOps"
  CreatedBy   = "Terraform"
}
