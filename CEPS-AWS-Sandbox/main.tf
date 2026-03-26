# ============================================================================
# Master Terraform File - CEPS-AWS-Sandbox
# ============================================================================
# Purpose: Orchestrate all sandbox modules for complete AWS environment
# Author: AON Sandbox Team
# Version: 1.0.0
# ============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment to use remote state storage
  backend "s3" {
    bucket       = "ashi0412-tfstate-bucket"
    key          = "sandbox/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(
      var.common_tags,
      {
        Project     = "AON-AWS-Sandbox"
        ManagedBy   = "Terraform-CEPS-AWS-Sandbox"
      }
    )
  }
}

# ============================================================================
# Module 1: VPC Creation
# ============================================================================
module "vpc" {
  source = "../terraform-module-sbx-vpc"

  aws_region     = var.aws_region
  environment    = var.environment
  vpc_cidr_block = var.vpc_cidr_block

  enable_s3_endpoint       = var.enable_s3_endpoint
  enable_dynamodb_endpoint = var.enable_dynamodb_endpoint

  vpc_flow_logs_retention_days = var.vpc_flow_logs_retention_days
  common_tags                   = var.common_tags
}

# ============================================================================
# Module 2: Subnets with NACL Rules
# ============================================================================
module "subnets" {
  source = "../terraform-module-sbx-subnet"

  aws_region       = var.aws_region
  environment      = var.environment
  vpc_id           = module.vpc.vpc_id

  private_subnet_cidr   = var.private_subnet_cidr
  public_subnet_cidr    = var.public_subnet_cidr
  firewall_subnet_cidr  = var.firewall_subnet_cidr
  specific_ip_cidr      = var.specific_ip_cidr
  firewall_ip_cidr      = var.firewall_ip_cidr

  common_tags = var.common_tags
}

# ============================================================================
# Module 3: Internet Gateway & Route Tables (Separate as not in subnet module)
# ============================================================================
resource "aws_internet_gateway" "main" {
  vpc_id = module.vpc.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-igw"
    }
  )
}

resource "aws_route" "public_internet_route" {
  route_table_id         = module.subnets.public_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# Helper module-like setup for route tables mentioned in subnets (this is simple local resource)
locals {
  subnets_routing = {
    private_route_table_id  = module.subnets.private_route_table_id
    public_route_table_id   = module.subnets.public_route_table_id
    firewall_route_table_id = module.subnets.firewall_route_table_id
  }
}

# Create local variable for routing
# (Subnets module already creates route tables, we're using them)

# ============================================================================
# Module 4: Security Groups
# ============================================================================
module "security_groups" {
  source = "../terraform-module-sbx-securitygroup"

  aws_region      = var.aws_region
  environment     = var.environment
  vpc_id          = module.vpc.vpc_id
  vpc_cidr_block  = var.vpc_cidr_block

  private_subnet_cidr = var.private_subnet_cidr
  specific_ip_cidr    = var.specific_ip_cidr
  firewall_ip_cidr    = var.firewall_ip_cidr

  enable_database_sg   = var.enable_database_sg
  enable_management_sg = var.enable_management_sg

  common_tags = var.common_tags
}

# ============================================================================
# Module 5: IAM & RBAC
# ============================================================================
module "rbac" {
  source = "../terraform-module-sbx-rbac"

  aws_region  = var.aws_region
  environment = var.environment

  enable_ec2_instance_role     = var.enable_ec2_instance_role
  enable_lambda_execution_role = var.enable_lambda_execution_role
  enable_rds_monitoring_role   = var.enable_rds_monitoring_role
  enable_cost_control_role     = var.enable_cost_control_role
  enable_sandbox_groups        = var.enable_sandbox_groups

  common_tags = var.common_tags
}

# ============================================================================
# Module 6: Network Firewall
# ============================================================================
# module "firewall" {
#   source = "../terraform-module-sbx-firewall"

#   aws_region        = var.aws_region
#   environment       = var.environment
#   vpc_id            = module.vpc.vpc_id
#   firewall_subnet_id = module.subnets.firewall_subnet_id
#   vpc_cidr_block    = var.vpc_cidr_block

#   firewall_logs_retention_days = var.firewall_logs_retention_days
#   enable_s3_logging            = var.firewall_enable_s3_logging
#   enable_firewall_alerts       = var.firewall_enable_alerts
#   sns_topic_arn                = module.automation.sns_topic_arn

#   stateless_rule_group_capacity = var.stateless_rule_group_capacity
#   stateful_rule_group_capacity  = var.stateful_rule_group_capacity
#   blocked_domains               = var.blocked_domains

#   common_tags = var.common_tags
# }

# ============================================================================
# Module 7: Cost Budget & Automation
# ============================================================================
module "automation" {
  source = "../terraform-module-sbx-automation"

  aws_region             = var.aws_region
  environment            = var.environment
  quarterly_budget_limit = var.quarterly_budget_limit

  budget_start_date = var.budget_start_date
  budget_end_date   = var.budget_end_date
  budget_alert_emails = var.budget_alert_emails

  enable_resource_shutdown = var.enable_resource_shutdown
  cloudwatch_period        = var.cloudwatch_period

  policy_seventy_percent     = var.policy_seventy_percent
  policy_eighty_five_percent = var.policy_eighty_five_percent
  iam_roles_to_target        = var.iam_roles_to_target

  common_tags = var.common_tags
}

# ============================================================================
# Outputs - VPC Information
# ============================================================================
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
  sensitive   = false
}

output "vpc_cidr_block" {
  description = "VPC CIDR Block"
  value       = module.vpc.vpc_cidr_block
}

output "vpc_arn" {
  description = "VPC ARN"
  value       = module.vpc.vpc_arn
}

# ============================================================================
# Outputs - Subnets Information
# ============================================================================
output "private_subnet_id" {
  description = "Private Subnet ID"
  value       = module.subnets.private_subnet_id
}

output "public_subnet_id" {
  description = "Public Subnet ID"
  value       = module.subnets.public_subnet_id
}

output "firewall_subnet_id" {
  description = "Firewall Subnet ID"
  value       = module.subnets.firewall_subnet_id
}

output "subnet_nacl_ids" {
  description = "Network ACL IDs for all subnets"
  value = {
    private_nacl_id   = module.subnets.private_nacl_id
    public_nacl_id    = module.subnets.public_nacl_id
    firewall_nacl_id  = module.subnets.firewall_nacl_id
  }
}

# ============================================================================
# Outputs - Security Groups
# ============================================================================
output "security_group_ids" {
  description = "Security Group IDs"
  value = {
    private_sg_id      = module.security_groups.private_sg_id
    public_sg_id       = module.security_groups.public_sg_id
    firewall_sg_id     = module.security_groups.firewall_sg_id
    database_sg_id     = module.security_groups.database_sg_id
    management_sg_id   = module.security_groups.management_sg_id
  }
}

# ============================================================================
# Outputs - IAM Roles & Policies
# ============================================================================
output "iam_roles" {
  description = "IAM Role ARNs"
  value = {
    ec2_instance_role_arn       = module.rbac.ec2_instance_role_arn
    lambda_execution_role_arn   = module.rbac.lambda_execution_role_arn
    rds_monitoring_role_arn     = module.rbac.rds_monitoring_role_arn
    cost_control_role_arn       = module.rbac.cost_control_role_arn
  }
}

output "iam_instance_profile" {
  description = "EC2 Instance Profile for launching instances"
  value       = module.rbac.ec2_instance_profile_name
}

# ============================================================================
# Outputs - Firewall Information
# ============================================================================
# output "firewall_id" {
#   description = "Network Firewall ID"
#   value       = module.firewall.firewall_id
# }

# output "firewall_arn" {
#   description = "Network Firewall ARN"
#   value       = module.firewall.firewall_arn
# }

# ============================================================================
# Outputs - Budget & Cost Control
# ============================================================================
output "budget_name" {
  description = "AWS Budget Name"
  value       = module.automation.budget_name
}

output "budget_limit_usd" {
  description = "Quarterly Budget Limit in USD"
  value       = module.automation.budget_limit_amount
}

output "budget_thresholds_usd" {
  description = "Budget Alert Thresholds in USD"
  value       = module.automation.budget_thresholds
}

output "sns_topic_arn" {
  description = "SNS Topic ARN for Budget Alerts"
  value       = module.automation.sns_topic_arn
}

output "sns_alert_emails" {
  description = "Email addresses receiving budget alerts"
  value       = var.budget_alert_emails
}

# ============================================================================
# Outputs - CloudWatch Monitoring
# ============================================================================
output "cloudwatch_alarms" {
  description = "CloudWatch Alarm ARNs"
  value = {
    budget_70_percent_arn  = module.automation.cloudwatch_alarm_70_arn
    budget_85_percent_arn  = module.automation.cloudwatch_alarm_85_arn
    budget_95_percent_arn  = module.automation.cloudwatch_alarm_95_arn
  }
}

# ============================================================================
# Outputs - Summary Outputs
# ============================================================================
output "sandbox_deployment_summary" {
  description = "Complete Sandbox Deployment Summary"
  value = {
    environment = var.environment
    region      = var.aws_region
    vpc_id      = module.vpc.vpc_id
    subnets = {
      private   = module.subnets.private_subnet_id
      public    = module.subnets.public_subnet_id
      firewall  = module.subnets.firewall_subnet_id
    }
    #firewall_id      = module.firewall.firewall_id
    budget_limit_usd = module.automation.budget_limit_amount
    budget_alerts    = {
      threshold_70  = module.automation.budget_thresholds.seventy_percent
      threshold_85  = module.automation.budget_thresholds.eighty_five_percent
      threshold_95  = module.automation.budget_thresholds.ninety_five_percent
    }
    sns_notification_emails = var.budget_alert_emails
  }
}
