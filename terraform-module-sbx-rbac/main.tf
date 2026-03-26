# ============================================================================
# AWS IAM/RBAC Module - terraform-module-sbx-rbac
# ============================================================================
# Purpose: Create IAM roles, policies, and access controls for Sandbox
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
        Module      = "terraform-module-sbx-rbac"
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
# IAM Role - EC2 Instance Profile
# ============================================================================
resource "aws_iam_role" "ec2_instance_role" {
  name                = "${var.environment}-ec2-instance-role"
  assume_role_policy  = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-ec2-instance-role"
    }
  )
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.environment}-ec2-instance-profile"
  role = aws_iam_role.ec2_instance_role.name
}

resource "aws_iam_role_policy" "ec2_instance_policy" {
  name   = "${var.environment}-ec2-instance-policy"
  role   = aws_iam_role.ec2_instance_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:UpdateInstanceInformation",
          "ssmmessages:AcknowledgeMessage",
          "ssmmessages:GetEndpoint",
          "ssmmessages:GetMessages",
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:${data.aws_partition.current.partition}:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/sandbox/*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeImages",
          "ec2:DescribeSnapshots",
          "ec2:DescribeVolumes"
        ]
        Resource = "*"
      }
    ]
  })
}

# ============================================================================
# IAM Role - Lambda Execution Role
# ============================================================================
resource "aws_iam_role" "lambda_execution_role" {
  name               = "${var.environment}-lambda-execution-role"
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
      Name = "${var.environment}-lambda-execution-role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_execution" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# ============================================================================
# IAM Role - RDS Enhanced Monitoring
# ============================================================================
resource "aws_iam_role" "rds_monitoring_role" {
  name               = "${var.environment}-rds-monitoring-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "monitoring.rds.amazonaws.com"
      }
    }]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-rds-monitoring-role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_monitoring_role.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# ============================================================================
# IAM Role - Cost Budget and Control
# ============================================================================
resource "aws_iam_role" "cost_control_role" {
  name               = "${var.environment}-cost-control-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ssm.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-cost-control-role"
    }
  )
}

resource "aws_iam_role_policy" "cost_control_policy" {
  name   = "${var.environment}-cost-control-policy"
  role   = aws_iam_role.cost_control_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:StopInstances",
          "ec2:TerminateInstances",
          "ec2:DescribeInstances",
          "rds:StopDBInstance",
          "rds:DescribeDBInstances",
          "lambda:UpdateFunctionConfiguration"
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
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:${data.aws_partition.current.partition}:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/sandbox/*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:SendCommand",
          "ssm:GetCommandInvocation",
          "ssm:ListCommandInvocations"
        ]
        Resource = "*"
      }
    ]
  })
}

# ============================================================================
# IAM Policy - Read-Only Access
# ============================================================================
resource "aws_iam_policy" "sandbox_read_only_policy" {
  name        = "${var.environment}-read-only-policy"
  description = "Read-only access to sandbox resources"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "rds:Describe*",
          "s3:Get*",
          "s3:List*",
          "dynamodb:Describe*",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "logs:Describe*",
          "logs:Get*",
          "logs:List*",
          "cloudwatch:Describe*",
          "cloudwatch:Get*",
          "cloudwatch:List*",
          "iam:Get*",
          "iam:List*"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-read-only-policy"
    }
  )
}

# ============================================================================
# IAM Policy - Developer Access
# ============================================================================
resource "aws_iam_policy" "sandbox_developer_policy" {
  name        = "${var.environment}-developer-policy"
  description = "Developer access to sandbox resources"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "rds:Describe*",
          "rds:CreateDBInstance",
          "rds:DeleteDBInstance",
          "rds:ModifyDBInstance",
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "dynamodb:Describe*",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:CreateTable",
          "dynamodb:DeleteTable",
          "logs:Describe*",
          "logs:Get*",
          "logs:List*",
          "cloudwatch:Put*",
          "cloudwatch:List*",
          "cloudwatch:Describe*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/Environment" = var.environment
          }
        }
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-developer-policy"
    }
  )
}

# ============================================================================
# IAM Group - Sandbox Developers
# ============================================================================
resource "aws_iam_group" "sandbox_developers" {
  name = "${var.environment}-developers"
}

resource "aws_iam_group_policy_attachment" "developers_policy" {
  group      = aws_iam_group.sandbox_developers.name
  policy_arn = aws_iam_policy.sandbox_developer_policy.arn
}

# ============================================================================
# IAM Group - Sandbox Viewers (Read-Only)
# ============================================================================
resource "aws_iam_group" "sandbox_viewers" {
  name = "${var.environment}-viewers"
}

resource "aws_iam_group_policy_attachment" "viewers_policy" {
  group      = aws_iam_group.sandbox_viewers.name
  policy_arn = aws_iam_policy.sandbox_read_only_policy.arn
}

# ============================================================================
# IAM Policy - Budget and Cost Controls (SCP-related)
# ============================================================================
resource "aws_iam_policy" "cost_budget_management_policy" {
  name        = "${var.environment}-cost-budget-policy"
  description = "Policy for accessing budget and cost controls"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "budgets:ViewBudget",
          "budgets:DescribeBudgets",
          "ce:GetCostAndUsage",
          "ce:GetDimensionValues",
          "ce:GetReservationPurchaseRecommendation",
          "ce:GetRightsizingRecommendation",
          "ce:GetSavingsPlansPurchaseRecommendationDetails",
          "ce:ListCostAllocationTags"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-cost-budget-policy"
    }
  )
}

# ============================================================================
# IAM Roles for Service Integrations
# ============================================================================

# SNS Publish Role for Budgets
resource "aws_iam_role" "budget_notification_role" {
  name               = "${var.environment}-budget-notification-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "budgets.amazonaws.com"
      }
    }]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-budget-notification-role"
    }
  )
}

resource "aws_iam_role_policy" "budget_notification_policy" {
  name   = "${var.environment}-budget-notification-policy"
  role   = aws_iam_role.budget_notification_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "sns:Publish"
      ]
      Resource = "*"
    }]
  })
}

# ============================================================================
# Service Control Policy (SCP) for Cost Control - Root Organization
# ============================================================================
# Note: This policy should be applied at the organization root level
# to restrict resource creation when budget thresholds are exceeded

resource "aws_iam_policy" "restrict_resource_creation_scp" {
  name        = "${var.environment}-restrict-resource-creation"
  description = "SCP to restrict resource creation when budget threshold exceeded"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyEC2CreationAboveThreshold"
        Effect = "Deny"
        Action = [
          "ec2:RunInstances"
        ]
        Resource = [
          "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:instance/*"
        ]
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = var.aws_region
          }
          StringLike = {
            "aws:TokenIssueTime" = "*"
          }
        }
      },
      {
        Sid    = "DenyRDSCreationAboveThreshold"
        Effect = "Deny"
        Action = [
          "rds:CreateDBInstance",
          "rds:CreateDBCluster"
        ]
        Resource = [
          "arn:${data.aws_partition.current.partition}:rds:*:${data.aws_caller_identity.current.account_id}:db/*",
          "arn:${data.aws_partition.current.partition}:rds:*:${data.aws_caller_identity.current.account_id}:cluster/*"
        ]
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-restrict-resource-creation"
    }
  )
}
