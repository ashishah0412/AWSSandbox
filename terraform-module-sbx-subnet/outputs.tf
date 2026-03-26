# ============================================================================
# Outputs - terraform-module-sbx-subnet
# ============================================================================

output "private_subnet_id" {
  description = "Private Subnet ID"
  value       = aws_subnet.private_subnet.id
}

output "private_subnet_arn" {
  description = "Private Subnet ARN"
  value       = aws_subnet.private_subnet.arn
}

output "private_subnet_cidr" {
  description = "Private Subnet CIDR block"
  value       = aws_subnet.private_subnet.cidr_block
}

output "public_subnet_id" {
  description = "Public Subnet ID"
  value       = aws_subnet.public_subnet.id
}

output "public_subnet_arn" {
  description = "Public Subnet ARN"
  value       = aws_subnet.public_subnet.arn
}

output "public_subnet_cidr" {
  description = "Public Subnet CIDR block"
  value       = aws_subnet.public_subnet.cidr_block
}

output "firewall_subnet_id" {
  description = "Firewall Subnet ID"
  value       = aws_subnet.firewall_subnet.id
}

output "firewall_subnet_arn" {
  description = "Firewall Subnet ARN"
  value       = aws_subnet.firewall_subnet.arn
}

output "firewall_subnet_cidr" {
  description = "Firewall Subnet CIDR block"
  value       = aws_subnet.firewall_subnet.cidr_block
}

output "private_nacl_id" {
  description = "Private Subnet Network ACL ID"
  value       = aws_network_acl.private_nacl.id
}

output "public_nacl_id" {
  description = "Public Subnet Network ACL ID"
  value       = aws_network_acl.public_nacl.id
}

output "firewall_nacl_id" {
  description = "Firewall Subnet Network ACL ID"
  value       = aws_network_acl.firewall_nacl.id
}

output "private_route_table_id" {
  description = "Private Route Table ID"
  value       = aws_route_table.private_route_table.id
}

output "public_route_table_id" {
  description = "Public Route Table ID"
  value       = aws_route_table.public_route_table.id
}

output "firewall_route_table_id" {
  description = "Firewall Route Table ID"
  value       = aws_route_table.firewall_route_table.id
}

output "all_subnet_ids" {
  description = "All Subnet IDs (Private, Public, Firewall)"
  value = {
    private_subnet_id   = aws_subnet.private_subnet.id
    public_subnet_id    = aws_subnet.public_subnet.id
    firewall_subnet_id  = aws_subnet.firewall_subnet.id
  }
}

output "all_route_table_ids" {
  description = "All Route Table IDs"
  value = {
    private_rt_id   = aws_route_table.private_route_table.id
    public_rt_id    = aws_route_table.public_route_table.id
    firewall_rt_id  = aws_route_table.firewall_route_table.id
  }
}
