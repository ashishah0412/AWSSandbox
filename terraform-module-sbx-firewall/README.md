# terraform-module-sbx-firewall

AWS Network Firewall Module for AON Sandbox Automation Project

## Overview

This Terraform module deploys AWS Network Firewall for monitoring and controlling traffic in the Sandbox environment:

- **Network Firewall**: Central traffic inspection and monitoring
- **Stateless Rules**: Basic packet-level filtering
- **Stateful Rules**: Connection-aware traffic inspection
- **CloudWatch Logging**: Real-time alert and flow logging
- **S3 Logging**: Optional long-term log archival
- **EventBridge Integration**: Automatic alert notifications

## Features

- **Traffic Monitoring**: North-South and East-West traffic inspection
- **Flexible Rule Engine**: Stateless and stateful rules
- **Comprehensive Logging**: CloudWatch and S3 log destinations
- **Alert Automation**: EventBridge rules for real-time notifications
- **Domain Blocking**: Block malicious domains via TLS-SNI inspection
- **Production-Ready**: Enterprise-grade security controls

## Prerequisites

- Terraform >= 1.0
- AWS Provider >= 5.0
- AWS Account with appropriate IAM permissions
- VPC and Firewall Subnet already created
- SNS Topic for alerts (optional)

## Usage

### Basic Usage

```hcl
module "firewall" {
  source = "path/to/terraform-module-sbx-firewall"

  aws_region        = "us-east-1"
  environment       = "Sandbox"
  vpc_id            = module.vpc.vpc_id
  firewall_subnet_id = module.subnets.firewall_subnet_id
  vpc_cidr_block    = "10.10.0.0/16"

  common_tags = {
    Project     = "AON-AWS-Sandbox"
    CostCenter  = "Engineering"
    Owner       = "CloudOps"
  }
}
```

### With Alerts and Blocked Domains

```hcl
module "firewall" {
  source = "path/to/terraform-module-sbx-firewall"

  aws_region         = "us-east-1"
  environment        = "Sandbox"
  vpc_id             = module.vpc.vpc_id
  firewall_subnet_id = module.subnets.firewall_subnet_id
  
  enable_firewall_alerts = true
  sns_topic_arn         = aws_sns_topic.firewall_alerts.arn
  
  blocked_domains = [
    "malicious-domain.com",
    "phishing-site.net"
  ]
}
```

### With S3 Logging

```hcl
module "firewall" {
  source = "path/to/terraform-module-sbx-firewall"

  aws_region        = "us-east-1"
  environment       = "Sandbox"
  vpc_id            = module.vpc.vpc_id
  firewall_subnet_id = module.subnets.firewall_subnet_id
  
  enable_s3_logging = true
  firewall_logs_retention_days = 90
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `aws_region` | AWS region for deployment | `string` | `"us-east-1"` | No |
| `environment` | Environment name for tagging | `string` | `"Sandbox"` | No |
| `vpc_id` | VPC ID for firewall | `string` | N/A | **Yes** |
| `firewall_subnet_id` | Subnet ID for firewall deployment | `string` | N/A | **Yes** |
| `vpc_cidr_block` | VPC CIDR block | `string` | `"10.10.0.0/16"` | No |
| `firewall_logs_retention_days` | CloudWatch retention days | `number` | `30` | No |
| `enable_s3_logging` | Enable S3 bucket for logs | `bool` | `false` | No |
| `enable_firewall_alerts` | Enable EventBridge alerts | `bool` | `true` | No |
| `sns_topic_arn` | SNS topic for alerts | `string` | `""` | No |
| `stateless_rule_group_capacity` | Stateless rule capacity | `number` | `100` | No |
| `stateful_rule_group_capacity` | Stateful rule capacity | `number` | `1000` | No |
| `blocked_domains` | List of domains to block | `list(string)` | `[]` | No |
| `common_tags` | Common tags for resources | `map(string)` | See defaults | No |

## Outputs

| Name | Description |
|------|-------------|
| `firewall_id` | Network Firewall ID |
| `firewall_arn` | Network Firewall ARN |
| `firewall_policy_arn` | Firewall Policy ARN |
| `stateless_rule_group_arn` | Stateless Rule Group ARN |
| `stateful_rule_group_arn` | Stateful Rule Group ARN |
| `alert_log_group_name` | CloudWatch alert log group name |
| `alert_log_group_arn` | CloudWatch alert log group ARN |
| `flow_log_group_name` | CloudWatch flow log group name |
| `flow_log_group_arn` | CloudWatch flow log group ARN |
| `logs_bucket_name` | S3 bucket name for logs (if enabled) |
| `logs_bucket_arn` | S3 bucket ARN for logs (if enabled) |
| `firewall_status` | Firewall status and configuration |
| `firewall_endpoints` | Firewall endpoint details |

## Network Architecture

```
┌─────────────────────────────────────────────────┐
│           VPC: 10.10.0.0/16                     │
│                                                 │
│  North-South Traffic (Internet ↔ Subnets)      │
│  East-West Traffic (Subnet ↔ Subnet)           │
│           ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓                │
│                                                 │
│  ┌───────────────────────────────────────────┐ │
│  │   AWS Network Firewall                    │ │
│  │   ┌─────────────────────────────────────┐ │ │
│  │   │ Stateless Rules (Protocol filtering)│ │ │
│  │   │ - TCP/UDP inspection               │ │ │
│  │   │ - Port-based rules                 │ │ │
│  │   └─────────────────────────────────────┘ │ │
│  │   ┌─────────────────────────────────────┐ │ │
│  │   │ Stateful Rules (Connection tracking)│ │ │
│  │   │ - Track established connections    │ │ │
│  │   │ - Domain blocking (TLS-SNI)        │ │ │
│  │   └─────────────────────────────────────┘ │ │
│  │   ┌─────────────────────────────────────┐ │ │
│  │   │ Logging & Alerts                    │ │ │
│  │   │ - CloudWatch Alerts                │ │ │
│  │   │ - CloudWatch Flows                 │ │ │
│  │   │ - S3 Archive (Optional)            │ │ │
│  │   │ - EventBridge Notifications        │ │ │
│  │   └─────────────────────────────────────┘ │ │
│  └───────────────────────────────────────────┘ │
│                                                 │
│  ┌──────────────┬──────────────┬───────────────┤
│  │ Private      │ Public       │ Firewall      │
│  │ Subnet       │ Subnet       │ Subnet        │
│  └──────────────┴──────────────┴───────────────┘
└─────────────────────────────────────────────────┘
         ↓ (Monitored Traffic)
    ┌─────────────────────────────────┐
    │ CloudWatch Logs                 │
    │ - Alerts Log Group              │
    │ - Flow Log Group                │
    │ - 30-day retention (configurable)
    └─────────────────────────────────┘
    
    ┌─────────────────────────────────┐
    │ S3 Bucket (Optional)            │
    │ - Long-term log archival        │
    │ - Compliance & audit trails     │
    └─────────────────────────────────┘
```

## Rule Types

### Stateless Rules
- **Purpose**: Basic packet-level filtering
- **Evaluation**: Per-packet analysis
- **Use Cases**: Block/allow specific protocols, ports, IPs
- **Performance**: Lower latency

### Stateful Rules
- **Purpose**: Connection-aware inspection
- **Evaluation**: Session-level analysis
- **Use Cases**: Track connections, block domains, detect anomalies
- **Performance**: Higher resources, more thorough

## Logging Architecture

### Alert Logs
- **Log Group**: `/aws/network-firewall/Sandbox/alerts`
- **Content**: Drops, rejects, and policy violations
- **Use**: Real-time investigation and alerting
- **Retention**: 30 days (configurable)

### Flow Logs
- **Log Group**: `/aws/network-firewall/Sandbox/flows`
- **Content**: All traffic flows (allowed and denied)
- **Use**: Traffic analysis, capacity planning
- **Retention**: 30 days (configurable)

### S3 Archival (Optional)
- **Bucket**: `sandbox-firewall-logs-ACCOUNT_ID`
- **Purpose**: Long-term compliance and forensics
- **Enabled**: `enable_s3_logging = true`
- **Encryption**: AES-256 (automatic)

## Monitoring & Alerts

### EventBridge Rule
- **Trigger**: Firewall DROP/REJECT actions
- **Target**: SNS Topic
- **Notification**: Sent to subscribers via email/SMS
- **Latency**: Auto-triggered on suspicious traffic

### CloudWatch Dashboards
Create dashboard for visualization:

```hcl
resource "aws_cloudwatch_dashboard" "firewall" {
  dashboard_name = "firewall-monitoring"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        metrics = [
          ["AWS/NetworkFirewall", "LogsProcessed", { stat = "Sum" }],
          [".", "DroppedPackets", { stat = "Sum" }]
        ]
      }
    ]
  })
}
```

## IAM Permissions Required

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "network-firewall:CreateFirewall",
        "network-firewall:DescribeFirewall",
        "network-firewall:DeleteFirewall",
        "network-firewall:CreateFirewallPolicy",
        "network-firewall:DescribeFirewallPolicy",
        "network-firewall:DeleteFirewallPolicy",
        "network-firewall:CreateRuleGroup",
        "network-firewall:DescribeRuleGroup",
        "network-firewall:DeleteRuleGroup",
        "logs:CreateLogGroup",
        "logs:DescribeLogGroups",
        "logs:PutRetentionPolicy",
        "iam:CreateRole",
        "iam:PutRolePolicy",
        "iam:PassRole",
        "s3:CreateBucket",
        "s3:PutBucketEncryption",
        "s3:PutBucketVersioning",
        "s3:PutBucketPublicAccessBlock",
        "events:PutRule",
        "events:PutTargets"
      ],
      "Resource": "*"
    }
  ]
}
```

## Deployment Instructions

### Prerequisites Check

```bash
# Verify VPC exists
aws ec2 describe-vpcs --vpc-ids vpc-xxxxx

# Verify subnet exists
aws ec2 describe-subnets --subnet-ids subnet-xxxxx

# Create SNS topic for alerts (if needed)
aws sns create-topic --name firewall-alerts
```

### Deployment

```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Review plan
terraform plan

# Apply configuration
terraform apply
```

### Post-Deployment

```bash
# Get firewall ID
terraform output firewall_id

# Monitor logs
aws logs tail /aws/network-firewall/Sandbox/alerts --follow

# Check firewall status
aws network-firewall describe-firewall --firewall-arn <firewall-arn>
```

## Deployment Order

This module depends on:
1. **terraform-module-sbx-vpc** - Must be created first
2. **terraform-module-sbx-subnet** - Needs firewall subnet

This module is optional for:
1. **CEPS-AWS-Sandbox** - Master orchestration

## Troubleshooting

### Firewall Creation Fails
- Verify subnet exists and is in correct VPC
- Check IAM permissions
- Verify no duplicate firewall in subnet

### Logs Not Appearing
- Check CloudWatch Logs permission
- Verify IAM role has correct policy
- Check firewall status: `firewall_status` output

### Alerts Not Firing
- Verify SNS topic exists
- Check EventBridge rule is enabled
- Confirm traffic matches rule conditions
- Review firewall logs for DROP actions

### No Traffic Flows
- Verify subnet routing through firewall
- Check Network ACLs allow traffic
- Verify security groups allow traffic
- Review firewall policy rules

## Cost Optimization

### Reduce Logging Costs
```hcl
firewall_logs_retention_days = 7  # Shorter retention
enable_s3_logging = false         # Disable S3 backup
```

### Adjust Rule Capacities
```hcl
stateless_rule_group_capacity = 50   # Reduce if not needed
stateful_rule_group_capacity  = 500  # Adjust to actual needs
```

## Cleanup

```bash
terraform destroy
```

## Version History

### v1.0.0
- Initial release
- Network Firewall deployment
- Stateless and stateful rules
- CloudWatch logging integration
- EventBridge alerts
- S3 archival support

## License

Internal Use Only - AON Sandbox Automation Project

## Contributors

AON Cloud Operations Team
