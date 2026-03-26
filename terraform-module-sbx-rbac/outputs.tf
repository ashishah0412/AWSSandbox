# ============================================================================
# Outputs - terraform-module-sbx-rbac
# ============================================================================

output "ec2_instance_role_name" {
  description = "EC2 instance role name"
  value       = aws_iam_role.ec2_instance_role.name
}

output "ec2_instance_role_arn" {
  description = "EC2 instance role ARN"
  value       = aws_iam_role.ec2_instance_role.arn
}

output "ec2_instance_profile_name" {
  description = "EC2 instance profile name"
  value       = aws_iam_instance_profile.ec2_instance_profile.name
}

output "ec2_instance_profile_arn" {
  description = "EC2 instance profile ARN"
  value       = aws_iam_instance_profile.ec2_instance_profile.arn
}

output "lambda_execution_role_name" {
  description = "Lambda execution role name"
  value       = aws_iam_role.lambda_execution_role.name
}

output "lambda_execution_role_arn" {
  description = "Lambda execution role ARN"
  value       = aws_iam_role.lambda_execution_role.arn
}

output "rds_monitoring_role_name" {
  description = "RDS monitoring role name"
  value       = aws_iam_role.rds_monitoring_role.name
}

output "rds_monitoring_role_arn" {
  description = "RDS monitoring role ARN"
  value       = aws_iam_role.rds_monitoring_role.arn
}

output "cost_control_role_name" {
  description = "Cost control role name"
  value       = aws_iam_role.cost_control_role.name
}

output "cost_control_role_arn" {
  description = "Cost control role ARN"
  value       = aws_iam_role.cost_control_role.arn
}

output "sandwich_developers_group_name" {
  description = "Sandbox developers group name"
  value       = aws_iam_group.sandbox_developers.name
}

output "sandbox_viewers_group_name" {
  description = "Sandbox viewers group name"
  value       = aws_iam_group.sandbox_viewers.name
}

output "budget_notification_role_name" {
  description = "Budget notification role name"
  value       = aws_iam_role.budget_notification_role.name
}

output "budget_notification_role_arn" {
  description = "Budget notification role ARN"
  value       = aws_iam_role.budget_notification_role.arn
}

output "developer_policy_arn" {
  description = "Developer policy ARN"
  value       = aws_iam_policy.sandbox_developer_policy.arn
}

output "read_only_policy_arn" {
  description = "Read-only policy ARN"
  value       = aws_iam_policy.sandbox_read_only_policy.arn
}

output "cost_budget_policy_arn" {
  description = "Cost budget management policy ARN"
  value       = aws_iam_policy.cost_budget_management_policy.arn
}

output "restrict_resource_creation_policy_arn" {
  description = "Restrict resource creation SCP ARN"
  value       = aws_iam_policy.restrict_resource_creation_scp.arn
}

output "all_roles" {
  description = "Map of all created roles"
  value = {
    ec2_instance_role_arn       = aws_iam_role.ec2_instance_role.arn
    lambda_execution_role_arn   = aws_iam_role.lambda_execution_role.arn
    rds_monitoring_role_arn     = aws_iam_role.rds_monitoring_role.arn
    cost_control_role_arn       = aws_iam_role.cost_control_role.arn
    budget_notification_role_arn = aws_iam_role.budget_notification_role.arn
  }
}

output "all_policies" {
  description = "Map of all created policies"
  value = {
    developer_policy_arn         = aws_iam_policy.sandbox_developer_policy.arn
    read_only_policy_arn         = aws_iam_policy.sandbox_read_only_policy.arn
    cost_budget_policy_arn       = aws_iam_policy.cost_budget_management_policy.arn
    restrict_resource_creation_scp_arn = aws_iam_policy.restrict_resource_creation_scp.arn
  }
}
