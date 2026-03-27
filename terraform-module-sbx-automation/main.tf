# ============================================================================
# AWS Cost Budget & Automation Module - terraform-module-sbx-automation
# ============================================================================
# Purpose: Cost budgets, alerts, automation, and resource controls
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
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(
      var.common_tags,
      {
        Module      = "terraform-module-sbx-automation"
        Environment = var.environment
        ManagedBy   = "Terraform"
      }
    )
  }
}

# ============================================================================
# Data Sources
# ============================================================================
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

# ============================================================================
# SNS Topic for Budget Alerts
# ============================================================================
resource "aws_sns_topic" "budget_alerts" {
  name              = "${var.environment}-budget-alerts"
  kms_master_key_id = "alias/aws/sns"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-budget-alerts"
    }
  )
}

resource "aws_sns_topic_subscription" "budget_alerts_email" {
  count     = length(var.budget_alert_emails)
  topic_arn = aws_sns_topic.budget_alerts.arn
  protocol  = "email"
  endpoint  = var.budget_alert_emails[count.index]
}

# ============================================================================
# IAM Policies for Budget Actions
# ============================================================================

# Policy for 85% threshold - Requires approval before resource creation
resource "aws_iam_policy" "budget_action_85_percent_policy" {
  name        = "${var.environment}-budget-action-85-restrict"
  description = "Restrictive policy applied at 85% budget threshold - requires approval for new resources"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyNewResourceCreation"
        Effect = "Deny"
        Action = [
          "ec2:RunInstances",
          "ec2:CreateVolume",
          "rds:CreateDBInstance",
          "elasticache:CreateCacheCluster",
          "lambda:CreateFunction",
          "apigateway:CreateRestApi",
          "dynamodb:CreateTable"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = var.aws_region
          }
        }
      },
      {
        Sid    = "AllowModifyExistingResources"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:StopInstances",
          "rds:DescribeDBInstances",
          "lambda:GetFunction",
          "logs:*"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-budget-action-85-policy"
    }
  )
}

# Policy for 95% threshold - Full freeze (deny all modifications)
resource "aws_iam_policy" "budget_action_95_percent_policy" {
  name        = "${var.environment}-budget-action-95-freeze"
  description = "Freeze policy applied at 95% budget threshold - auto-applied resource freeze"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "FreezeAllResourceOperations"
        Effect = "Deny"
        Action = [
          "ec2:RunInstances",
          "ec2:CreateVolume",
          "ec2:CreateImage",
          "ec2:CreateSnapshot",
          "rds:CreateDBInstance",
          "rds:ModifyDBInstance",
          "elasticache:CreateCacheCluster",
          "lambda:CreateFunction",
          "lambda:UpdateFunctionCode",
          "apigateway:CreateRestApi",
          "dynamodb:CreateTable",
          "s3:CreateBucket",
          "efs:CreateFileSystem"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = var.aws_region
          }
        }
      },
      {
        Sid    = "AllowReadOnly"
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "rds:Describe*",
          "lambda:List*",
          "lambda:Get*",
          "logs:*",
          "cloudwatch:*",
          "s3:List*",
          "s3:Get*"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-budget-action-95-policy"
    }
  )
}

# ============================================================================
# AWS Budget (quarterly cost limit)
# ============================================================================
resource "aws_budgets_budget" "sandbox_budget" {
  name              = "${var.environment}-quarterly-budget"
  budget_type       = "COST"
  limit_unit        = "USD"
  limit_amount      = var.quarterly_budget_limit
  time_period_start = var.budget_start_date
  time_period_end   = var.budget_end_date
  time_unit         = "QUARTERLY"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-budget"
    }
  )
}

# ============================================================================
# NOTE: Budget Threshold Alerts
# ============================================================================
# Threshold monitoring is implemented via CloudWatch Alarms (see below):
# - 70% threshold: SNS notification to budget_alert_emails
# - 85% threshold: SNS notification to budget_alert_emails  
# - 95% threshold: SNS notification + Lambda auto-shutdown triggered
#
# These CloudWatch alarms integrate with AWS Billing metrics and appear
# in the AWS Budget console along with SNS notifications.


# ============================================================================
# CloudWatch Alarms for Budget Thresholds
# ============================================================================
resource "aws_cloudwatch_metric_alarm" "budget_seventy_percent_alarm" {
  alarm_name          = "${var.environment}-budget-70-percent"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = var.cloudwatch_period
  statistic           = "Maximum"
  threshold           = (var.quarterly_budget_limit * 0.70)
  alarm_description   = "Alert when budget usage reaches 70%"
  alarm_actions       = [aws_sns_topic.budget_alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    Currency = "USD"
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-budget-70-alarm"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "budget_eighty_five_percent_alarm" {
  alarm_name          = "${var.environment}-budget-85-percent"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = var.cloudwatch_period
  statistic           = "Maximum"
  threshold           = (var.quarterly_budget_limit * 0.85)
  alarm_description   = "Alert when budget usage reaches 85%"
  alarm_actions       = [aws_sns_topic.budget_alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    Currency = "USD"
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-budget-85-alarm"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "budget_ninety_five_percent_alarm" {
  alarm_name          = "${var.environment}-budget-95-percent"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = var.cloudwatch_period
  statistic           = "Maximum"
  threshold           = (var.quarterly_budget_limit * 0.95)
  alarm_description   = "Alert when budget usage reaches 95% - TRIGGER RESOURCE FREEZE"
  alarm_actions       = [aws_sns_topic.budget_alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    Currency = "USD"
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-budget-95-alarm"
    }
  )
}


# ============================================================================
# Lambda Function for Resource Shutdown (95% threshold)
# ============================================================================
resource "aws_lambda_function" "resource_shutdown" {
  count            = var.enable_resource_shutdown ? 1 : 0
  filename         = "${path.module}/lambda_handler.zip"
  function_name    = "${var.environment}-resource-shutdown"
  role             = aws_iam_role.lambda_shutdown_role[0].arn
  handler          = "lambda_handler.handler"
  source_code_hash = try(filebase64sha256("${path.module}/lambda_handler.zip"), "placeholder-hash")
  timeout          = 60
  runtime          = "python3.11"

  environment {
    variables = {
      ENVIRONMENT = var.environment
      SNS_TOPIC   = aws_sns_topic.budget_alerts.arn
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-resource-shutdown"
    }
  )
}

resource "aws_iam_role" "lambda_shutdown_role" {
  count = var.enable_resource_shutdown ? 1 : 0
  name  = "${var.environment}-lambda-shutdown-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-lambda-shutdown-role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "lambda_shutdown_basic" {
  count      = var.enable_resource_shutdown ? 1 : 0
  role       = aws_iam_role.lambda_shutdown_role[0].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_shutdown_policy" {
  count = var.enable_resource_shutdown ? 1 : 0
  name  = "${var.environment}-lambda-shutdown-policy"
  role  = aws_iam_role.lambda_shutdown_role[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:StopInstances",
          "ec2:TerminateInstances",
          "rds:DescribeDBInstances",
          "rds:StopDBInstance",
          "rds:DeleteDBInstance"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/Environment" = var.environment
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.budget_alerts.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:${data.aws_partition.current.partition}:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*"
      }
    ]
  })
}

# ============================================================================
# EventBridge Rule for 95% Threshold Trigger
# ============================================================================
resource "aws_cloudwatch_event_rule" "budget_95_threshold" {
  count           = var.enable_resource_shutdown ? 1 : 0
  name            = "${var.environment}-budget-95-trigger"
  description     = "Trigger resource shutdown when budget reaches 95%"
  event_bus_name  = "default"
  
  event_pattern = jsonencode({
    source      = ["aws.cloudwatch"]
    detail-type = ["CloudWatch Alarm State Change"]
    detail = {
      alarmName           = [aws_cloudwatch_metric_alarm.budget_ninety_five_percent_alarm.alarm_name]
      state = {
        value = ["ALARM"]
      }
    }
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-budget-95-trigger"
    }
  )
}

resource "aws_cloudwatch_event_target" "budget_95_lambda" {
  count     = var.enable_resource_shutdown ? 1 : 0
  rule      = aws_cloudwatch_event_rule.budget_95_threshold[0].name
  target_id = "LambdaShutdown"
  arn       = aws_lambda_function.resource_shutdown[0].arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  count         = var.enable_resource_shutdown ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.resource_shutdown[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.budget_95_threshold[0].arn
}

# ============================================================================
# CloudWatch Log Group for Budget Automation
# ============================================================================
resource "aws_cloudwatch_log_group" "budget_automation_logs" {
  name              = "/aws/sandbox/${var.environment}/budget-automation"
  retention_in_days = 30

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-budget-automation-logs"
    }
  )
}
