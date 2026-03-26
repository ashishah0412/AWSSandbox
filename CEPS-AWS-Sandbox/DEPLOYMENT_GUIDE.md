# Deployment Guide - AON AWS Sandbox

## Table of Contents

1. [Local Deployment (Direct Terraform)](#local-deployment)
2. [Azure DevOps Pipeline Deployment](#azure-devops-deployment)
3. [Verification Checklist](#verification-checklist)
4. [Troubleshooting](#troubleshooting)
5. [Post-Deployment Tasks](#post-deployment-tasks)
6. [Cleanup](#cleanup)

---

## Local Deployment

### Prerequisites Check

```bash
# 1. Verify Terraform installation
terraform --version
# Expected: Terraform v1.0 or higher

# 2. Verify AWS CLI installation
aws --version
# Expected: AWS CLI 2.0 or higher

# 3. Configure AWS credentials
aws configure
# Enter: AWS Access Key ID
# Enter: AWS Secret Access Key
# Enter: Default region (us-east-1)
# Enter: Default output format (json)

# 4. Verify AWS credentials
aws sts get-caller-identity
# Should return your AWS Account ID, User ARN, and Account ID
```

### Step 1: Clone the Repository

```bash
# Clone the CEPS-AWS-Sandbox repository
git clone https://github.com/your-org/CEPS-AWS-Sandbox.git
cd CEPS-AWS-Sandbox

# Verify directory structure
ls -la
# Should show: main.tf, variables.tf, outputs.tf, terraform.tfvars, README.md, modules/

# Check child modules
ls -la modules/
# Should list all 6 modules:
# - terraform-module-sbx-vpc
# - terraform-module-sbx-subnet
# - terraform-module-sbx-securitygroup
# - terraform-module-sbx-firewall
# - terraform-module-sbx-rbac
# - terraform-module-sbx-automation
```

### Step 2: Initialize Terraform

```bash
# Initialize Terraform (downloads providers and modules)
terraform init

# Expected output:
# - Initializing the backend...
# - Initializing modules...
# - Initializing provider plugins...
# - Terraform has been successfully initialized!

# Verify initialization
ls -la .terraform/
# Should contain: modules/, providers/, .terraform.lock.hcl
```

### Step 3: Validate Configuration

```bash
# Validate Terraform syntax
terraform validate

# Expected output:
# Success! The configuration is valid.

# (Optional) Check formatting
terraform fmt -check -recursive

# Format and fix (if needed)
terraform fmt -recursive
```

### Step 4: Review Configuration

```bash
# View variable defaults
cat terraform.tfvars

# Review main configuration
cat main.tf | head -50

# Check module sources
grep "source" main.tf
```

### Step 5: Generate Plan

```bash
# Create infrastructure plan
terraform plan -out=tfplan

# This will:
# - Query AWS for existing resources
# - Compare with Terraform configuration
# - Generate plan for all resources
# - Display summary (typically 100+ resources)

# Expected output:
# Plan: X to add, 0 to change, 0 to destroy.
# Saved the plan to: tfplan

# Export plan as human-readable
terraform show tfplan > tfplan.txt

# View plan summary
head -100 tfplan.txt
tail -50 tfplan.txt

# Count resources (using jq if installed)
terraform show -json tfplan | jq '[.resource_changes[]] | length'
```

### Step 6: Review Plan Details

```bash
# Check VPC resources
grep -A 3 "resource \"aws_vpc\"" tfplan.txt

# Check subnet resources
grep -A 3 "subnet" tfplan.txt

# Check firewall
grep -A 3 "firewall" tfplan.txt

# Check IAM resources
grep -A 3 "iam_" tfplan.txt

# Check budget
grep -A 3 "budget" tfplan.txt
```

### Step 7: Apply Configuration

```bash
# Apply the infrastructure plan
terraform apply tfplan

# This will:
# - Create VPC and subnets
# - Deploy security groups
# - Launch network firewall
# - Create IAM roles and policies
# - Set up budgets and alarms
# - Deploy Lambda function
# - Configure SNS topic
# - Take 5-10 minutes to complete

# You should see:
# Apply complete! Resources added: X, changed: 0, destroyed: 0.

# Monitor progress (in separate terminal)
watch -n 5 'aws ec2 describe-vpcs --filters "Name=tag:Environment,Values=Sandbox"'
```

### Step 8: Retrieve Outputs

```bash
# Display all outputs
terraform output

# Get specific output
terraform output vpc_id
terraform output firewall_id
terraform output sns_topic_arn

# Export outputs as JSON
terraform output -json > outputs.json

# View deployment summary
terraform output -raw sandbox_deployment_summary

# Save deployment notes
terraform output -raw deployment_notes > DEPLOYMENT_NOTES.txt
cat DEPLOYMENT_NOTES.txt
```

### Step 9: Confirm SNS Subscription

```bash
# Check for SNS confirmation email
# 1. Open email inbox (ashishah0412@gmail.com)
# 2. Find email from AWS Notifications (SNS)
# 3. Click "Confirm subscription" link
# 4. You should see: "Subscription confirmed!"

# Verify subscription (optional)
aws sns list-subscriptions-by-topic \
  --topic-arn arn:aws:sns:us-east-1:ACCOUNT-ID:Sandbox-budget-alerts

# Status should show: PendingConfirmation → Subscribed
```

### Step 10: Verify Deployment

```bash
# Check VPC creation
aws ec2 describe-vpcs --filters "Name=cidr,Values=10.10.0.0/16"

# Check subnets
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$(terraform output -raw vpc_id)"

# Check security groups
aws ec2 describe-security-groups \
  --filters "Name=vpc-id,Values=$(terraform output -raw vpc_id)" \
  --query 'SecurityGroups[].{Name:GroupName,ID:GroupId}'

# Check firewall
aws network-firewall describe-firewall \
  --firewall-arn $(terraform output -raw firewall_id)

# Check budget
aws budgets describe-budget \
  --account-id $(aws sts get-caller-identity --query Account --output text) \
  --budget-name Sandbox

# Check alarms
aws cloudwatch describe-alarms \
  --alarm-name-prefix Sandbox \
  --query 'MetricAlarms[].{Name:AlarmName,State:StateValue}'

# Check IAM groups
aws iam list-groups --query 'Groups[?starts_with(GroupName, `sandbox`)]'
```

---

## Azure DevOps Deployment

### Prerequisites

1. **Azure DevOps Project**: Already created and configured
2. **Git Repository**: CEPS-AWS-Sandbox repository pushed to Azure Repos or GitHub
3. **AWS Account**: Credentials available
4. **Service Connection**: AWS credentials configured in Azure DevOps
5. **Variable Groups**: Secrets stored in Azure DevOps

### Step 1: Create AWS Service Connection

```bash
# 1. Go to: Project Settings → Service Connections → New Service Connection
# 2. Select: AWS Connection
# 3. Fill in:
#    - AWS Access Key ID: [your-access-key]
#    - AWS Secret Access Key: [your-secret-key]
#    - Service Connection Name: AWS-Sandbox
#    - Grant access permission to all pipelines: ✓ Check
# 4. Click: Save

# Verify connection
# - The connection should appear in Service Connections list
# - Status should show "Ready"
```

### Step 2: Create Variable Groups

```bash
# 1. Go to: Pipelines → Library → + Variable group

# Create Variable Group 1: aws-sandbox-secrets
#   - Name: aws-sandbox-secrets
#   - Variables:
#     - AWS_ACCESS_KEY_ID = [your-access-key] (Mark as secret)
#     - AWS_SECRET_ACCESS_KEY = [your-secret-key] (Mark as secret)
#     - AWS_ACCOUNT_ID = [your-account-id]
#     - AWS_REGION = us-east-1

# Create Variable Group 2: terraform-variables
#   - Name: terraform-variables
#   - Variables:
#     - TF_VERSION = 1.5.0
#     - ENVIRONMENT = Sandbox
#     - ENABLE_FIREWALL = true
#     - ENABLE_BUDGET_AUTOMATION = true
#     - QUARTERLY_BUDGET = 1000
#     - SNS_EMAIL = ashishah0412@gmail.com

# Verify variable groups
# - Both should appear in Library → Variable groups
# - Access is controlled via YAML pipeline
```

### Step 3: Configure S3 Backend (Optional but Recommended)

```bash
# Create S3 bucket for Terraform state
AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="sandbox-terraform-state-${AWS_ACCOUNT}"

aws s3api create-bucket \
  --bucket "$BUCKET_NAME" \
  --region us-east-1 \
  --create-bucket-configuration LocationConstraint=us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket "$BUCKET_NAME" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Block public access
aws s3api put-public-access-block \
  --bucket "$BUCKET_NAME" \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Create DynamoDB table for locking
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region us-east-1

echo "Backend configured successfully!"
echo "S3 Bucket: $BUCKET_NAME"
```

### Step 4: Set Up Branch Policies

```bash
# 1. Go to: Repos → Branches → main
# 2. Click: "..." → Branch policies
# 3. Enable:
#    - Require a minimum number of reviewers: 1
#    - Check expiration of pull request approval
#    - Require comment resolution: Yes
#    - Limit approval scope: Only primary reviewers
#    - Check for linked work items: Required
#    - Check for merge conflict resolution: Yes
# 4. Save
```

### Step 5: Create Pipeline

```bash
# 1. Go to: Pipelines → Create Pipeline
# 2. Select: GitHub / Azure Repos (where your code is)
# 3. Select repository: CEPS-AWS-Sandbox
# 4. Select: Existing Azure Pipelines YAML file
# 5. Path: /azure-pipelines.yml
# 6. Click: Continue
# 7. Click: Save and run

# OR manually create the file:
# 1. Create file: azure-pipelines.yml (in repository root)
# 2. Paste pipeline YAML (provided above)
# 3. Commit and push
# 4. Pipeline runs automatically
```

### Step 6: Monitor Pipeline Execution

```bash
# View pipeline run details
# 1. Go to: Pipelines → All pipelines → CEPS-AWS-Sandbox
# 2. Click on latest run
# 3. View stages:
#    - Initialize (Job: TerraformInit)
#    - Plan (Job: TerraformPlan)
#    - ApprovalGate (Manual approval - click Approve/Reject)
#    - Apply (Job: TerraformApply)
#    - Validation (Job: ValidateDeployment)
#    - Notify (Job: SendNotifications)

# Download artifacts
# 1. Click "Published" in run summary
# 2. Download:
#    - terraform-plan (tfplan.txt, tfplan.json)
#    - terraform-outputs (outputs.json)
#    - deployment-summary (all artifacts)
```

### Step 7: Approve Deployment

```bash
# When approval is needed:
# 1. Pipeline reaches "ApprovalGate" stage
# 2. Review notification email at cloud-ops@aon.com
# 3. Go to: Pipelines → Run details
# 4. Click: "Manual Validation"
# 5. Click: "Approve" (or "Reject")
# 6. Add optional notes
# 7. Pipeline continues to Apply stage

# If rejected:
# - Pipeline stops
# - No infrastructure changes applied
# - Build marked as "Rejected"
```

### Step 8: Post-Deployment Notification

```bash
# You will receive email:
# From: terraform-bot@aon.com
# Subject: [AON Sandbox] Terraform Deployment Complete - Build #XXX
# 
# Email contains:
# - Build summary
# - Resources deployed
# - Next steps
# - Link to deployment artifacts
```

### Step 9: Retrieve Deployment Information

```bash
# 1. Go to: Pipelines → Run details → Artifacts
# 2. Download: terraform-outputs artifact
# 3. Open: outputs.json
# 4. Extract deployment details:
#    - VPC ID
#    - Subnet IDs
#    - Security Group IDs
#    - IAM Role ARNs
#    - Firewall ID
#    - Budget information
#    - SNS Topic ARN
```

---

## Verification Checklist

After deployment (local or pipeline), verify with this checklist:

### Network Resources

- [ ] VPC created with CIDR: 10.10.0.0/16
- [ ] Private subnet created: 10.10.1.0/24
- [ ] Public subnet created: 10.10.2.0/24
- [ ] Firewall subnet created: 10.10.5.0/24
- [ ] Internet Gateway attached to VPC
- [ ] Route tables created for all 3 subnets
- [ ] NACL rules deployed (default-deny + explicit allows)
- [ ] VPC endpoints: S3 and DynamoDB created

### Security Resources

- [ ] 5 Security groups created
- [ ] Private SG configured (EC2 compute)
- [ ] Public SG configured (ALB)
- [ ] Firewall SG configured (Network Firewall)
- [ ] Database SG configured (RDS)
- [ ] Management SG configured (Bastion)
- [ ] Inter-SG rules correct

### Firewall

- [ ] Network Firewall deployed
- [ ] Firewall policy created
- [ ] Stateless rule group created
- [ ] Stateful rule group created
- [ ] CloudWatch log groups created (alerts, flows)
- [ ] Firewall in "READY" state

### IAM/RBAC

- [ ] EC2 instance role created
- [ ] Lambda execution role created
- [ ] RDS monitoring role created
- [ ] Cost control role created
- [ ] IAM groups created (developers, viewers)
- [ ] Instance profiles created

### Cost Control

- [ ] AWS Budget created ($1,000/quarter)
- [ ] Budget notifications configured (70%, 85%, 95%)
- [ ] CloudWatch alarms created (3 alarms)
- [ ] SNS topic created and encrypted
- [ ] SNS email subscription confirmed
- [ ] Lambda function deployed
- [ ] EventBridge rule created

### CloudWatch Logs

- [ ] VPC Flow Logs log group exists
- [ ] Firewall alerts log group exists
- [ ] Firewall flows log group exists
- [ ] Budget automation log group exists
- [ ] All log groups have correct retention (30 days)

---

## Troubleshooting

### Common Issues and Solutions

#### 1. "Error: No Valid Credential Sources Found"

**Symptom**: `Error: No valid credential sources found`

**Causes**:
- AWS credentials not configured
- AWS CLI not authenticated
- Environment variables not set

**Solutions**:
```bash
# Option 1: Configure AWS CLI
aws configure
# Enter credentials when prompted

# Option 2: Set environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"

# Option 3: Verify current credentials
aws sts get-caller-identity

# Option 4: Check credential file
cat ~/.aws/credentials
cat ~/.aws/config
```

#### 2. "Error: AccessDenied: User is not authorized"

**Symptom**: `AccessDenied: EntityNotFound.AccessDenied`

**Causes**:
- IAM permissions too restrictive
- Using wrong AWS account
- Service principals not trusted

**Solutions**:
```bash
# Add required permissions
aws iam attach-user-policy \
  --user-name your-user \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# Or create custom policy (least privilege)
aws iam create-policy \
  --policy-name TerraformSandboxAccess \
  --policy-document file://terraform-policy.json

# List current policies
aws iam list-user-policies --user-name your-user

# Check current user
aws iam get-user
```

#### 3. "Error: Error creating VPC: InsufficientCidrBlock"

**Symptom**: `Error: Error creating VPC: InsufficientCidrBlock`

**Causes**:
- VPC CIDR already exists
- Region-specific limit reached
- IP range conflicts

**Solutions**:
```bash
# Check existing VPCs
aws ec2 describe-vpcs

# If conflict, change CIDR in terraform.tfvars
# Original: vpc_cidr_block = "10.10.0.0/16"
# Alternative: vpc_cidr_block = "10.20.0.0/16"

terraform plan  # Verify new CIDR
terraform apply
```

#### 4. "Error: Failed to download module"

**Symptom**: `Error: Failed to download module from source: ...`

**Causes**:
- Module subdirectory missing
- Git repository not cloned
- Module path incorrect

**Solutions**:
```bash
# Verify module structure
ls -la modules/
# Should show 6 subdirectories

# Re-init modules
terraform init -upgrade

# Or clone modules manually
git clone https://github.com/org/terraform-module-sbx-vpc \
  modules/terraform-module-sbx-vpc

# Verify module files
ls -la modules/terraform-module-sbx-vpc/main.tf
```

#### 5. "Error: SNS topic already exists"

**Symptom**: `Error: Error creating TopicAlreadyExists`

**Causes**:
- Previous deployment not cleaned up
- SNS topic name conflict

**Solutions**:
```bash
# List existing topics
aws sns list-topics

# Delete conflicting topic (if safe)
aws sns delete-topic --topic-arn arn:aws:sns:us-east-1:ACCOUNT:Sandbox-budget-alerts

# Re-apply Terraform
terraform apply
```

#### 6. "Error: Network Firewall not available in this region"

**Symptom**: `Error: InvalidAction: The service is not available in the selected region`

**Causes**:
- Region doesn't support Network Firewall
- Feature not enabled in region

**Solutions**:
```bash
# Change to supported region
# Supported regions:
# - us-east-1, us-east-1
# - us-west-2
# - eu-west-1, eu-central-1
# - ap-southeast-1, ap-northeast-1

# Edit terraform.tfvars
aws_region = "us-east-1"  # Change from us-east-1

terraform init
terraform plan
terraform apply
```

#### 7. "Error: Insufficient capacity in AZ"

**Symptom**: `InsufficientCapacityInAZ`

**Causes**:
- AWS availability zone at capacity
- Instance type not available

**Solutions**:
```bash
# Wait and retry
terraform apply

# Or change region/AZ
aws_region = "us-west-2"

terraform apply

# Or use different instance type (if deploying compute)
instance_type = "t3.small"  # Instead of t3.micro
```

#### 8. "Error: Terraform state locked"

**Symptom**: `Error: Error acquiring the state lock`

**Causes**:
- Another process holding lock
- DynamoDB lock table issue
- Stale lock file

**Solutions**:
```bash
# Check lock status
aws dynamodb scan --table-name terraform-locks

# Force unlock (ONLY if safe!)
terraform force-unlock <LOCK_ID>

# Or remove local lock file
rm -f .terraform.tfstate.lock.hcl

# Clear cache and retry
rm -rf .terraform/
terraform init
terraform plan
```

### Debug Mode

```bash
# Enable detailed logging
export TF_LOG=TRACE
export TF_LOG_PATH=terraform.log

# Run command
terraform plan

# Review logs
tail -100 terraform.log
grep -i error terraform.log
```

---

## Post-Deployment Tasks

### 1. Access the Sandbox

```bash
# From your terminal
# To use EC2 instances in private subnet via Session Manager

# List instances
aws ec2 describe-instances \
  --filters "Name=subnet-id,Values=$(terraform output -raw private_subnet_id)" \
  --query 'Reservations[].Instances[].{ID:InstanceId,Name:Tags[?Key==`Name`].Value|[0]}'

# Start session with instance
aws ssm start-session --target i-xxxxxxxxxx

# You now have shell access without SSH key!
```

### 2. Deploy Compute Resources

```bash
# Create EC2 instance in private subnet
aws ec2 run-instances \
  --image-id ami-xxxxxxxxxxx \
  --instance-type t3.micro \
  --key-name my-keypair \
  --security-group-ids sg-private \
  --subnet-id $(terraform output -raw private_subnet_id) \
  --iam-instance-profile Name=$(terraform output -raw ec2_instance_profile_name) \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Environment,Value=Sandbox},{Key=Name,Value=SandboxCompute}]'
```

### 3. Deploy Database

```bash
# Create RDS database in private subnet
aws rds create-db-instance \
  --db-instance-identifier sandbox-mysql \
  --db-instance-class db.t3.micro \
  --engine mysql \
  --allocated-storage 20 \
  --db-subnet-group-name sandbox-db-subnet \
  --vpc-security-group-ids sg-database \
  --no-publicly-accessible \
  --master-username admin \
  --master-user-password YourSecurePassword123!
```

### 4. Monitor Costs

```bash
# View current spending
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity DAILY \
  --metrics "UnblendedCost"

# View budget status
aws budgets describe-budget \
  --account-id $(aws sts get-caller-identity --query Account --output text) \
  --budget-name Sandbox

# View budget notifications
aws sns list-subscriptions-by-topic \
  --topic-arn $(terraform output -raw sns_topic_arn)
```

### 5. Configure Logging and Monitoring

```bash
# View VPC Flow Logs
aws logs tail /aws/vpc/flowlogs/Sandbox --follow

# View Firewall Alerts
aws logs tail /aws/network-firewall/Sandbox/alerts --follow

# View Firewall Flows
aws logs tail /aws/network-firewall/Sandbox/flows --follow

# Create CloudWatch Dashboard
aws cloudwatch put-dashboard \
  --dashboard-name "AON-Sandbox-Overview" \
  --dashboard-body file://dashboard.json
```

### 6. Add Users to IAM Groups

```bash
# Add user to developers group
aws iam add-user-to-group \
  --group-name sandbox-developers \
  --user-name john.doe

# Add user to viewers group
aws iam add-user-to-group \
  --group-name sandbox-viewers \
  --user-name jane.smith

# Verify group membership
aws iam get-group --group-name sandbox-developers
```

---

## Cleanup

### Complete Infrastructure Destruction

```bash
# Step 1: Plan destruction
terraform plan -destroy -out=destroy.tfplan

# Step 2: Review what will be destroyed
terraform show destroy.tfplan | head -100

# Step 3: Apply destruction
terraform apply destroy.tfplan

# Step 4: Verify cleanup
aws ec2 describe-vpcs --filters "Name=cidr,Values=10.10.0.0/16"
# Should return: VPCs = []

# Step 5: Remove local files
rm -rf .terraform/
rm terraform.tfstate*
rm tfplan*
rm destroy.tfplan
```

### Selective Destruction (Remove Only Some Resources)

```bash
# Example: Remove only the firewall (keep other resources)
terraform destroy -target=module.firewall

# Example: Remove multiple targets
terraform destroy \
  -target=module.firewall \
  -target=module.automation

# Verify partial destruction
terraform plan
```

### Backup Before Deletion

```bash
# Export state to file
terraform state pull > backup-$(date +%Y%m%d).tfstate

# Export outputs
terraform output -json > backup-outputs-$(date +%Y%m%d).json

# Compress for archival
tar czf sandbox-backup-$(date +%Y%m%d-%H%M%S).tar.gz \
  backup-*.tfstate \
  backup-*.json \
  terraform.tfstate* \
  outputs.json

# Upload to S3 (optional)
aws s3 cp sandbox-backup-*.tar.gz s3://sandbox-backup-bucket/
```

### S3 Backend Cleanup (If Using)

```bash
# Delete state files from S3
AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
BUCKET="sandbox-terraform-state-${AWS_ACCOUNT}"

# List versions
aws s3api list-object-versions --bucket "$BUCKET"

# Delete all versions
aws s3 rm "s3://${BUCKET}" --recursive

# Delete bucket
aws s3api delete-bucket --bucket "$BUCKET"

# Delete DynamoDB lock table
aws dynamodb delete-table --table-name terraform-locks

echo "Backend cleanup complete!"
```

---

## Support

For issues or questions:

1. **Check Logs**: View Terraform logs in `terraform.log`
2. **Review Outputs**: Check `terraform output` for deployment details
3. **AWS Console**: Verify resources in AWS Management Console
4. **Documentation**: Review module READMEs in `modules/` subdirectory
5. **Contact Team**: Reach cloud-ops@aon.com for assistance

---

**Document Version**: 1.0  
**Last Updated**: 2024-01-15  
**Maintained By**: Cloud Operations Team
