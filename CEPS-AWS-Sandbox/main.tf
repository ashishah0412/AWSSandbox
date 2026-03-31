# ============================================================================
# Master Terraform File - CEPS-AWS-Sandbox
# ============================================================================
# Purpose: Orchestrate all sandbox modules for complete AWS environment
# Author: AWS Sandbox Team
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
        Project     = "AWS-AWS-Sandbox"
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

  availability_zones           = var.availability_zones
  enable_s3_endpoint           = var.enable_s3_endpoint
  enable_dynamodb_endpoint     = var.enable_dynamodb_endpoint

  vpc_flow_logs_retention_days = var.vpc_flow_logs_retention_days
  common_tags                  = var.common_tags
}

# ============================================================================
# Module 2: Subnets with NACL Rules
# ============================================================================
module "subnets" {
  source = "../terraform-module-sbx-subnet"

  aws_region  = var.aws_region
  environment = var.environment
  vpc_id      = module.vpc.vpc_id

  # Multi-AZ & Dynamic Subnet Configuration
  num_availability_zones     = var.num_availability_zones
  availability_zones         = var.availability_zones
  num_private_subnets        = var.num_private_subnets
  num_public_subnets         = var.num_public_subnets
  private_subnet_cidr_blocks = var.private_subnet_cidr_blocks
  public_subnet_cidr_blocks  = var.public_subnet_cidr_blocks
  firewall_subnet_cidr       = var.firewall_subnet_cidr
  specific_ip_cidr           = var.specific_ip_cidr
  firewall_ip_cidr           = var.firewall_ip_cidr

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
  count = length(module.subnets.public_route_table_ids)
  
  route_table_id         = module.subnets.public_route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# ============================================================================
# Firewall Subnet Route - Internet Gateway (CRITICAL for return traffic)
# ============================================================================
# The firewall endpoint receives traffic from private subnets (0.0.0.0/0 -> firewall)
# and needs a route to forward allowed traffic to the IGW for internet access
# ============================================================================
resource "aws_route" "firewall_internet_route" {
  route_table_id         = module.subnets.firewall_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id

  depends_on = [
    aws_internet_gateway.main
  ]
}

# Helper module-like setup for route tables mentioned in subnets (this is simple local resource)
locals {
  subnets_routing = {
    private_route_table_ids  = module.subnets.private_route_table_ids
    public_route_table_ids   = module.subnets.public_route_table_ids
    firewall_route_table_id  = module.subnets.firewall_route_table_id
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

  private_subnet_cidr = var.private_subnet_cidr_blocks
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
module "firewall" {
  source = "../terraform-module-sbx-firewall"

  aws_region        = var.aws_region
  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  firewall_subnet_id = module.subnets.firewall_subnet_id
  vpc_cidr_block    = var.vpc_cidr_block

  private_route_table_ids = module.subnets.private_route_table_ids
  public_route_table_ids  = module.subnets.public_route_table_ids

  firewall_logs_retention_days = var.firewall_logs_retention_days
  enable_s3_logging            = var.firewall_enable_s3_logging
  enable_firewall_alerts       = var.firewall_enable_alerts
  sns_topic_arn                = module.automation.sns_topic_arn

  stateless_rule_group_capacity = var.stateless_rule_group_capacity
  stateful_rule_group_capacity  = var.stateful_rule_group_capacity
  blocked_domains               = var.blocked_domains

  common_tags = var.common_tags
}

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
