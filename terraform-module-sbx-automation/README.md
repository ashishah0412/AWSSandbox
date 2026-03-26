# terraform-module-sbx-automation

AWS Cost Budget & Automation Module for AON Sandbox Automation Project

## Overview

This production-grade Terraform module implements comprehensive cost management and automation controls:

- **AWS Budgets**: Quarterly budget with tag-based filtering
- **Multi-Tier Alerts**: 70%, 85%, and 95% threshold notifications via SNS
- **CloudWatch Alarms**: Real-time budget monitoring
- **Lambda Automation**: Automatic resource shutdown at 95% threshold
- **EventBridge Integration**: Event-driven resource control
- **IAM Budget Actions**: Automatic policy application at thresholds

## Critical Features

### Budget Configuration
- **Quarterly Period**: Q1-Q4 budget reset
- **Tag Filtering**: `environment=Sandbox` and `application=XYZ`
- **Multi-Region Support**: Applicable across accounts

### Alert Thresholds
| Threshold | Cost ($) | Action | Notification |
|---|---|---|---|
| 70% | $700 | Notify team | Email via SNS |
| 85% | $850 | Notify admins | Email via SNS + EventBridge |
| 95% | $950 | **Freeze & Shutdown** | Email + SNS + Lambda |

### Automation Actions
- **70%**: Alert user groups
- **85%**: Alert admin groups
- **95%**: Trigger automated:
  - EC2 instance shutdown
  - RDS DB instance shutdown
  - SNS notifications to all stakeholders
  - SCP-based resource freeze

## Prerequisites

- Terraform >= 1.0
- AWS Provider >= 5.0
- AWS Account (with billing access)
- SNS subscription approval
- CloudWatch monitoring enabled

## Usage

### Basic Usage

```hcl
module "automation" {
  source = "path/to/terraform-module-sbx-automation"

  aws_region             = "us-east-1"
  environment            = "Sandbox"
  quarterly_budget_limit = 1000
  budget_alert_emails    = ["ashishah0412@gmail.com"]

  common_tags = {
    Project     = "AON-AWS-Sandbox"
    CostCenter  = "Engineering"
    Owner       = "CloudOps"
  }
}
```

### With Resource Shutdown

```hcl
module "automation" {
  source = "path/to/terraform-module-sbx-automation"

  aws_region              = "us-east-1"
  environment             = "Sandbox"
  quarterly_budget_limit  = 1000
  budget_alert_emails     = ["ashishah0412@gmail.com"]
  enable_resource_shutdown = true

  # IAM roles for budget actions
  iam_roles_to_target = [
    "Sandbox-ec2-instance-role",
    "Sandbox-lambda-execution-role"
  ]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `aws_region` | AWS region | `string` | `"us-east-1"` | No |
| `environment` | Environment name | `string` | `"Sandbox"` | No |
| `quarterly_budget_limit` | Budget in USD | `number` | `1000` | No |
| `budget_alert_emails` | Alert email list | `list(string)` | `["ashishah0412@gmail.com"]` | No |
| `enable_resource_shutdown` | Enable Lambda shutdown | `bool` | `true` | No |
| `cloudwatch_period` | Alarm evaluation in seconds | `number` | `3600` | No |
| `common_tags` | Common resource tags | `map(string)` | See defaults | No |

## Outputs

| Name | Description |
|------|-------------|
| `budget_name` | AWS Budget name |
| `sns_topic_arn` | SNS topic for alerts |
| `cloudwatch_alarm_70_arn` | 70% threshold alarm ARN |
| `cloudwatch_alarm_85_arn` | 85% threshold alarm ARN |
| `cloudwatch_alarm_95_arn` | 95% threshold alarm ARN |
| `lambda_shutdown_function_arn` | Resource shutdown Lambda ARN |
| `eventbridge_rule_arn` | EventBridge rule ARN |
| `budget_thresholds` | Dollar amounts for each threshold |

## Budget Architecture

```
AWS Budget ($1000/Quarter)
    ↓
Tag Filter: environment=Sandbox
    ↓
    ├─→ 70% ($700)
    │    ├─ CloudWatch Alarm
    │    └─ SNS Email Alert
    │
    ├─→ 85% ($850)
    │    ├─ CloudWatch Alarm
    │    ├─ SNS Email Alert
    │    └─ Budget Action (Restrict Policy)
    │
    └─→ 95% ($950)
         ├─ CloudWatch Alarm
         ├─ SNS Email Alert
         ├─ EventBridge Rule Trigger
         └─ Lambda Execution
              ├─ Stop EC2 Instances
              ├─ Stop RDS Instances
              └─ SNS Notification
```

## Notification Flow

```
CloudWatch Metric
(EstimatedCharges)
       ↓
   Alarm Match
       ↓
   SNS Topic
       ↓
   Email Subscribers
   (ashishah0412@gmail.com)
       ↓
   ├─notification-70%
   ├─notification-85%
   └─notification-95%
       ↓
   (At 95%):
   EventBridge Rule
       ↓
   Lambda Function
       ↓
   Resource Shutdown
```

## Lambda Resource Shutdown Function

### Triggered at 95% Threshold

The Lambda function performs:
1. **Query EC2 Instances**: Tagged with `Environment=Sandbox`
2. **Stop EC2**: Halts running instances
3. **Stop RDS**: Stops database instances
4. **Notify SNS**: Sends detailed notification
5. **Log Events**: Tracks all actions taken

### Resource Selection

Only resources tagged with:
- `Environment`: Sandbox (or specified environment)
- Must be in correct AWS region

### Example Tagged Resources

```hcl
resource "aws_instance" "web_server" {
  tags = {
    Environment = "Sandbox"
    Name        = "web-server-prod"
  }
}

resource "aws_db_instance" "database" {
  tags = {
    Environment = "Sandbox"
    Application = "XYZ"
  }
}
```

## Monitoring & Dashboard

### CloudWatch Metrics
- `AWS/Billing:EstimatedCharges`
- `AWS/Lambda:Invocations` (resource shutdown)
- `AWS/EC2:StoppedInstances`
- `AWS/RDS:StoppedDBInstances`

### View Budget Status

```bash
# Check budget details
aws budgets describe-budgets --account-id ACCOUNT_ID

# Check alarm status
aws cloudwatch describe-alarms --alarm-names Sandbox-budget-70-percent

# Check recent SNS notifications
aws sns get-topic-attributes --topic-arn arn:aws:sns:us-east-1:ACCOUNT_ID:Sandbox-budget-alerts
```

## Cost Savings Tactics

### Automatic Actions at 95%
- Stop unused EC2 instances (saves 90% of compute costs)
- Stop non-critical RDS instances (saves 80% of database costs)
- Prevents runaway spending

### Manual Actions Recommended
- Delete unused EBS volumes
- Terminate unused RDS snapshots
- Remove unused security groups
- Clean up unused Lambda functions
- Delete old CloudWatch Logs

## SNS Email Confirmation

After Terraform apply, you must confirm SNS subscriptions:

1. Check email inbox (ashishah0412@gmail.com)
2. Click "Confirm subscription" link in email
3. Budget alerts will start after confirmation

### Resend Confirmation

```bash
aws sns list-subscriptions-by-topic --topic-arn arn:aws:sns:us-east-1:ACCOUNT_ID:Sandbox-budget-alerts
```

## IAM Permissions

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "budgets:CreateBudget",
        "budgets:DescribeBudgets",
        "budgets:DeleteBudget",
        "budgets:UpdateBudget",
        "budgets:CreateBudgetAction",
        "budgets:DescribeBudgetAction",
        "budgets:ExecuteBudgetAction",
        "ce:GetCostAndUsage",
        "sns:CreateTopic",
        "sns:Subscribe",
        "sns:Publish",
        "cloudwatch:PutMetricAlarm",
        "cloudwatch:DescribeAlarms",
        "cloudwatch:DeleteAlarms",
        "lambda:CreateFunction",
        "lambda:DeleteFunction",
        "lambda:UpdateFunctionCode",
        "iam:CreateRole",
        "iam:PutRolePolicy",
        "iam:PassRole",
        "events:PutRule",
        "events:PutTargets",
        "events:RemoveTargets",
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutRetentionPolicy"
      ],
      "Resource": "*"
    }
  ]
}
```

## Deployment

```bash
# Initialize
terraform init

# Validate
terraform validate

# Plan
terraform plan

# Apply
terraform apply

# Check status
terraform output
```

## Deployment Order

This module works with:
1. **terraform-module-sbx-rbac** - For IAM roles (optional)
2. **terraform-module-sbx-vpc** - For VPC context (optional)

This module is standalone and can be deployed independently.

## Post-Deployment

1. **Confirm SNS Subscriptions**: Check and confirm email
2. **Review Budget Settings**: `aws budgets describe-budgets`
3. **Test Alarms**: Monitor for first budget data
4. **Tag Resources**: Ensure all resources have Environment tag

## Testing & Validation

### Verify Budget Created
```bash
aws budgets describe-budgets --account-id ACCOUNT_ID --query 'Budgets[0].BudgetName'
```

### Check Alarms
```bash
aws cloudwatch describe-alarms --alarm-name-prefix Sandbox-budget
```

### Monitor SNS
```bash
aws sns get-topic-attributes --topic-arn <sns-arn>
```

### List Subscriptions
```bash
aws sns list-subscriptions-by-topic --topic-arn <sns-arn>
```

## Troubleshooting

### SNS Emails Not Received
- Check email's spam/junk folder
- Confirm subscription from email link
- Verify email address is correct

### Alarms Never Triggered
- Budget data updates daily (takes 24 hours for first data)
- Check actual spending vs. budget
- Verify resources have correct tags

### Lambda Not Executing
- Check EventBridge rule is enabled
- Verify Lambda role has EC2/RDS permissions
- Check Lambda logs in CloudWatch

### Budget Not Appearing
- Wait 24 hours for AWS to activate budget
- Verify account has billing enabled
- Check IAM permissions

## Cost Impact

- **AWS Budgets**: Free
- **CloudWatch Alarms**: ~$0.10/alert/month
- **SNS**: ~$0.50 per million notifications
- **Lambda**: ~$0.20 per million invocations (likely < $1/month)
- **Total**: < $2/month for budget automation

## Cleanup

```bash
terraform destroy
```

## Version History

### v1.0.0
- Initial release
- AWS Budgets with multi-tier alerts
- CloudWatch alarms and SNS notifications
- Lambda-based resource shutdown
- EventBridge integration
- Production-ready configuration

## License

Internal Use Only - AON Sandbox Automation Project

## Contributors

AON Cloud Operations Team
