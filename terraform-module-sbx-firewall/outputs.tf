# ============================================================================
# Outputs - terraform-module-sbx-firewall
# ============================================================================

output "firewall_id" {
  description = "Network Firewall ID"
  value       = aws_networkfirewall_firewall.firewall.id
}

output "firewall_arn" {
  description = "Network Firewall ARN"
  value       = aws_networkfirewall_firewall.firewall.arn
}

output "firewall_policy_arn" {
  description = "Network Firewall Policy ARN"
  value       = aws_networkfirewall_firewall_policy.policy.arn
}

output "stateless_rule_group_arn" {
  description = "Stateless Rule Group ARN"
  value       = aws_networkfirewall_rule_group.stateless_rulesource.arn
}

output "stateful_rule_group_arn" {
  description = "Stateful Rule Group ARN"
  value       = aws_networkfirewall_rule_group.stateful_rulesource.arn
}

output "alert_log_group_name" {
  description = "CloudWatch Log Group name for firewall alerts"
  value       = aws_cloudwatch_log_group.firewall_alert_logs.name
}

output "alert_log_group_arn" {
  description = "CloudWatch Log Group ARN for firewall alerts"
  value       = aws_cloudwatch_log_group.firewall_alert_logs.arn
}

output "flow_log_group_name" {
  description = "CloudWatch Log Group name for firewall flows"
  value       = aws_cloudwatch_log_group.firewall_flow_logs.name
}

output "flow_log_group_arn" {
  description = "CloudWatch Log Group ARN for firewall flows"
  value       = aws_cloudwatch_log_group.firewall_flow_logs.arn
}

output "logs_bucket_name" {
  description = "S3 bucket name for firewall logs"
  value       = try(aws_s3_bucket.firewall_logs_bucket[0].id, null)
}

output "logs_bucket_arn" {
  description = "S3 bucket ARN for firewall logs"
  value       = try(aws_s3_bucket.firewall_logs_bucket[0].arn, null)
}

output "firewall_status" {
  description = "Network Firewall status"
  value       = aws_networkfirewall_firewall.firewall.firewall_status
}

output "firewall_endpoints" {
  description = "Network Firewall endpoint information"
  value       = {
    firewall_arn     = aws_networkfirewall_firewall.firewall.arn
    firewall_details = aws_networkfirewall_firewall.firewall.firewall_status
  }
}
