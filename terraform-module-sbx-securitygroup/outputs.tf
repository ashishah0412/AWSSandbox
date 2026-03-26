# ============================================================================
# Outputs - terraform-module-sbx-securitygroup
# ============================================================================

output "private_sg_id" {
  description = "Private Security Group ID"
  value       = aws_security_group.private_sg.id
}

output "private_sg_arn" {
  description = "Private Security Group ARN"
  value       = aws_security_group.private_sg.arn
}

output "public_sg_id" {
  description = "Public Security Group ID"
  value       = aws_security_group.public_sg.id
}

output "public_sg_arn" {
  description = "Public Security Group ARN"
  value       = aws_security_group.public_sg.arn
}

output "firewall_sg_id" {
  description = "Firewall Security Group ID"
  value       = aws_security_group.firewall_sg.id
}

output "firewall_sg_arn" {
  description = "Firewall Security Group ARN"
  value       = aws_security_group.firewall_sg.arn
}

output "database_sg_id" {
  description = "Database Security Group ID"
  value       = aws_security_group.database_sg.id
}

output "database_sg_arn" {
  description = "Database Security Group ARN"
  value       = aws_security_group.database_sg.arn
}

output "management_sg_id" {
  description = "Management/Bastion Security Group ID"
  value       = aws_security_group.management_sg.id
}

output "management_sg_arn" {
  description = "Management/Bastion Security Group ARN"
  value       = aws_security_group.management_sg.arn
}

output "all_security_groups" {
  description = "Map of all security groups"
  value = {
    private_sg_id      = aws_security_group.private_sg.id
    public_sg_id       = aws_security_group.public_sg.id
    firewall_sg_id     = aws_security_group.firewall_sg.id
    database_sg_id     = aws_security_group.database_sg.id
    management_sg_id   = aws_security_group.management_sg.id
  }
}
