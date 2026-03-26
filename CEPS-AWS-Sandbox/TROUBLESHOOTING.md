# Troubleshooting Guide - AON AWS Sandbox

## Quick Diagnostics

### 1. Check Prerequisites

```bash
# Verify Terraform
terraform version
# Required: >= 1.0

# Verify AWS CLI
aws --version
# Required: >= 2.0

# Verify AWS Credentials
aws sts get-caller-identity
# Should return JSON with Account, UserId, Arn

# Verify Git
git version
# Required: >= 2.0
```

### 2. Enable Debug Logging

```bash
# Set debug level
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform-debug.log

# Run command
terraform plan

# View logs
tail -100 terraform-debug.log

# Disable debug (when done)
unset TF_LOG
unset TF_LOG_PATH
```

### 3. Validate Installation

```bash
# Check Terraform syntax
terraform validate

# Check module integrity
terraform mod init
terraform get -update

# Verify AWS provider
aws ec2 describe-regions
```

---

## Module-Specific Issues

### terraform-module-sbx-vpc

#### Issue: VPC CIDR Already Exists

**Error Message**:
```
Error: Error creating VPC: InvalidParameterValue
{
  Code: "InvalidVpcCIDR.AlreadyExists",
  Message: "The CIDR '10.10.0.0/16' conflicts with another VPC."
}
```

**Causes**:
- VPC with same CIDR already exists
- Previous deployment not cleaned up
- Manual VPC creation with same CIDR

**Solutions**:
```bash
# Check existing VPCs
aws ec2 describe-vpcs

# List all CIDRs in use
aws ec2 describe-vpcs --query 'Vpcs[*].[CidrBlock,Tags[?Key==`Name`]]'

# Option 1: Delete conflicting VPC
aws ec2 delete-vpc --vpc-id vpc-xxxxx

# Option 2: Change CIDR in terraform.tfvars
vpc_cidr_block = "10.20.0.0/16"  # Change from 10.10.0.0/16

# Re-deploy
terraform apply
```

#### Issue: VPC Endpoints Fail to Attach

**Error Message**:
```
Error: Error creating VPC Endpoint:
{
  Code: "DataSourceNotFound",
  Message: "The data source ID 'vpce-xxxxx' does not exist."
}
```

**Causes**:
- S3 or DynamoDB not available in region
- IAM permissions insufficient
- Service misconfiguration

**Solutions**:
```bash
# Verify service availability
aws ec2 describe-vpc-endpoint-services --service-names com.amazonaws.us-east-1.s3

# Check IAM permissions
aws iam get-role-policy --role-name VPCFlowLogsRole --policy-name VPCFlowLogs

# Enable both endpoints in terraform.tfvars
enable_s3_endpoint = true
enable_dynamodb_endpoint = true

# Re-deploy
terraform apply
```

### terraform-module-sbx-subnet

#### Issue: NACL Rules Not Applied

**Error Message**:
```
Error: Error creating NACL entry:
{
  Code: "NaclBufferLimit",
  Message: "Too many entries in NACL."
}
```

**Causes**:
- NACL has too many rules (max ~40)
- Rule numbering conflict
- Previous rules not cleaned up

**Solutions**:
```bash
# List current NACL rules
aws ec2 describe-network-acls \
  --filters "Name=association.subnet-id,Values=subnet-xxxxx"

# View specific NACL rules
aws ec2 describe-network-acls \
  --network-acl-ids acl-xxxxx \
  --query 'NetworkAcls[0].Entries'

# Option 1: Manual cleanup (if deploying fresh)
terraform destroy -target=module.subnets
terraform apply

# Option 2: Adjust NACL rule numbers to avoid conflicts
# Edit: terraform-module-sbx-subnet/main.tf
# Change rule numbers: 100, 200, 300... (leave gaps)

terraform plan
terraform apply
```

#### Issue: Subnet CIDR Block Conflicts

**Error Message**:
```
Error: Error creating Subnet:
{
  Code: "InvalidParameterValue",
  Message: "The CIDR 10.10.1.0/24 overlaps with another subnet."
}
```

**Causes**:
- Subnet CIDR overlaps with existing subnet
- Manual subnet creation with overlapping CIDR
- VPC CIDR changed mid-deployment

**Solutions**:
```bash
# Check existing subnets in VPC
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-xxxxx"

# Change subnet CIDRs in terraform.tfvars to non-overlapping
# Original:
private_subnet_cidr   = "10.10.1.0/24"
public_subnet_cidr    = "10.10.2.0/24"
firewall_subnet_cidr  = "10.10.5.0/24"

# Alternative (if conflict):
private_subnet_cidr   = "10.10.10.0/24"
public_subnet_cidr    = "10.10.20.0/24"
firewall_subnet_cidr  = "10.10.30.0/24"

terraform plan
terraform apply
```

### terraform-module-sbx-securitygroup

#### Issue: Security Group Rules Reference Non-Existent Group

**Error Message**:
```
Error: Error creating Security Group ingress rule:
{
  Code: "InvalidGroup.NotFound",
  Message: "The security group 'sg-xxxxx' does not exist."
}
```

**Causes**:
- Referenced security group not created
- Module dependency issue
- Security group deleted externally

**Solutions**:
```bash
# Verify all security groups exist
aws ec2 describe-security-groups \
  --filters "Name=vpc-id,Values=vpc-xxxxx"

# Check module dependencies in main.tf
terraform graph | grep security_groups

# Redeploy security groups module
terraform destroy -target=module.security_groups
terraform apply

# Or redeploy entire stack
terraform destroy
terraform apply
```

#### Issue: Port/Protocol Invalid in Security Group Rule

**Error Message**:
```
Error: Error authorizing security group ingress:
{
  Code: "InvalidParameterValue",
  Message: "Invalid protocol: tcp (Supported: tcp, udp, icmp, icmpv6, -1)"
}
```

**Causes**:
- Invalid protocol specification
- Port number out of range (0-65535)
- Typo in protocol name

**Solutions**:
```bash
# Check valid protocols
# Valid: tcp, udp, icmp, icmpv6, -1 (all)
# Invalid: TCP, TCP/IP, all

# Check module configuration
terraform show | grep -A 3 "security_group_rule"

# Fix in: terraform-module-sbx-securitygroup/main.tf
# Example: Change "TCP" to "tcp"

# Verify port range
# Valid: 0-65535
# If specifying range: from_port=80, to_port=443
# Not: port=80

terraform apply
```

### terraform-module-sbx-firewall

#### Issue: Network Firewall Not Available in Region

**Error Message**:
```
Error: Error creating Network Firewall:
{
  Code: "InvalidAction",
  Message: "The service is not available in the selected region."
}
```

**Causes**:
- Region doesn't support AWS Network Firewall
- Feature not enabled in region
- Account limitation

**Solutions**:
```bash
# Supported regions (as of 2024)
# - us-east-1, us-east-1, us-west-1, us-west-2
# - eu-west-1, eu-central-1
# - ap-southeast-1, ap-northeast-1, ap-southeast-2
# - ca-central-1

# Check current region
aws configure get region

# Change region in terraform.tfvars
aws_region = "us-east-1"  # Change from us-east-1

# Verify service available in new region
aws network-firewall describe-resource-policy --region us-east-1

terraform init
terraform apply
```

#### Issue: CloudWatch Log Groups Conflict

**Error Message**:
```
Error: Error creating CloudWatch Log Group:
{
  Code: "ResourceAlreadyExistsException",
  Message: "The specified log group already exists."
}
```

**Causes**:
- Log group from previous deployment exists
- Manual creation of conflicting log group
- Cross-deployment name collision

**Solutions**:
```bash
# List existing log groups
aws logs describe-log-groups | grep Sandbox

# Delete conflicting log group
aws logs delete-log-group --log-group-name /aws/network-firewall/Sandbox/alerts
aws logs delete-log-group --log-group-name /aws/network-firewall/Sandbox/flows

# Re-deploy firewall module
terraform apply -target=module.firewall

# Or destroy and redeploy entire stack
terraform destroy
terraform apply
```

#### Issue: Firewall Rules Exceed Capacity

**Error Message**:
```
Error: Error creating Rule Group:
{
  Code: "LimitExceededException",
  Message: "Capacity units exceeded."
}
```

**Causes**:
- Too many rules defined
- Stateless/stateful rule group capacity exceeded
- Rule complexity too high

**Solutions**:
```bash
# Current capacity in terraform.tfvars
stateless_rule_group_capacity = 100   # Min: 10, Max: 32000
stateful_rule_group_capacity = 1000   # Min: 10, Max: 1000000

# Increase capacity for more rules
stateless_rule_group_capacity = 500   # Increase if needed
stateful_rule_group_capacity = 5000   # Increase if needed

# Or simplify rules by:
# - Combining similar rules
# - Using CIDR blocks instead of individual IPs
# - Using domain lists for blocked domains

terraform apply
```

### terraform-module-sbx-rbac

#### Issue: IAM Role Assume Policy Invalid

**Error Message**:
```
Error: Error creating IAM role:
{
  Code: "InvalidParameterValue",
  Message: "Invalid principal in AssumeRolePolicyDocument."
}
```

**Causes**:
- Incorrect principal ARN format
- Principal service not valid
- JSON syntax error in policy

**Solutions**:
```bash
# Valid service principals
# - ec2.amazonaws.com
# - lambda.amazonaws.com
# - rds.amazonaws.com
# - budgets.amazonaws.com
# - events.amazonaws.com

# Check module policy document
terraform show | grep -A 10 'assume_role_policy'

# Fix in: terraform-module-sbx-rbac/main.tf
# Example:
# "Principal": {
#   "Service": "ec2.amazonaws.com"
# }

terraform apply
```

#### Issue: IAM Policy Limit Exceeded

**Error Message**:
```
Error: Error creating IAM group policy:
{
  Code: "LimitExceeded",
  Message: "Policy document is too large."
}
```

**Causes**:
- IAM policy too large (>10KB limit)
- Too many permissions in single policy
- Repeated permissions not consolidated

**Solutions**:
```bash
# Check policy size
aws iam get-group-policy \
  --group-name sandbox-developers \
  --policy-name DeveloperPolicy \
  --query 'GroupPolicy.PolicyDocument' | wc -c

# If > 10240 bytes, need to split policies

# Option 1: Create multiple policies
developer_policy_1 = "..." # EC2, RDS permissions
developer_policy_2 = "..." # S3, Lambda permissions

# Option 2: Use AWS managed policies
AWS managed: PowerUserAccess, ReadOnlyAccess

# Attach multiple policies to group
aws iam attach-group-policy \
  --group-name sandbox-developers \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess

terraform apply
```

### terraform-module-sbx-automation

#### Issue: Lambda Function Deployment Fails

**Error Message**:
```
Error: Error creating Lambda function:
{
  Code: "InvalidParameterValueException",
  Message: "An error occurred (InvalidParameterValueException) when calling the CreateFunction operation: Could not locate deployment package."
}
```

**Causes**:
- Lambda deployment package not found
- Incorrect file path
- ZIP file corrupted

**Solutions**:
```bash
# Verify Lambda package exists
ls -la modules/terraform-module-sbx-automation/resource_shutdown.zip

# If missing, recreate ZIP
cd modules/terraform-module-sbx-automation/
zip resource_shutdown.zip lambda_handler.py
cd -

# Verify ZIP integrity
unzip -t modules/terraform-module-sbx-automation/resource_shutdown.zip

terraform apply
```

#### Issue: SNS Topic Already Exists

**Error Message**:
```
Error: Error creating SNS Topic:
{
  Code: "TopicAlreadyExists",
  Message: "Topic already exists."
}
```

**Causes**:
- Previous deployment created topic
- Manual SNS topic creation with same name
- Topic not deleted from previous execution

**Solutions**:
```bash
# List existing SNS topics
aws sns list-topics

# Delete conflicting topic
aws sns delete-topic --topic-arn arn:aws:sns:us-east-1:ACCOUNT:Sandbox-budget-alerts

# Or rename in terraform.tfvars (change topic name)

# Re-deploy automation module
terraform apply -target=module.automation
```

#### Issue: Budget Limit Invalid

**Error Message**:
```
Error: Error creating Budget:
{
  Code: "InvalidParameterValue",
  Message: "Budget limit amount must be greater than 0."
}
```

**Causes**:
- Budget limit set to 0 or negative
- Budget limit not a valid number
- Currency not specified

**Solutions**:
```bash
# Check terraform.tfvars
quarterly_budget_limit = 1000  # Must be > 0
budget_limit_unit = "USD"      # Must be specified

# Ensure valid format
quarterly_budget_limit = 1000.00  # Decimal valid
quarterly_budget_limit = 1000     # Integer valid
quarterly_budget_limit = -500     # Invalid!
quarterly_budget_limit = 0        # Invalid!

terraform apply
```

#### Issue: CloudWatch Alarm Threshold Invalid

**Error Message**:
```
Error: Error creating CloudWatch Alarm:
{
  Code: "InvalidParameterValue",
  Message: "Invalid alarm threshold."
}
```

**Causes**:
- Threshold not a valid number
- Threshold exceeds metric limits
- Threshold not numeric

**Solutions**:
```bash
# Check alarm setup in main.tf
# Thresholds should be:
# - 70% of budget: 700 (if budget = 1000)
# - 85% of budget: 850
# - 95% of budget: 950

# Verify calculation
budget_limit = 1000
threshold_70 = budget_limit * 0.70  # = 700
threshold_85 = budget_limit * 0.85  # = 850
threshold_95 = budget_limit * 0.95  # = 950

terraform apply
```

---

## Common Terraform Errors

### State-Related Issues

#### Error: State Lock Timeout

**Error Message**:
```
Error: Error acquiring the state lock:
{
  Code: "ConditionalCheckFailedException",
  Message: "The conditional request failed."
}
```

**Causes**:
- Another process modifying state
- DynamoDB connection issue
- Stale lock

**Solutions**:
```bash
# Check lock status
aws dynamodb scan --table-name terraform-locks

# Force unlock (use with caution!)
terraform force-unlock LOCK_ID

# Or delete lock file
rm -f .terraform.tfstate.lock.hcl

# Refresh state
terraform refresh

# Retry operation
terraform apply
```

#### Error: State File Corruption

**Error Message**:
```
Error: Failed to read state file:
{
  Code: "InvalidParameterValueException",
  Message: "Invalid state file format."
}
```

**Causes**:
- State file corrupted
- Manual edit of .tfstate
- Version mismatch

**Solutions**:
```bash
# Restore from backup
cp terraform.tfstate.backup terraform.tfstate

# Or recover from version control
git checkout terraform.tfstate

# Or from S3 backend
aws s3 cp s3://sandbox-terraform-state/terraform.tfstate ./

# Verify state
terraform validate

# Refresh
terraform refresh
```

### Module-Resolution Issues

#### Error: Module Source Invalid

**Error Message**:
```
Error: Failed to download module:
{
  Code: "ModuleSourceNotFound",
  Message: "Could not find module source."
}
```

**Causes**:
- Module directory doesn't exist
- Git repository not accessible
- Relative path incorrect

**Solutions**:
```bash
# Verify module structure
find . -name "main.tf" | grep modules

# Ensure all modules present
ls modules/
# Should show 6 directories

# Verify paths in main.tf
grep "source.*=" main.tf

# Update modules
terraform get -update

# Reinitialize
terraform init -upgrade
```

---

## AWS Service-Specific Issues

### EC2 Related

#### Error: Insufficient Capacity

**Error Message**:
```
Error: InsufficientCapacityInAZ
{
  Code: "InsufficientCapacityInAZ",
  Message: "The requested instance type is not available."
}
```

**Solutions**:
```bash
# Try different AZ
# Or try different instance type
# Or change region

aws_region = "us-west-2"

terraform apply
```

### RDS Related

#### Error: Database Already Exists

**Error Message**:
```
Error: creating DB Instance:
{
  Code: "DBInstanceAlreadyExists",
  Message: "The database already exists."
}
```

**Solutions**:
```bash
# Check existing databases
aws rds describe-db-instances

# Delete conflicting database
aws rds delete-db-instance \
  --db-instance-identifier sandbox-mysql \
  --skip-final-snapshot

# Or rename in Terraform
db_instance_identifier = "sandbox-mysql-new"

terraform apply
```

### IAM Related

#### Error: User Not Authorized

**Error Message**:
```
Error: Operation not authorized:
{
  Code: "AccessDenied",
  Message: "User is not authorized to perform this action."
}
```

**Solutions**:
```bash
# Verify user permissions
aws iam list-user-policies --user-name your-user

# Attach required policy
aws iam attach-user-policy \
  --user-name your-user \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# Or create custom policy with required permissions

terraform apply
```

### Networking Related

#### Error: VPC Limit Exceeded

**Error Message**:
```
Error: Error creating VPC:
{
  Code: "VpcLimitExceeded",
  Message: "The maximum number of VPCs has been exceeded."
}
```

**Solutions**:
```bash
# Default limit: 5 VPCs per region
# Request limit increase

# Or use existing VPC
vpc_id = "vpc-xxxxxxxx"  # Specify existing VPC

# Or delete unused VPCs
aws ec2 delete-vpc --vpc-id vpc-xxxxx

terraform apply
```

---

## Debug Workflow

### Step-by-Step Debugging Process

```
1. Identify Error
   ├─ Read error message carefully
   ├─ Note error code and service
   └─ Check if known issue in this guide

2. Collect Information
   ├─ terraform.log (if TF_LOG enabled)
   ├─ AWS CloudTrail logs
   ├─ terraform show (current state)
   └─ terraform plan (what would change)

3. Isolate Problem
   ├─ Test single module: terraform apply -target=module.xxx
   ├─ Verify prerequisites: aws sts get-caller-identity
   ├─ Check resource state: aws ec2 describe-vpcs
   └─ Review IAM permissions: aws iam get-user

4. Implement Fix
   ├─ Modify terraform.tfvars
   ├─ Update main.tf if necessary
   ├─ Test with terraform plan
   └─ Apply with terraform apply

5. Verify Resolution
   ├─ Check terraform output
   ├─ Verify AWS resources exist
   ├─ Confirm no additional errors
   └─ Document solution

6. Prevent Recurrence
   ├─ Update documentation
   ├─ Add validation to module
   ├─ Create runbook for team
   └─ Add to troubleshooting guide
```

### Getting Help

```
Level 1 - Self Service
- Consult this troubleshooting guide
- Review module READMEs
- Check terraform.log
- Search Terraform Registry

Level 2 - Team
- Slack: #cloud-ops
- Email: cloud-ops@aon.com
- GitHub Issues: (repo)/issues

Level 3 - Escalation
- AWS Support: (if applicable)
- Terraform Enterprise support
- HashiCorp consulting
```

---

**Last Updated**: 2024-01-15  
**Document Version**: 1.0  
**Maintained By**: Cloud Operations Team
