# ============================================================================
# Outputs - terraform-module-sbx-vpc
# ============================================================================

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.sandbox_vpc.id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value       = aws_vpc.sandbox_vpc.cidr_block
}

output "vpc_arn" {
  description = "VPC ARN"
  value       = aws_vpc.sandbox_vpc.arn
}

output "s3_endpoint_id" {
  description = "S3 Gateway VPC Endpoint ID"
  value       = try(aws_vpc_endpoint.s3_gateway[0].id, null)
}

output "s3_endpoint_arn" {
  description = "S3 Gateway VPC Endpoint ARN"
  value       = try(aws_vpc_endpoint.s3_gateway[0].arn, null)
}

output "dynamodb_endpoint_id" {
  description = "DynamoDB Gateway VPC Endpoint ID"
  value       = try(aws_vpc_endpoint.dynamodb_gateway[0].id, null)
}

output "dynamodb_endpoint_arn" {
  description = "DynamoDB Gateway VPC Endpoint ARN"
  value       = try(aws_vpc_endpoint.dynamodb_gateway[0].arn, null)
}

output "flow_log_group_name" {
  description = "CloudWatch Log Group name for VPC Flow Logs"
  value       = aws_cloudwatch_log_group.vpc_flow_logs_group.name
}

output "flow_log_group_arn" {
  description = "CloudWatch Log Group ARN for VPC Flow Logs"
  value       = aws_cloudwatch_log_group.vpc_flow_logs_group.arn
}

output "availability_zones" {
  description = "Available zones in the region"
  value       = local.availability_zones
}

output "account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}
