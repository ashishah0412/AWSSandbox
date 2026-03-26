# ============================================================================
# Outputs - CEPS-AWS-Sandbox Master Module
# ============================================================================
# Purpose: Define all output values for deployed infrastructure
# ============================================================================

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
# Outputs - Subnets Information (Dynamic, Multi-AZ)
# ============================================================================
output "private_subnet_ids" {
  description = "List of Private Subnet IDs"
  value       = module.subnets.private_subnet_ids
}

output "public_subnet_ids" {
  description = "List of Public Subnet IDs"
  value       = module.subnets.public_subnet_ids
}

output "firewall_subnet_id" {
  description = "Firewall Subnet ID"
  value       = module.subnets.firewall_subnet_id
}

output "subnet_nacl_ids" {
  description = "Network ACL IDs for all subnets (dynamic)"
  value = {
    private_nacl_ids   = module.subnets.private_nacl_ids
    public_nacl_ids    = module.subnets.public_nacl_ids
    firewall_nacl_id   = module.subnets.firewall_nacl_id
  }
}

output "subnets_by_az" {
  description = "Subnets grouped by Availability Zone with details"
  value       = module.subnets.subnets_by_az
}

output "subnet_count_summary" {
  description = "Summary of created subnets"
  value       = module.subnets.subnet_count_summary
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
      private_ids  = module.subnets.private_subnet_ids
      public_ids   = module.subnets.public_subnet_ids
      firewall_id  = module.subnets.firewall_subnet_id
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
