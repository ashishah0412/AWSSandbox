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

# ============================================================================
# Multi-AZ & Dynamic Subnet Configuration
# ============================================================================

variable "num_availability_zones" {
  description = "Number of Availability Zones to use for multi-AZ deployment (1-4)"
  type        = number
  default     = 2

  validation {
    condition     = var.num_availability_zones >= 1 && var.num_availability_zones <= 4
    error_message = "Number of AZs must be between 1 and 4"
  }
}

variable "num_private_subnets" {
  description = "Number of private subnets to create (one per availability zone)"
  type        = number
  default     = 2

  validation {
    condition     = var.num_private_subnets >= 1 && var.num_private_subnets <= 4
    error_message = "Number of private subnets must be between 1 and 4"
  }
}

variable "num_public_subnets" {
  description = "Number of public subnets to create (one per availability zone)"
  type        = number
  default     = 2

  validation {
    condition     = var.num_public_subnets >= 1 && var.num_public_subnets <= 4
    error_message = "Number of public subnets must be between 1 and 4"
  }
}

variable "private_subnet_cidr_blocks" {
  description = "List of CIDR blocks for private subnets (one per subnet in order)"
  type        = list(string)
  default     = ["10.10.1.0/24", "10.10.2.0/24"]

  validation {
    condition     = length(var.private_subnet_cidr_blocks) >= 1 && length(var.private_subnet_cidr_blocks) <= 4
    error_message = "Must provide 1 to 4 private subnet CIDR blocks"
  }

  validation {
    condition     = alltrue([for cidr in var.private_subnet_cidr_blocks : can(cidrhost(cidr, 0))])
    error_message = "All private subnet CIDRs must be valid CIDR ranges"
  }
}

variable "public_subnet_cidr_blocks" {
  description = "List of CIDR blocks for public subnets (one per subnet in order)"
  type        = list(string)
  default     = ["10.10.11.0/24", "10.10.12.0/24"]

  validation {
    condition     = length(var.public_subnet_cidr_blocks) >= 1 && length(var.public_subnet_cidr_blocks) <= 4
    error_message = "Must provide 1 to 4 public subnet CIDR blocks"
  }

  validation {
    condition     = alltrue([for cidr in var.public_subnet_cidr_blocks : can(cidrhost(cidr, 0))])
    error_message = "All public subnet CIDRs must be valid CIDR ranges"
  }
}

variable "firewall_subnet_cidr" {
  description = "CIDR block for Firewall Subnet (permanent, always 1 subnet)"
  type        = string
  default     = "10.10.21.0/24"

  validation {
    condition     = can(cidrhost(var.firewall_subnet_cidr, 0))
    error_message = "Firewall Subnet CIDR must be a valid CIDR range"
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
    Project     = "AWS-AWS-Sandbox"
    CostCenter  = "Engineering"
    Owner       = "CloudOps"
  }
}
