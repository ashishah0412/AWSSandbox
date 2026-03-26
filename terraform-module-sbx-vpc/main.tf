# ============================================================================
# AWS VPC Module - terraform-module-sbx-vpc
# ============================================================================
# Purpose: Create VPC infrastructure with VPC Endpoints (S3, DynamoDB)
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
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(
      var.common_tags,
      {
        Module      = "terraform-module-sbx-vpc"
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
data "aws_region" "current" {}

# ============================================================================
# VPC Creation
# ============================================================================
resource "aws_vpc" "sandbox_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-vpc"
    }
  )
}

# ============================================================================
# VPC Flow Logs (CloudWatch)
# ============================================================================
resource "aws_iam_role" "vpc_flow_logs_role" {
  name = "${var.environment}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-vpc-flow-logs-role"
    }
  )
}

resource "aws_iam_role_policy" "vpc_flow_logs_policy" {
  name   = "${var.environment}-vpc-flow-logs-policy"
  role   = aws_iam_role.vpc_flow_logs_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/vpc/flowlogs/${var.environment}:*"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs_group" {
  name              = "/aws/vpc/flowlogs/${var.environment}"
  retention_in_days = var.vpc_flow_logs_retention_days

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-vpc-flow-logs"
    }
  )
}

resource "aws_flow_log" "vpc_flow_logs" {
  iam_role_arn    = aws_iam_role.vpc_flow_logs_role.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs_group.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.sandbox_vpc.id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-vpc-flow-logs"
    }
  )
}

# ============================================================================
# VPC Endpoints - S3 Gateway Endpoint
# ============================================================================
resource "aws_vpc_endpoint" "s3_gateway" {
  count = var.enable_s3_endpoint ? 1 : 0

  vpc_id            = aws_vpc.sandbox_vpc.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.route_table_ids

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::*",
          "arn:aws:s3:::*/*"
        ]
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-s3-endpoint"
    }
  )
}

# ============================================================================
# VPC Endpoints - DynamoDB Gateway Endpoint
# ============================================================================
resource "aws_vpc_endpoint" "dynamodb_gateway" {
  count = var.enable_dynamodb_endpoint ? 1 : 0

  vpc_id            = aws_vpc.sandbox_vpc.id
  service_name      = "com.amazonaws.${var.aws_region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.route_table_ids

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem"
        ]
        Resource = "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/*"
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-dynamodb-endpoint"
    }
  )
}

# ============================================================================
# Data Sources
# ============================================================================
data "aws_availability_zones" "available" {
  state = "available"
}
