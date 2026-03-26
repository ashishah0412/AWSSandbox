# AWS AWS Sandbox - Master Orchestration Module

## Overview

This is the master Terraform module that orchestrates the complete  AWS Sandbox infrastructure. It brings together six specialized child modules to create a production-ready, cost-controlled, and security-focused AWS environment designed for comprehensive sandbox deployment and testing.

**Repository**: `CEPS-AWS-Sandbox`

## Architecture

### High-Level Deployment Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                   CEPS-AWS-Sandbox Master                        │
│              (Main Orchestration - THIS REPOSITORY)              │
└─────────────────────────────────────────────────────────────────┘
                           │
          ┌────────────────┼────────────────┐
          │                │                │
    ┌─────▼─────┐    ┌─────▼─────┐    ┌────▼──────┐
    │    VPC    │    │   SUBNETS  │    │ SEC GROUPS│
    │  Module   │    │   Module   │    │  Module   │
    └─────┬─────┘    └─────┬─────┘    └────┬──────┘
          │                │                │
          └────────────────┼────────────────┘
                           │
          ┌────────────────┼────────────────┐
          │                │                │
    ┌─────▼─────┐    ┌─────▼─────┐    ┌────▼──────┐
    │  FIREWALL │    │   RBAC    │    │ AUTOMATION│
    │  Module   │    │  Module   │    │  Module   │
    └───────────┘    └───────────┘    └───────────┘
```

### Network Architecture

```
VPC: 10.10.0.0/16
│
├─ PRIVATE SUBNET (10.10.1.0/24)
│  ├─ Resources: EC2, RDS, Internal Services
│  ├─ NACL Rules: VPC<->Private, 203.0.113.0/24 TCP 1025-65535
│  ├─ Default Deny: All other traffic
│  └─ IGW: None (Fully Private)
│
├─ PUBLIC SUBNET (10.10.2.0/24)
│  ├─ Resources: ALB, NAT Gateway, Bastion
│  ├─ NACL Rules: VPC<->Public, 203.0.113.0/24 HTTP/HTTPS
│  ├─ Default Deny: All other traffic
│  └─ IGW: Yes (Internet Access)
│
├─ FIREWALL SUBNET (10.10.5.0/24)
│  ├─ Resources: AWS Network Firewall
│  ├─ NACL Rules: VPC<->Firewall, 10.10.5.0/24 TCP 1025-65535
│  ├─ Default Deny: All other traffic
│  └─ Routes: Traffic inspection
│
├─ VPC ENDPOINTS
│  ├─ S3 Gateway: Reduces data transfer costs
│  └─ DynamoDB Gateway: Private service access
```

### Security Architecture

```
┌─ EXTERNAL TRAFFIC (203.0.113.0/24)
│
├─ NACL Rules (Stateless)
│  └─ Explicit allow-lists, implicit deny-all
│
├─ NETWORK FIREWALL (AWS Network Firewall)
│  ├─ Stateless Rules: SYN filtering, port validation
│  ├─ Stateful Rules: Connection tracking, threat detection
│  └─ Logging: CloudWatch Logs + optional S3
│
├─ SECURITY GROUPS (Stateful)
│  ├─ Private SG: EC2/Compute (restrictive ingress)
│  ├─ Public SG: ALB (HTTP/HTTPS only)
│  ├─ Firewall SG: Network Firewall (internal)
│  ├─ Database SG: RDS (MySQL 3306, PostgreSQL 5432)
│  └─ Management SG: Bastion (SSH 22, RDP 3389)
│
└─ IAM/RBAC (Identity-based control)
   ├─ Developer Group: CRUD permissions (tag-filtered)
   ├─ Viewer Group: Read-only access
   ├─ Instance Role: EC2 SSM access, S3, CloudWatch
   ├─ Lambda Role: VPC access, resource control
   └─ Cost Control Role: Stop/terminate resources
```

### Cost Control Architecture

```
┌─ BUDGET: $1,000/Quarter
│
├─ 70% ($700) Threshold
│  └─ Action: SNS notification to admins
│
├─ 85% ($850) Threshold
│  ├─ Action: SNS notification (urgent)
│  └─ Action: Apply restrictive IAM policy
│
└─ 95% ($950) Threshold
   ├─ Action: SNS notification (critical)
   ├─ Action: EventBridge → Lambda trigger
   ├─ Lambda: Stop all EC2 instances
   ├─ Lambda: Stop all RDS instances
   └─ CloudWatch: Alert dashboard
```

## Prerequisites

### Local Development

```bash
# Required
- Terraform >= 1.0
- AWS CLI >= 2.0
- AWS Account with appropriate permissions
- Git

# Optional but recommended
- jq (for JSON processing)
- Terraform Cloud/Remote State (for team environments)
- VS Code with Terraform extension
```

### AWS Permissions Required

Create/manage the following AWS resources:
- EC2 (VPC, Subnets, Security Groups, Network Firewall)
- IAM (Roles, Policies, Groups)
- CloudWatch (Logs, Alarms)
- SNS (Topics, Subscriptions)
- Budgets (AWS Budgets, Budget Actions)
- EventBridge (Rules, Targets)
- Lambda (Functions, Roles)
- S3 (VPC Endpoints, Buckets for logging)

**Recommended**: Attach `AdministratorAccess` policy to your AWS user/role for sandbox setup.

### Environment Setup

```bash
# 1. Configure AWS Credentials
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_REGION="us-east-1"

# 2. Or use AWS CLI configuration
aws configure

# 3. Verify AWS credentials
aws sts get-caller-identity
```

## Repository Structure

```
CEPS-AWS-Sandbox/
├── main.tf                          # Master orchestration (module composition)
├── variables.tf                     # Input variables (consolidated from all modules)
├── outputs.tf                       # Output variables (comprehensive deployment info)
├── terraform.tfvars                 # Variable defaults
├── versions.tf                      # Terraform version constraints (optional)
├── README.md                        # This file
├── .gitignore                       # Git ignore rules
├── .terraform/                      # Cached module sources (local only)
├── terraform.tfstate*               # State file (local only, use remote for production)
│
├── modules/                         # Child module subdirectory
│   ├── terraform-module-sbx-vpc/
│   ├── terraform-module-sbx-subnet/
│   ├── terraform-module-sbx-securitygroup/
│   ├── terraform-module-sbx-firewall/
│   ├── terraform-module-sbx-rbac/
│   └── terraform-module-sbx-automation/
│
└── pipelines/                       # Azure DevOps pipeline configuration (optional)
    └── azure-pipelines.yml          # CI/CD pipeline definition
```

## Module Dependencies

```
terraform-module-sbx-vpc (Foundation)
    ↓
    ├─→ terraform-module-sbx-subnet (Requires VPC ID)
    │   ├─→ terraform-module-sbx-firewall (Requires VPC + Subnets)
    │   └─→ terraform-module-sbx-securitygroup (Requires VPC ID)
    │
    └─→ terraform-module-sbx-rbac (No dependencies)
        └─→ terraform-module-sbx-automation (No dependencies)
```

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/your-org/CEPS-AWS-Sandbox.git
cd CEPS-AWS-Sandbox
```

### 2. Initialize Terraform

```bash
terraform init

# This will:
# - Download AWS provider
# - Cache local module sources from ./modules/
# - Initialize .terraform directory
```

### 3. Review the Plan

```bash
terraform plan -out=tfplan

# This will:
# - Validate Terraform syntax
# - Check module dependencies
# - Display all resources to be created
# - Estimate costs (if using cost estimation)
```

### 4. Apply the Configuration

```bash
# Standard deployment
terraform apply tfplan

# Or interactive (not recommended for production)
terraform apply

# This will:
# - Create VPC and subnets
# - Deploy security groups and network firewall
# - Create IAM roles and policies
# - Set up budgets and alarms
# - Deploy Lambda function
# - Trigger SNS email confirmation
```

### 5. Confirm SNS Email Subscription

```
1. Check email inbox: ashishah0412@gmail.com
2. Click "Confirm subscription" link from AWS SNS
3. Budget alerts will start arriving once confirmed
```

### 6. Retrieve Outputs

```bash
# Pretty-print all outputs
terraform output

# Get specific output
terraform output -json sandbox_deployment_summary | jq '.'

# Export to file
terraform output -json > deployment-info.json
```

## Configuration Options

### Regional Deployment

```hcl
# terraform.tfvars
aws_region = "us-east-1"           # Change to different region
vpc_cidr_block = "10.10.0.0/16"    # Customize VPC CIDR
```

Supported regions:
- us-east-1, us-east-1
- us-west-1, us-west-2
- eu-west-1, eu-central-1
- ap-southeast-1, ap-northeast-1

### Budget Configuration

```hcl
# terraform.tfvars
quarterly_budget_limit = 1000                       # Total budget in USD
budget_start_date = "2024-01-01_00:00"                    # Q1 start (format: YYYY-MM-DD_HH:MM)
budget_end_date = "2024-12-31_23:59"                      # Q4 end (format: YYYY-MM-DD_HH:MM)

budget_alert_emails = [
  "ashishah0412@gmail.com",                         # Primary alert
  "cloud-ops@company.com"                           # Optional: CC
]

enable_resource_shutdown = true                     # Auto-stop at 95%
```

### Firewall Configuration

```hcl
# terraform.tfvars
firewall_enable_s3_logging = false                  # S3 logging (additional cost)
firewall_enable_alerts = true                       # EventBridge alerts

stateless_rule_group_capacity = 100                 # Adjust for traffic volume
stateful_rule_group_capacity = 1000                 # Adjust for connections
```

### Feature Toggles

```hcl
# terraform.tfvars - Enable/disable optional components
enable_s3_endpoint = true                           # S3 Gateway Endpoint
enable_dynamodb_endpoint = true                     # DynamoDB Gateway Endpoint
enable_database_sg = true                           # RDS Security Group
enable_management_sg = true                         # Bastion Security Group
enable_ec2_instance_role = true                     # EC2 instance role
enable_lambda_execution_role = true                 # Lambda role
enable_rds_monitoring_role = true                   # RDS monitoring
enable_cost_control_role = true                     # Budget automation role
enable_sandbox_groups = true                        # IAM groups
```

## Deployment Options

### Option 1: Direct Terraform Execution

**Best for**: Local development, testing, quick changes

```bash
# Step-by-step deployment
terraform init
terraform plan -out=tfplan
terraform apply tfplan

# Cleanup
terraform destroy
```

**Pros**:
- Full control over deployment
- Immediate feedback
- No external dependencies

**Cons**:
- Manual state management
- No audit trail
- Environment-specific configurations

### Option 2: Azure DevOps Pipeline

**Best for**: Team environments, production, CI/CD automation

```bash
# 1. Configure Azure DevOps project
#    - Create Service Connection to AWS
#    - Set up Variable Groups for secrets

# 2. Trigger pipeline
git push origin main

# 3. Pipeline automatically:
#    - Validates Terraform
#    - Creates plan artifacts
#    - Waits for approval
#    - Applies configuration
#    - Reports results
```

See [Azure DevOps Pipeline Guide](#azure-devops-pipeline-deployment) below.

## Deployment Instructions

### 1. Validate Environment

```bash
# Check Terraform syntax
terraform validate

# Verify module sources
terraform get

# Check AWS credentials
aws sts get-caller-identity
```

### 2. Plan Deployment

```bash
# Generate detailed plan
terraform plan -out=tfplan

# Review plan
cat tfplan

# Estimate costs
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-12-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE
```

### 3. Apply Configuration

```bash
# Apply from saved plan
terraform apply tfplan

# Wait for completion (5-10 minutes typical)
# Terraform will output resource IDs
```

### 4. Post-Deployment Verification

```bash
# Verify resources
aws ec2 describe-vpcs --filters "Name=cidr,Values=10.10.0.0/16"
aws sns list-topics
aws budgets describe-budget --account-id XXXX --budget-name Sandbox

# Test VPC endpoints
aws s3 ls                              # Should work through endpoint
aws ec2 describe-security-groups

# Monitor logs
aws logs describe-log-groups | grep sandbox
```

### 5. Destroy Infrastructure (When Done)

```bash
# Delete all resources
terraform destroy

# Alternatively, save state for later
terraform state pull > backup.tfstate
rm -rf .terraform
```

## Outputs and Access

### Key Deployment Outputs

After successful deployment, Terraform will output:

```
Outputs:
  vpc_id = "vpc-xxxxx"
  private_subnet_id = "subnet-xxxxx"
  public_subnet_id = "subnet-xxxxx"
  firewall_id = "arn:aws:network-firewall:..."
  budget_limit_amount = 1000
  sns_topic_arn = "arn:aws:sns:..."
  sandbox_deployment_summary = {
    "vpc" : {...},
    "subnets" : {...},
    "security_groups" : {...},
    "iam" : {...},
    "cost_control" : {...}
  }
```

### Accessing the Sandbox

#### 1. EC2 Instance in Private Subnet

```bash
# Use Session Manager (SSM) via EC2 Instance Role
aws ssm start-session --target i-xxxxx

# No SSH key needed - authentication via IAM
# Internet access through NAT Gateway
```

#### 2. RDS Database Access

From EC2 instance in private subnet:

```bash
# MySQL
mysql -h rds-endpoint.rds.amazonaws.com -u admin -p sandbox_db

# PostgreSQL
psql -h rds-endpoint.rds.amazonaws.com -U admin -d sandbox_db
```

#### 3. CloudWatch Logs

```bash
# View VPC Flow Logs
aws logs tail /aws/vpc/flowlogs/Sandbox --follow

# View Firewall Alerts
aws logs tail /aws/network-firewall/Sandbox/alerts --follow

# View Budget Automation
aws logs tail /aws/sandbox/Sandbox/budget-automation --follow
```

#### 4. Budget Alerts via SNS

```bash
# Confirm subscription
# Check: ashishah0412@gmail.com for SNS confirmation link

# Manual testing
aws sns publish \
  --topic-arn arn:aws:sns:us-east-1:ACCOUNT-ID:Sandbox-budget-alerts \
  --message "Test message from CloudOps team"
```

## Cost Estimation

### Monthly Breakdown (Estimated)

```
VPC:
  - VPC: $0.00 (included)
  - Data Transfer: $5-20/month (depends on usage)
  - VPC Endpoints (S3, DynamoDB): $0.00 per month
  
Network:
  - NAT Gateway: $32/month (if used)
  - Network Firewall: $100/month + $0.65/FW-hour-used
  
Compute:
  - EC2 (t3.micro): $3.79/month (first year free eligible)
  
Database:
  - RDS (t3.micro): $10-30/month
  
Logging:
  - CloudWatch Logs: $0.50/GB ingested
  - VPC Flow Logs: ~$5-10/month
  
Automation:
  - Lambda: $0.20/million (free tier)
  - EventBridge: $0.35/million (free tier)
  - SNS: $0.50/million (free tier)
  
Budget:
  - AWS Budgets: $0.00 (free)
  - Budget Actions: $0.00 (free)

TOTAL (Light Usage): ~$100-150/month
TOTAL (Heavy Usage): ~$500-1000/month
```

### Budget Thresholds

At $1,000/quarter budget:

| Threshold | USD Amount | Alert Type |
|-----------|-----------|-----------|
| 70% | $700 | Email notification |
| 85% | $850 | Email + Policy restriction |
| 95% | $950 | Email + Auto-shutdown |

## Monitoring and Alerts

### CloudWatch Alarms

```
Alarm 1: Budget at 70% ($700)
  - Metric: EstimatedCharges
  - Threshold: >= 700
  - Action: Notify SNS
  
Alarm 2: Budget at 85% ($850)
  - Metric: EstimatedCharges
  - Threshold: >= 850
  - Action: Notify SNS + Apply IAM policy
  
Alarm 3: Budget at 95% ($950)
  - Metric: EstimatedCharges
  - Threshold: >= 950
  - Action: EventBridge → Lambda → Stop resources
```

### Monitoring Dashboard

```bash
# Create custom dashboard
aws cloudwatch put-dashboard \
  --dashboard-name "AWS-Sandbox" \
  --dashboard-body file://dashboard.json
```

## Troubleshooting

### Common Issues

#### 1. Terraform Initialization Fails

**Symptom**: `Error: Error getting default AWS region`

**Solution**:
```bash
export AWS_REGION=us-east-1
export AWS_DEFAULT_REGION=us-east-1
aws configure
```

#### 2. Module Sources Not Found

**Symptom**: `Error: Failed to download module from ./modules/...`

**Solution**:
```bash
# Ensure module subdirectories exist
ls -la modules/

# If missing, clone module repositories
git clone https://github.com/your-org/terraform-module-sbx-vpc modules/terraform-module-sbx-vpc
```

#### 3. SNS Email Not Received

**Symptom**: Email subscription not confirmed, no budget alerts

**Solution**:
```bash
# Check spam folder
# Resend confirmation
aws sns list-subscriptions-by-topic \
  --topic-arn arn:aws:sns:us-east-1:ACCOUNT:Sandbox-budget-alerts

# Manually confirm if needed
aws sns set-subscription-attributes \
  --subscription-arn arn:aws:sns:... \
  --attribute-name SubscriptionRoleArn \
  --attribute-value <role-arn>
```

#### 4. Permission Denied Errors

**Symptom**: `AccessDenied: User is not authorized to perform...`

**Solution**:
```bash
# Check IAM permissions
aws iam user-get-inline-policy-list --user-name your-user

# Verify AWS credentials
aws sts get-caller-identity

# Re-authenticate if needed
aws configure
```

#### 5. Network Firewall Fails to Deploy

**Symptom**: `Error: Error creating network firewall`

**Solution**:
```bash
# Check region support
aws network-firewall describe-resource-policy --resource-arn ...

# Verify firewall subnet exists
aws ec2 describe-subnets --filters "Name=tag:Name,Values=SandboxFirewall"

# Check capacity
terraform plan | grep -i firewall
```

### Debug Commands

```bash
# Enable debug logging
export TF_LOG=DEBUG
terraform apply

# Validate all modules
terraform validate --recursive

# Check module graph
terraform graph | dot -Tsvg > graph.svg

# List all resources
terraform state list

# Inspect specific resource
terraform state show module.vpc.aws_vpc.main

# Show outputs
terraform output -json | jq '.'

# Test AWS connectivity
aws s3 ls                              # Test S3 endpoint
aws dynamodb list-tables               # Test DynamoDB endpoint
```

## State Management

### Local State (Development)

```bash
# Default behavior - state stored locally
terraform plan
terraform apply

# Backup before major changes
cp terraform.tfstate terraform.tfstate.backup
```

### Remote State (Production - AWS S3)

```bash
# Create S3 bucket for state
aws s3api create-bucket \
  --bucket sandbox-terraform-state-${ACCOUNT_ID} \
  --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket sandbox-terraform-state-${ACCOUNT_ID} \
  --versioning-configuration Status=Enabled

# Create backend.tf
cat > backend.tf <<EOF
terraform {
  backend "s3" {
    bucket         = "sandbox-terraform-state-${ACCOUNT_ID}"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
EOF

# Migrate state
terraform init
```

### DynamoDB Locking (Team Environments)

```bash
# Create lock table
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
```

## Azure DevOps Pipeline Deployment

### Prerequisites

1. **Azure DevOps Project**: Created and configured
2. **Service Connection**: AWS credentials configured
3. **Variable Groups**: Sensitive values stored securely

### Configuration Steps

#### 1. Create Azure DevOps Service Connection

```yaml
# Project Settings → Service Connections → New Service Connection
Service Type: AWS
Authentication Method: AWS Access Key
Access Key ID: <your-access-key>
Secret Access Key: <your-secret-key>
Service Connection Name: AWS-Sandbox
```

#### 2. Create Variable Groups

```bash
# Navigate to Pipelines → Library → + Variable group
# Create: aws-sandbox-secrets
#   - AWS_ACCESS_KEY_ID (Secret)
#   - AWS_SECRET_ACCESS_KEY (Secret)
#   - AWS_REGION = us-east-1
#   - SNS_EMAIL = ashishah0412@gmail.com
#   - BUDGET_LIMIT = 1000

# Create: terraform-vars
#   - TF_VERSION = 1.5.0
#   - AWS_PROFILE = default
#   - ENABLE_FIREWALL = true
#   - ENABLE_BUDGET_AUTOMATION = true
```

#### 3. Create Pipeline File

```yaml
# File: azure-pipelines.yml
trigger:
  - main

pool:
  vmImage: 'ubuntu-latest'

variables:
  - group: aws-sandbox-secrets
  - group: terraform-vars

stages:
  - stage: Validate
    jobs:
      - job: TerraformValidate
        steps:
          - task: TerraformTaskV4@4
            inputs:
              provider: 'aws'
              command: 'init'
              backendServiceAWS: 'AWS-Sandbox'
              backendAWSBucketName: 'sandbox-tf-state'
              backendAWSKey: 'terraform.tfstate'
          
          - task: TerraformTaskV4@4
            inputs:
              provider: 'aws'
              command: 'validate'

  - stage: Plan
    dependsOn: Validate
    jobs:
      - job: TerraformPlan
        steps:
          - task: TerraformTaskV4@4
            inputs:
              provider: 'aws'
              command: 'plan'
              commandOptions: '-out=tfplan'
          
          - task: PublishBuildArtifacts@1
            inputs:
              pathToPublish: 'tfplan'
              artifactName: 'terraform-plan'

  - stage: Approval
    dependsOn: Plan
    jobs:
      - job: waitForValidation
        displayName: Wait for Approval
        pool: server
        timeoutInMinutes: 1440
        steps:
          - task: ManualValidation@0
            inputs:
              notifyUsers: 'cloud-ops@company.com'
              instructions: 'Review Terraform plan and approve/reject'

  - stage: Apply
    dependsOn: [Plan, Approval]
    jobs:
      - job: TerraformApply
        steps:
          - task: DownloadBuildArtifacts@0
            inputs:
              artifactName: 'terraform-plan'
          
          - task: TerraformTaskV4@4
            inputs:
              provider: 'aws'
              command: 'apply'
              commandOptions: 'tfplan'
          
          - task: TerraformTaskV4@4
            inputs:
              provider: 'aws'
              command: 'output'
            name: TerraformOutputs

  - stage: Notify
    dependsOn: Apply
    condition: succeeded()
    jobs:
      - job: NotifySuccess
        steps:
          - script: |
              echo "Deployment successful!"
              echo "SNS Topic: $(sns_topic_arn)"
            displayName: 'Post-Deployment Notification'
```

#### 4. Execute Pipeline

```bash
# Commit and push to main branch
git add azure-pipelines.yml
git commit -m "Add Terraform pipeline"
git push origin main

# Azure DevOps automatically triggers pipeline
# Monitor: Pipelines → Azure Pipelines → Run details
```

## Cleanup and Destruction

### Safe Destruction

```bash
# Plan destruction first
terraform plan -destroy -out=destroy.tfplan

# Review what will be destroyed
cat destroy.tfplan

# Apply destruction
terraform apply destroy.tfplan

# Verify cleanup
aws ec2 describe-vpcs --filters "Name=cidr,Values=10.10.0.0/16"
aws sns list-topics
```

### Backup Before Destruction

```bash
# Export state
terraform state pull > final-state.json

# Export outputs
terraform output -json > final-outputs.json

# Compress for archive
tar czf sandbox-backup-$(date +%Y%m%d).tar.gz terraform.tfstate* final-state.json final-outputs.json
```

### Retention Policy

- **Active**: Keep state files and infrastructure running
- **Paused**: `terraform state` (manual restore possible)
- **Destroyed**: `terraform destroy` (complete removal, backup first)

## Performance Optimization

### Reduce Deployment Time

```bash
# Parallel resource creation (default: 10)
terraform apply -parallelism=20

# Skip refresh
terraform apply -refresh=false

# Use lock-free operations
terraform apply -lock=false
```

### Cost Optimization

```hcl
# In terraform.tfvars - Reduce costs

# Use smaller instance types
variable "instance_type" {
  default = "t3.micro"  # Instead of t3.medium
}

# Disable firewall S3 logging
firewall_enable_s3_logging = false

# Reduce log retention
vpc_flow_logs_retention_days = 7  # Instead of 30
firewall_logs_retention_days = 7

# Disable optional VPC endpoints if not needed
enable_s3_endpoint = false
enable_dynamodb_endpoint = false
```

## Best Practices

### 1. Version Control

```bash
# Always commit state and variables
git add main.tf variables.tf terraform.tfvars
git commit -m "Configuration changes: update VPC CIDR"

# Never commit secrets
echo "*.tfstate" >> .gitignore
echo "*.tfvars" >> .gitignore
```

### 2. Team Collaboration

```bash
# Use remote state (S3 + DynamoDB)
# Use variable groups in Azure DevOps
# Require code reviews before apply
# Use branch protection rules
```

### 3. Disaster Recovery

```bash
# Regular backups
aws s3 sync s3://sandbox-tf-state ./backups/

# Document all manual changes
# Test destroy/recreate quarterly
# Maintain runbooks for incidents
```

### 4. Security Hardening

```hcl
# Enable all security features
firewall_enable_alerts = true
enable_cost_control_role = true

# Restrict sandbox access
enable_management_sg = true  # Bastion only
enable_sandbox_groups = true  # IAM controls

# Monitor all activity
vpc_flow_logs_retention_days = 90
firewall_logs_retention_days = 90
```

## Advanced Topics

### Custom Firewall Rules

Edit `modules/terraform-module-sbx-firewall/main.tf`:

```hcl
blocked_domains = [
  "evil.com",
  "malware.net",
  "phishing.site"
]
```

### IAM Policy Customization

Edit `modules/terraform-module-sbx-rbac/main.tf`:

```hcl
# Add custom developer policy actions
developer_actions = [
  "ec2:*",
  "rds:*",
  "s3:Get*",
  "s3:List*"
]
```

### Budget Action Automation

Edit `modules/terraform-module-sbx-automation/main.tf`:

```hcl
# Custom Lambda shutdown logic
lambda_timeout = 60
lambda_memory = 512
```

## Support and Troubleshooting

### Getting Help

1. **Check Terraform Docs**: https://registry.terraform.io/providers/hashicorp/aws/latest
2. **AWS Documentation**: https://docs.aws.amazon.com/
3. **Terraform Modules**: https://github.com/your-org/terraform-modules
4. **Team Slack**: #cloud-ops

### Logging and Diagnostics

```bash
# Enable detailed logging
export TF_LOG=TRACE
terraform plan 2>&1 | tee plan.log

# Check AWS CloudTrail
aws cloudtrail lookup-events --max-results 50

# Monitor real-time feedback
watch -n 1 'aws ec2 describe-instances'
```

### Escalation Path

1. Team Slack: #cloud-ops (general questions)
2. GitHub Issues: (bugs/features)
3. Cloud Leadership: (policy/architecture)
4. AWS TAM: (AWS-specific issues)

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2024-01-15 | Initial release |
| 1.1 | 2024-02-01 | Added Azure Pipelines support |
| 2.0 | 2024-03-01 | Production-grade hardening |

