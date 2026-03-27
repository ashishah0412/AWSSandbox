# ============================================================================
# Terraform Values - terraform-module-sbx-firewall
# ============================================================================

aws_region           = "us-east-1"
environment          = "Sandbox"
vpc_id               = "vpc-xxxxxxxxxxxxx"          # Replace with actual VPC ID
firewall_subnet_id   = "subnet-xxxxxxxxxxxxx"       # Replace with actual Firewall Subnet ID
vpc_cidr_block       = "10.10.0.0/16"
firewall_logs_retention_days = 30
enable_s3_logging    = false                        # Set to true for S3 logging
enable_firewall_alerts = true
sns_topic_arn        = "arn:aws:sns:us-east-2:ACCOUNT_ID:firewall-alerts" # Replace with actual SNS topic ARN
stateless_rule_group_capacity = 100
stateful_rule_group_capacity  = 1000
blocked_domains      = []                           # Add domains to block if needed

common_tags = {
  Project     = "AWS-AWS-Sandbox"
  CostCenter  = "Engineering"
  Owner       = "CloudOps"
  CreatedBy   = "Terraform"
}
