# ============================================================================
# Variables - CEPS-AWS-Sandbox Master Module
# ============================================================================

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "Sandbox"
}

# ============================================================================
# VPC Module Variables
# ============================================================================

variable "vpc_cidr_block" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.10.0.0/16"
}

variable "enable_s3_endpoint" {
  description = "Enable S3 Gateway VPC Endpoint"
  type        = bool
  default     = true
}

variable "enable_dynamodb_endpoint" {
  description = "Enable DynamoDB Gateway VPC Endpoint"
  type        = bool
  default     = true
}

variable "vpc_flow_logs_retention_days" {
  description = "VPC Flow Logs retention in days"
  type        = number
  default     = 30
}

# ============================================================================
# Subnet Module Variables
# ============================================================================

variable "private_subnet_cidr" {
  description = "Private Subnet CIDR"
  type        = string
  default     = "10.10.1.0/24"
}

variable "public_subnet_cidr" {
  description = "Public Subnet CIDR"
  type        = string
  default     = "10.10.2.0/24"
}

variable "firewall_subnet_cidr" {
  description = "Firewall Subnet CIDR"
  type        = string
  default     = "10.10.5.0/24"
}

variable "specific_ip_cidr" {
  description = "Specific/External IP CIDR for NACL rules"
  type        = string
  default     = "203.0.113.0/24"
}

variable "firewall_ip_cidr" {
  description = "Firewall Device IP CIDR"
  type        = string
  default     = "10.10.5.0/24"
}

# ============================================================================
# Security Group Module Variables
# ============================================================================

variable "enable_database_sg" {
  description = "Enable Database Security Group"
  type        = bool
  default     = true
}

variable "enable_management_sg" {
  description = "Enable Management Security Group"
  type        = bool
  default     = true
}

# ============================================================================
# RBAC Module Variables
# ============================================================================

variable "enable_ec2_instance_role" {
  description = "Enable EC2 Instance Role"
  type        = bool
  default     = true
}

variable "enable_lambda_execution_role" {
  description = "Enable Lambda Execution Role"
  type        = bool
  default     = true
}

variable "enable_rds_monitoring_role" {
  description = "Enable RDS Monitoring Role"
  type        = bool
  default     = true
}

variable "enable_cost_control_role" {
  description = "Enable Cost Control Role"
  type        = bool
  default     = true
}

variable "enable_sandbox_groups" {
  description = "Enable IAM Groups for Developers/Viewers"
  type        = bool
  default     = true
}

# ============================================================================
# Firewall Module Variables
# ============================================================================

variable "firewall_logs_retention_days" {
  description = "Firewall logs retention in days"
  type        = number
  default     = 30
}

variable "firewall_enable_s3_logging" {
  description = "Enable S3 logging for firewall"
  type        = bool
  default     = false
}

variable "firewall_enable_alerts" {
  description = "Enable firewall alerts via EventBridge"
  type        = bool
  default     = true
}

variable "stateless_rule_group_capacity" {
  description = "Stateless rule group capacity"
  type        = number
  default     = 100
}

variable "stateful_rule_group_capacity" {
  description = "Stateful rule group capacity"
  type        = number
  default     = 1000
}

variable "blocked_domains" {
  description = "List of domains to block in firewall"
  type        = list(string)
  default     = []
}

# ============================================================================
# Budget & Automation Module Variables
# ============================================================================

variable "quarterly_budget_limit" {
  description = "Quarterly budget limit in USD"
  type        = number
  default     = 1000
}

variable "budget_start_date" {
  description = "Budget start date (YYYY-MM-DD_HH:MM)"
  type        = string
  default     = "2024-01-01_00:00"
}

variable "budget_end_date" {
  description = "Budget end date (YYYY-MM-DD_HH:MM)"
  type        = string
  default     = "2024-12-31_23:59"
}

variable "budget_alert_emails" {
  description = "Email addresses for budget alerts"
  type        = list(string)
  default     = ["ashishah0412@gmail.com"]
}

variable "enable_resource_shutdown" {
  description = "Enable automatic resource shutdown at 95% threshold"
  type        = bool
  default     = true
}

variable "cloudwatch_period" {
  description = "CloudWatch alarm evaluation period (seconds)"
  type        = number
  default     = 3600
}

variable "policy_seventy_percent" {
  description = "IAM policy ARN for 70% threshold"
  type        = string
  default     = ""
}

variable "policy_eighty_five_percent" {
  description = "IAM policy ARN for 85% threshold"
  type        = string
  default     = ""
}

variable "iam_roles_to_target" {
  description = "IAM roles to target for budget actions"
  type        = list(string)
  default     = []
}

# ============================================================================
# Common Tags
# ============================================================================

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "AON-AWS-Sandbox"
    CostCenter  = "Engineering"
    Owner       = "CloudOps"
    CreatedBy   = "Terraform"
    Environment = "Sandbox"
  }
}
