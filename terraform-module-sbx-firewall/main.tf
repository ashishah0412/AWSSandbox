# ============================================================================
# AWS Network Firewall Module - terraform-module-sbx-firewall
# ============================================================================
# Purpose: Deploy AWS Network Firewall for traffic monitoring and inspection
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
        Module      = "terraform-module-sbx-firewall"
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
# CloudWatch Logging for Network Firewall
# ============================================================================
resource "aws_cloudwatch_log_group" "firewall_alert_logs" {
  name              = "/aws/network-firewall/${var.environment}/alerts"
  retention_in_days = var.firewall_logs_retention_days

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-firewall-alert-logs"
    }
  )
}

resource "aws_cloudwatch_log_group" "firewall_flow_logs" {
  name              = "/aws/network-firewall/${var.environment}/flows"
  retention_in_days = var.firewall_logs_retention_days

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-firewall-flow-logs"
    }
  )
}

# ============================================================================
# S3 Bucket for Firewall Logs (Optional)
# ============================================================================
resource "aws_s3_bucket" "firewall_logs_bucket" {
  count  = var.enable_s3_logging ? 1 : 0
  bucket = "${lower(var.environment)}-firewall-logs-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-firewall-logs"
    }
  )
}

resource "aws_s3_bucket_versioning" "firewall_logs_versioning" {
  count  = var.enable_s3_logging ? 1 : 0
  bucket = aws_s3_bucket.firewall_logs_bucket[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "firewall_logs_encryption" {
  count  = var.enable_s3_logging ? 1 : 0
  bucket = aws_s3_bucket.firewall_logs_bucket[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "firewall_logs_access_block" {
  count  = var.enable_s3_logging ? 1 : 0
  bucket = aws_s3_bucket.firewall_logs_bucket[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ============================================================================
# IAM Role for Network Firewall Logging
# ============================================================================
resource "aws_iam_role" "firewall_logging_role" {
  name = "${var.environment}-firewall-logging-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "network-firewall.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-firewall-logging-role"
    }
  )
}

resource "aws_iam_role_policy" "firewall_logging_policy" {
  name = "${var.environment}-firewall-logging-policy"
  role = aws_iam_role.firewall_logging_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:PutLogEvents",
          "logs:CreateLogStream"
        ]
        Resource = [
          aws_cloudwatch_log_group.firewall_alert_logs.arn,
          aws_cloudwatch_log_group.firewall_flow_logs.arn
        ]
      }
    ]
  })
}

# ============================================================================
# Network Firewall Rule Group - Stateless Rules
# ============================================================================
resource "aws_networkfirewall_rule_group" "stateless_rulesource" {
  capacity    = var.stateless_rule_group_capacity
  name        = "${var.environment}-stateless-rules"
  type        = "STATELESS"
  description = "Stateless rules for ${var.environment} sandbox firewall"

  rule_group {
    rules_source {
      stateless_rules_and_custom_actions {
        stateless_rule {
          priority = 1
          rule_definition {
            actions = ["aws:pass"]
            match_attributes {
              protocols = [6]  # TCP
              source {
                address_definition = "0.0.0.0/0"
              }
              destination {
                address_definition = "0.0.0.0/0"
              }
            }
          }
        }

        stateless_rule {
          priority = 2
          rule_definition {
            actions = ["aws:drop"]
            match_attributes {
              protocols = [6]  # TCP
              source {
                address_definition = "0.0.0.0/0"
              }
              destination {
                address_definition = "0.0.0.0/0"
              }
            }
          }
        }
      }
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-stateless-rules"
    }
  )
}

# ============================================================================
# Network Firewall Rule Group - Stateful Rules
# ============================================================================
resource "aws_networkfirewall_rule_group" "stateful_rulesource" {
  capacity    = var.stateful_rule_group_capacity
  name        = "${var.environment}-stateful-rules"
  type        = "STATEFUL"
  description = "Stateful rules for ${var.environment} sandbox firewall"

  rule_group {
    rules_source {
      stateful_rule {
        action = "DROP"
        header {
          destination      = "ANY"
          destination_port = "ANY"
          direction        = "ANY"
          protocol         = "IP"
          source           = "ANY"
          source_port      = "ANY"
        }
        rule_option {
          keyword  = "msg"
          settings = ["\"Suspicious traffic\""]
        }
      }

      stateful_rule {
        action = "PASS"
        header {
          destination      = "ANY"
          destination_port = "ANY"
          direction        = "FORWARD"
          protocol         = "TCP"
          source           = var.vpc_cidr_block
          source_port      = "ANY"
        }
        rule_option {
          keyword  = "flow"
          settings = ["established"]
        }
        rule_option {
          keyword  = "msg"
          settings = ["\"Allow established VPC traffic\""]
        }
      }
    }

    stateful_rule_options {
      rule_order = "STRICT_ORDER"
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-stateful-rules"
    }
  )
}

# ============================================================================
# Network Firewall Policy
# ============================================================================
resource "aws_networkfirewall_firewall_policy" "policy" {
  name               = "${var.environment}-firewall-policy"
  description        = "Firewall policy for ${var.environment} sandbox environment"
  firewall_policy    {
    stateful_default_actions   = ["aws:alert_established", "aws:drop"]
    stateless_default_actions  = ["aws:pass"]
    stateless_fragment_default_actions = ["aws:pass"]

    stateful_engine_options {
      rule_order = "STRICT_ORDER"
      stream_exception_policy = "DROP"
    }

    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.stateful_rulesource.arn
      priority     = 100
    }

    stateless_rule_group_reference {
      priority     = 100
      resource_arn = aws_networkfirewall_rule_group.stateless_rulesource.arn
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-firewall-policy"
    }
  )
}

# ============================================================================
# Network Firewall
# ============================================================================
resource "aws_networkfirewall_firewall" "firewall" {
  name                = "${var.environment}-firewall"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.policy.arn
  vpc_id              = var.vpc_id
  subnet_mapping {
    subnet_id = var.firewall_subnet_id
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-firewall"
    }
  )

  depends_on = [
    aws_iam_role_policy.firewall_logging_policy
  ]
}


# ============================================================================
# EventBridge Rule for Firewall Alerts (Optional)  
# ============================================================================
resource "aws_cloudwatch_event_rule" "firewall_alerts" {
  count           = var.enable_firewall_alerts ? 1 : 0
  name            = "${var.environment}-firewall-alerts"
  description     = "Capture Network Firewall alerts"
  event_bus_name  = "default"

  event_pattern = jsonencode({
    source      = ["aws.events"]
    detail-type = ["Network Firewall Alert"]
    detail = {
      action = ["REJECT", "DROP"]
    }
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-firewall-alerts-rule"
    }
  )
}

resource "aws_cloudwatch_event_target" "firewall_alerts_sns" {
  count           = var.enable_firewall_alerts ? 1 : 0
  rule            = aws_cloudwatch_event_rule.firewall_alerts[0].name
  target_id       = "SendToSNS"
  arn             = var.sns_topic_arn
  role_arn        = aws_iam_role.eventbridge_firewall_role[0].arn
}

resource "aws_iam_role" "eventbridge_firewall_role" {
  count = var.enable_firewall_alerts ? 1 : 0
  name  = "${var.environment}-eventbridge-firewall-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-eventbridge-firewall-role"
    }
  )
}

resource "aws_iam_role_policy" "eventbridge_firewall_policy" {
  count = var.enable_firewall_alerts ? 1 : 0
  name  = "${var.environment}-eventbridge-firewall-policy"
  role  = aws_iam_role.eventbridge_firewall_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = var.sns_topic_arn
      }
    ]
  })
}
