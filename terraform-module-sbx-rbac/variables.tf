# ============================================================================
# Variables - terraform-module-sbx-rbac
# ============================================================================

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"

  validation {
    condition = can(regex("^[a-z]{2}-[a-z]+-\\d{1}$", var.aws_region))
    error_message = "AWS region must be a valid region format (e.g., us-east-1)."
  }
}

variable "environment" {
  description = "Environment name for tagging and naming resources"
  type        = string
  default     = "Sandbox"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,50}$", var.environment))
    error_message = "Environment must be alphanumeric and hyphens only, max 50 characters."
  }
}

variable "enable_ec2_instance_role" {
  description = "Enable creation of EC2 instance role"
  type        = bool
  default     = true
}

variable "enable_lambda_execution_role" {
  description = "Enable creation of Lambda execution role"
  type        = bool
  default     = true
}

variable "enable_rds_monitoring_role" {
  description = "Enable creation of RDS monitoring role"
  type        = bool
  default     = true
}

variable "enable_cost_control_role" {
  description = "Enable creation of cost control role"
  type        = bool
  default     = true
}

variable "enable_sandbox_groups" {
  description = "Enable creation of IAM groups (developers, viewers)"
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "AON-AWS-Sandbox"
    CostCenter  = "Engineering"
    Owner       = "CloudOps"
  }
}
