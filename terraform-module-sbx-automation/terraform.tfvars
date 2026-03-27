# ============================================================================
# Terraform Values - terraform-module-sbx-automation
# ============================================================================

aws_region               = "us-east-1"
environment              = "Sandbox"
quarterly_budget_limit   = 1000
budget_start_date        = "2026-01-01_00:00"
budget_end_date          = "2026-12-31_23:59"
budget_alert_emails      = ["ashishah0412@gmail.com"]
enable_resource_shutdown = false
cloudwatch_period        = 3600

# Budget action policies - use resource creation restrict policies
# policy_seventy_percent  = "arn:aws:iam::ACCOUNT_ID:policy/Sandbox-restrict-policy-70"
# policy_eighty_five_percent = "arn:aws:iam::ACCOUNT_ID:policy/Sandbox-restrict-policy-85"

# IAM roles to target for budget actions
# iam_roles_to_target = ["Sandbox-ec2-instance-role", "Sandbox-lambda-execution-role"]

common_tags = {
  Project     = "AWS-AWS-Sandbox"
  CostCenter  = "Engineering"
  Owner       = "CloudOps"
  CreatedBy   = "Terraform"
}
