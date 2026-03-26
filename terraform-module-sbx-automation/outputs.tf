# ============================================================================
# Outputs - terraform-module-sbx-automation
# ============================================================================

output "budget_name" {
  description = "AWS Budget name"
  value       = aws_budgets_budget.sandbox_budget.name
}

output "budget_limit_amount" {
  description = "Budget limit amount in USD"
  value       = aws_budgets_budget.sandbox_budget.limit_amount
}

output "sns_topic_arn" {
  description = "SNS Topic ARN for budget alerts"
  value       = aws_sns_topic.budget_alerts.arn
}

output "sns_topic_name" {
  description = "SNS Topic name for budget alerts"
  value       = aws_sns_topic.budget_alerts.name
}

output "cloudwatch_alarm_70_arn" {
  description = "CloudWatch alarm ARN for 70% threshold"
  value       = aws_cloudwatch_metric_alarm.budget_seventy_percent_alarm.arn
}

output "cloudwatch_alarm_85_arn" {
  description = "CloudWatch alarm ARN for 85% threshold"
  value       = aws_cloudwatch_metric_alarm.budget_eighty_five_percent_alarm.arn
}

output "cloudwatch_alarm_95_arn" {
  description = "CloudWatch alarm ARN for 95% threshold"
  value       = aws_cloudwatch_metric_alarm.budget_ninety_five_percent_alarm.arn
}

output "lambda_shutdown_function_name" {
  description = "Lambda function name for resource shutdown"
  value       = try(aws_lambda_function.resource_shutdown[0].function_name, null)
}

output "lambda_shutdown_function_arn" {
  description = "Lambda function ARN for resource shutdown"
  value       = try(aws_lambda_function.resource_shutdown[0].arn, null)
}

output "eventbridge_rule_arn" {
  description = "EventBridge rule ARN for 95% threshold"
  value       = try(aws_cloudwatch_event_rule.budget_95_threshold[0].arn, null)
}

output "budget_automation_log_group_name" {
  description = "CloudWatch Log Group name for budget automation"
  value       = aws_cloudwatch_log_group.budget_automation_logs.name
}

output "budget_automation_log_group_arn" {
  description = "CloudWatch Log Group ARN for budget automation"
  value       = aws_cloudwatch_log_group.budget_automation_logs.arn
}

output "budget_thresholds" {
  description = "Budget threshold amounts in USD"
  value = {
    seventy_percent     = aws_budgets_budget.sandbox_budget.limit_amount * 0.70
    eighty_five_percent = aws_budgets_budget.sandbox_budget.limit_amount * 0.85
    ninety_five_percent = aws_budgets_budget.sandbox_budget.limit_amount * 0.95
  }
}

# ============================================================================
# Budget Threshold Implementation
# ============================================================================

output "budget_threshold_monitoring" {
  description = "How budget thresholds are monitored and alerted"
  value = {
    implementation_method = "CloudWatch Alarms + SNS + EventBridge + Lambda"
    
    thresholds = {
      seventy_percent = {
        trigger         = "Actual charges >= $${var.quarterly_budget_limit * 0.70}"
        action          = "SNS notification to ${join(", ", var.budget_alert_emails)}"
        automation      = "Email alert only"
      }
      eighty_five_percent = {
        trigger         = "Actual charges >= $${var.quarterly_budget_limit * 0.85}"
        action          = "SNS notification to ${join(", ", var.budget_alert_emails)}"
        automation      = "Email alert only"
      }
      ninety_five_percent = {
        trigger         = "Actual charges >= $${var.quarterly_budget_limit * 0.95}"
        action          = "SNS notification + EventBridge rule fires"
        automation      = "Lambda function triggered to stop/terminate EC2 and RDS resources"
      }
    }
    
    monitoring_source = "AWS/Billing EstimatedCharges metric"
    alert_recipients  = var.budget_alert_emails
    
    note = "Threshold alerts appear in AWS Budgets console and trigger SNS notifications"
  }
}
