# ============================================================================
# Terraform Values - terraform-module-sbx-vpc
# ============================================================================

aws_region          = "us-east-1"
environment         = "Sandbox"
vpc_cidr_block      = "10.10.0.0/16"
enable_dns_hostnames = true
enable_dns_support   = true
enable_s3_endpoint   = true
enable_dynamodb_endpoint = true
vpc_flow_logs_retention_days = 30

common_tags = {
  Project     = "AWS-AWS-Sandbox"
  CostCenter  = "Engineering"
  Owner       = "CloudOps"
  CreatedBy   = "Terraform"
}
