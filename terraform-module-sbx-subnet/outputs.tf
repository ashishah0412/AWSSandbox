# ============================================================================
# Outputs - terraform-module-sbx-subnet
# Multi-AZ & Dynamic Subnets (v2.0)
# ============================================================================

# ============================================================================
# Private Subnet Outputs
# ============================================================================

output "private_subnet_ids" {
  description = "List of Private Subnet IDs"
  value       = aws_subnet.private_subnets[*].id
}

output "private_subnet_arns" {
  description = "List of Private Subnet ARNs"
  value       = aws_subnet.private_subnets[*].arn
}

output "private_subnet_cidrs" {
  description = "List of Private Subnet CIDR blocks"
  value       = aws_subnet.private_subnets[*].cidr_block
}

output "private_subnet_azs" {
  description = "List of Private Subnet Availability Zones"
  value       = aws_subnet.private_subnets[*].availability_zone
}

# ============================================================================
# Public Subnet Outputs
# ============================================================================

output "public_subnet_ids" {
  description = "List of Public Subnet IDs"
  value       = aws_subnet.public_subnets[*].id
}

output "public_subnet_arns" {
  description = "List of Public Subnet ARNs"
  value       = aws_subnet.public_subnets[*].arn
}

output "public_subnet_cidrs" {
  description = "List of Public Subnet CIDR blocks"
  value       = aws_subnet.public_subnets[*].cidr_block
}

output "public_subnet_azs" {
  description = "List of Public Subnet Availability Zones"
  value       = aws_subnet.public_subnets[*].availability_zone
}

# ============================================================================
# Firewall Subnet Outputs (Static - Always 1)
# ============================================================================

output "firewall_subnet_id" {
  description = "Firewall Subnet ID (static, always 1)"
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

output "firewall_subnet_az" {
  description = "Firewall Subnet Availability Zone"
  value       = aws_subnet.firewall_subnet.availability_zone
}

# ============================================================================
# Network ACL Outputs
# ============================================================================

output "private_nacl_ids" {
  description = "List of Private Subnet Network ACL IDs"
  value       = aws_network_acl.private_nacls[*].id
}

output "public_nacl_ids" {
  description = "List of Public Subnet Network ACL IDs"
  value       = aws_network_acl.public_nacls[*].id
}

output "firewall_nacl_id" {
  description = "Firewall Subnet Network ACL ID (static)"
  value       = aws_network_acl.firewall_nacl.id
}

# ============================================================================
# Route Table Outputs
# ============================================================================

output "private_route_table_ids" {
  description = "List of Private Route Table IDs"
  value       = aws_route_table.private_route_tables[*].id
}

output "public_route_table_ids" {
  description = "List of Public Route Table IDs"
  value       = aws_route_table.public_route_tables[*].id
}

output "firewall_route_table_id" {
  description = "Firewall Route Table ID (static)"
  value       = aws_route_table.firewall_route_table.id
}

# ============================================================================
# Summary & Composite Outputs
# ============================================================================

output "subnets_by_az" {
  description = "Subnets organized by Availability Zone"
  value = {
    for az in data.aws_availability_zones.available.names :
    az => {
      private_subnets = [
        for i, subnet in aws_subnet.private_subnets :
        {
          subnet_id  = subnet.id
          cidr_block = subnet.cidr_block
        }
        if subnet.availability_zone == az
      ]
      public_subnets = [
        for i, subnet in aws_subnet.public_subnets :
        {
          subnet_id  = subnet.id
          cidr_block = subnet.cidr_block
        }
        if subnet.availability_zone == az
      ]
    }
  }
}

output "subnet_count_summary" {
  description = "Summary of subnet counts and configuration"
  value = {
    num_availability_zones = var.num_availability_zones
    num_private_subnets    = var.num_private_subnets
    num_public_subnets     = var.num_public_subnets
    total_subnets          = (var.num_private_subnets + var.num_public_subnets + 1) # +1 for firewall
    private_subnets_count  = length(aws_subnet.private_subnets)
    public_subnets_count   = length(aws_subnet.public_subnets)
  }
}

output "all_subnet_ids" {
  description = "All Subnet IDs organized by type"
  value = {
    private_subnet_ids  = aws_subnet.private_subnets[*].id
    public_subnet_ids   = aws_subnet.public_subnets[*].id
    firewall_subnet_id  = aws_subnet.firewall_subnet.id
  }
}

output "all_route_table_ids" {
  description = "All Route Table IDs organized by type"
  value = {
    private_route_table_ids = aws_route_table.private_route_tables[*].id
    public_route_table_ids  = aws_route_table.public_route_tables[*].id
    firewall_route_table_id = aws_route_table.firewall_route_table.id
  }
}
