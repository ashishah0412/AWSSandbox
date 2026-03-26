# ============================================================================
# Variables - terraform-module-sbx-firewall
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

variable "vpc_id" {
  description = "VPC ID where firewall will be deployed"
  type        = string

  validation {
    condition     = can(regex("^vpc-[a-z0-9]+$", var.vpc_id))
    error_message = "VPC ID must be a valid VPC ID."
  }
}

variable "firewall_subnet_id" {
  description = "Subnet ID for firewall deployment"
  type        = string

  validation {
    condition     = can(regex("^subnet-[a-z0-9]+$", var.firewall_subnet_id))
    error_message = "Subnet ID must be a valid Subnet ID."
  }
}

variable "vpc_cidr_block" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.10.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr_block, 0))
    error_message = "VPC CIDR block must be a valid CIDR range."
  }
}

variable "firewall_logs_retention_days" {
  description = "CloudWatch Logs retention in days"
  type        = number
  default     = 30

  validation {
    condition     = var.firewall_logs_retention_days > 0
    error_message = "Retention days must be greater than 0."
  }
}

variable "enable_s3_logging" {
  description = "Enable S3 bucket for firewall logs"
  type        = bool
  default     = false
}

variable "enable_firewall_alerts" {
  description = "Enable EventBridge rule for firewall alerts"
  type        = bool
  default     = true
}

variable "sns_topic_arn" {
  description = "SNS Topic ARN for firewall alerts"
  type        = string
  default     = ""
}

variable "stateless_rule_group_capacity" {
  description = "Capacity for stateless rule group"
  type        = number
  default     = 100
}

variable "stateful_rule_group_capacity" {
  description = "Capacity for stateful rule group"
  type        = number
  default     = 1000
}

variable "blocked_domains" {
  description = "List of domains to block"
  type        = list(string)
  default     = []
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
