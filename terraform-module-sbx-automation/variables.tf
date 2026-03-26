# ============================================================================
# Variables - terraform-module-sbx-automation
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

variable "quarterly_budget_limit" {
  description = "Quarterly budget limit in USD"
  type        = number
  default     = 1000

  validation {
    condition     = var.quarterly_budget_limit > 0
    error_message = "Budget limit must be greater than 0."
  }
}

variable "budget_start_date" {
  description = "Budget start date (YYYY-MM-DD_HH:MM)"
  type        = string
  default     = "2024-01-01_00:00"

  validation {
    condition     = can(regex("^\\d{4}-\\d{2}-\\d{2}_\\d{2}:\\d{2}$", var.budget_start_date))
    error_message = "Budget start date must be in YYYY-MM-DD_HH:MM format."
  }
}

variable "budget_end_date" {
  description = "Budget end date (YYYY-MM-DD_HH:MM)"
  type        = string
  default     = "2024-12-31_23:59"

  validation {
    condition     = can(regex("^\\d{4}-\\d{2}-\\d{2}_\\d{2}:\\d{2}$", var.budget_end_date))
    error_message = "Budget end date must be in YYYY-MM-DD_HH:MM format."
  }
}

variable "budget_alert_emails" {
  description = "Email addresses for budget alerts"
  type        = list(string)
  default     = ["ashishah0412@gmail.com"]

  validation {
    condition = alltrue([for email in var.budget_alert_emails : can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email))])
    error_message = "All values must be valid email addresses."
  }
}

variable "enable_resource_shutdown" {
  description = "Enable automatic resource shutdown at 95% threshold"
  type        = bool
  default     = true
}

variable "cloudwatch_period" {
  description = "CloudWatch alarm evaluation period in seconds"
  type        = number
  default     = 3600  # 1 hour

  validation {
    condition     = var.cloudwatch_period > 0
    error_message = "Period must be greater than 0."
  }
}

variable "policy_seventy_percent" {
  description = "IAM policy ARN to apply at 70% threshold"
  type        = string
  default     = ""
}

variable "policy_eighty_five_percent" {
  description = "IAM policy ARN to apply at 85% threshold"
  type        = string
  default     = ""
}

variable "iam_roles_to_target" {
  description = "IAM roles to target for budget actions"
  type        = list(string)
  default     = []
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "AWS-AWS-Sandbox"
    CostCenter  = "Engineering"
    Owner       = "CloudOps"
  }
}
