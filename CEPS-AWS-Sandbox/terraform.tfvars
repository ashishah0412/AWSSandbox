# ============================================================================
# Terraform Variables - CEPS-AWS-Sandbox Master Module
# ============================================================================

aws_region = "us-east-1"
environment = "Sandbox"

# ============================================================================
# VPC Configuration
# ============================================================================

vpc_cidr_block                = "10.10.0.0/16"
enable_s3_endpoint            = true
enable_dynamodb_endpoint      = true
vpc_flow_logs_retention_days  = 30

# ============================================================================
# Subnet Configuration - Multi-AZ & Dynamic
# ============================================================================

# Number of Availability Zones to use (1-4)
num_availability_zones = 2

# Number of private subnets to create
num_private_subnets = 2

# Number of public subnets to create
num_public_subnets = 2

# Private subnet CIDR blocks (one per subnet)
private_subnet_cidr_blocks = [
  "10.10.1.0/24",
  "10.10.2.0/24"
]

# Public subnet CIDR blocks (one per subnet)
public_subnet_cidr_blocks = [
  "10.10.11.0/24",
  "10.10.12.0/24"
]

# Firewall subnet CIDR (permanent, always created)
firewall_subnet_cidr = "10.10.21.0/24"

# Specific/External IP CIDR for NACL rules
specific_ip_cidr = "203.0.113.0/24"

# Firewall IP CIDR
firewall_ip_cidr = "10.10.21.0/24"

# ============================================================================
# Security Group Configuration
# ============================================================================

enable_database_sg   = true
enable_management_sg = true

# ============================================================================
# RBAC Configuration
# ============================================================================

enable_ec2_instance_role      = true
enable_lambda_execution_role  = true
enable_rds_monitoring_role    = true
enable_cost_control_role      = true
enable_sandbox_groups         = true

# ============================================================================
# Firewall Configuration
# ============================================================================

firewall_logs_retention_days   = 30
firewall_enable_s3_logging     = false
firewall_enable_alerts         = true
stateless_rule_group_capacity  = 100
stateful_rule_group_capacity   = 1000
blocked_domains                = []

# ============================================================================
# Budget & Cost Control Configuration
# ============================================================================

quarterly_budget_limit = 1000
budget_start_date      = "2026-01-01_00:00"
budget_end_date        = "2026-12-31_23:59"

# Update these email addresses for your notifications
budget_alert_emails = [
  "ashishah0412@gmail.com"
]

enable_resource_shutdown = false
cloudwatch_period        = 3600

# Leave empty to auto-create policies, or provide existing policy ARNs
policy_seventy_percent      = ""
policy_eighty_five_percent  = ""
iam_roles_to_target         = []

# ============================================================================
# Common Tags
# ============================================================================

common_tags = {
  Project     = "AWS-AWS-Sandbox"
  CostCenter  = "Engineering"
  Owner       = "CloudOps"
  CreatedBy   = "Terraform"
  Environment = "Sandbox"
}
