# ============================================================================
# Variables - terraform-module-sbx-subnet
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
  description = "VPC ID where subnets will be created"
  type        = string

  validation {
    condition     = can(regex("^vpc-[a-z0-9]+$", var.vpc_id))
    error_message = "VPC ID must be a valid VPC ID."
  }
}

variable "private_subnet_cidr" {
  description = "CIDR block for Private Subnet"
  type        = string
  default     = "10.10.1.0/24"

  validation {
    condition     = can(cidrhost(var.private_subnet_cidr, 0))
    error_message = "Private Subnet CIDR must be a valid CIDR range."
  }
}

variable "public_subnet_cidr" {
  description = "CIDR block for Public Subnet"
  type        = string
  default     = "10.10.2.0/24"

  validation {
    condition     = can(cidrhost(var.public_subnet_cidr, 0))
    error_message = "Public Subnet CIDR must be a valid CIDR range."
  }
}

variable "firewall_subnet_cidr" {
  description = "CIDR block for Firewall Subnet"
  type        = string
  default     = "10.10.5.0/24"

  validation {
    condition     = can(cidrhost(var.firewall_subnet_cidr, 0))
    error_message = "Firewall Subnet CIDR must be a valid CIDR range."
  }
}

variable "specific_ip_cidr" {
  description = "CIDR block for external/specific IP access (e.g., 203.0.113.0/24)"
  type        = string
  default     = "203.0.113.0/24"

  validation {
    condition     = can(cidrhost(var.specific_ip_cidr, 0))
    error_message = "Specific IP CIDR must be a valid CIDR range."
  }
}

variable "firewall_ip_cidr" {
  description = "CIDR block for firewall device IP range (e.g., 10.10.5.0/24)"
  type        = string
  default     = "10.10.5.0/24"

  validation {
    condition     = can(cidrhost(var.firewall_ip_cidr, 0))
    error_message = "Firewall IP CIDR must be a valid CIDR range."
  }
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
