# ============================================================================
# AWS Subnet Module - terraform-module-sbx-subnet
# ============================================================================
# Purpose: Create dynamic multi-AZ subnets (Private, Public, Firewall) with NACL rules
# Author: AWS Sandbox Team
# Version: 2.0.0 (Dynamic Multi-AZ)
# ============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(
      var.common_tags,
      {
        Module      = "terraform-module-sbx-subnet"
        Environment = var.environment
        ManagedBy   = "Terraform"
      }
    )
  }
}

# ============================================================================
# Data Sources
# ============================================================================
data "aws_vpc" "sandbox_vpc" {
  id = var.vpc_id
}

# ============================================================================
# Locals - Availability Zones Configuration
# ============================================================================
# Regional AZ defaults (for when user doesn't specify availability_zones)
# This avoids requiring ec2:DescribeAvailabilityZones IAM permission
locals {
  azs_by_region = {
    "us-east-1"      = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d"]
    "us-east-2"      = ["us-east-2a", "us-east-2b", "us-east-2c"]
    "us-west-1"      = ["us-west-1a", "us-west-1b", "us-west-1c"]
    "us-west-2"      = ["us-west-2a", "us-west-2b", "us-west-2c", "us-west-2d"]
    "eu-west-1"      = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
    "eu-central-1"   = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
    "ap-southeast-1" = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
    "ap-northeast-1" = ["ap-northeast-1a", "ap-northeast-1b", "ap-northeast-1c", "ap-northeast-1d"]
    "ca-central-1"   = ["ca-central-1a", "ca-central-1b", "ca-central-1d"]
    "ap-south-1"     = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
  }
  
  # Use provided AZs if specified, otherwise use regional defaults
  availability_zones = length(var.availability_zones) > 0 ? var.availability_zones : try(local.azs_by_region[var.aws_region], ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"])
}

# ============================================================================
# Private Subnets - Dynamic (using count)
# ============================================================================
resource "aws_subnet" "private_subnets" {
  count = var.num_private_subnets

  vpc_id                  = var.vpc_id
  cidr_block              = var.private_subnet_cidr_blocks[count.index]
  availability_zone       = local.availability_zones[count.index % var.num_availability_zones]
  map_public_ip_on_launch = false

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-private-subnet-${count.index + 1}"
      Type = "Private"
      AZ   = local.availability_zones[count.index % var.num_availability_zones]
    }
  )
}

# ============================================================================
# Public Subnets - Dynamic (using count)
# ============================================================================
resource "aws_subnet" "public_subnets" {
  count = var.num_public_subnets

  vpc_id                  = var.vpc_id
  cidr_block              = var.public_subnet_cidr_blocks[count.index]
  availability_zone       = local.availability_zones[count.index % var.num_availability_zones]
  map_public_ip_on_launch = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-public-subnet-${count.index + 1}"
      Type = "Public"
      AZ   = local.availability_zones[count.index % var.num_availability_zones]
    }
  )
}

# ============================================================================
# Firewall Subnet - Static (permanent, always 1)
# ============================================================================
resource "aws_subnet" "firewall_subnet" {
  vpc_id                  = var.vpc_id
  cidr_block              = var.firewall_subnet_cidr
  availability_zone       = local.availability_zones[0]
  map_public_ip_on_launch = false

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-firewall-subnet"
      Type = "Firewall"
      AZ   = local.availability_zones[0]
    }
  )
}

# ============================================================================
# Network ACLs - Private (one per private subnet)
# ============================================================================
resource "aws_network_acl" "private_nacls" {
  count = var.num_private_subnets

  vpc_id     = var.vpc_id
  subnet_ids = [aws_subnet.private_subnets[count.index].id]

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-private-nacl-${count.index + 1}"
    }
  )

  # Inbound Rules - Private Subnet
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.10.0.0/16"
    from_port  = 0
    to_port    = 65535
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = var.specific_ip_cidr
    from_port  = 1025
    to_port    = 65535
  }

  ingress {
    protocol   = "-1"
    rule_no    = 32766
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  # Outbound Rules - Private Subnet
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.10.0.0/16"
    from_port  = 0
    to_port    = 65535
  }

  egress {
    protocol   = "udp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 53
    to_port    = 53
  }

  egress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  egress {
    protocol   = "-1"
    rule_no    = 32766
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}

# ============================================================================
# Network ACLs - Public (one per public subnet)
# ============================================================================
resource "aws_network_acl" "public_nacls" {
  count = var.num_public_subnets

  vpc_id     = var.vpc_id
  subnet_ids = [aws_subnet.public_subnets[count.index].id]

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-public-nacl-${count.index + 1}"
    }
  )

  # Inbound Rules - Public Subnet
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.10.0.0/16"
    from_port  = 0
    to_port    = 65535
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = var.specific_ip_cidr
    from_port  = 80
    to_port    = 443
  }

  ingress {
    protocol   = "-1"
    rule_no    = 32766
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  # Outbound Rules - Public Subnet
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.10.0.0/16"
    from_port  = 0
    to_port    = 65535
  }

  egress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = var.specific_ip_cidr
    from_port  = 1025
    to_port    = 65535
  }

  egress {
    protocol   = "-1"
    rule_no    = 32766
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}

# ============================================================================
# Network ACL - Firewall (static)
# ============================================================================
resource "aws_network_acl" "firewall_nacl" {
  vpc_id     = var.vpc_id
  subnet_ids = [aws_subnet.firewall_subnet.id]

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-firewall-nacl"
    }
  )

  # Inbound Rules - Firewall Subnet
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.10.0.0/16"
    from_port  = 0
    to_port    = 65535
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = var.firewall_ip_cidr
    from_port  = 1025
    to_port    = 65535
  }

  ingress {
    protocol   = "-1"
    rule_no    = 32766
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  # Outbound Rules - Firewall Subnet
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.10.0.0/16"
    from_port  = 0
    to_port    = 65535
  }

  egress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = var.firewall_ip_cidr
    from_port  = 0
    to_port    = 65535
  }

  egress {
    protocol   = "-1"
    rule_no    = 32766
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}

# ============================================================================
# Route Tables - Private (one per private subnet)
# ============================================================================
resource "aws_route_table" "private_route_tables" {
  count = var.num_private_subnets

  vpc_id = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-private-rt-${count.index + 1}"
      Type = "Private"
    }
  )
}

resource "aws_route_table_association" "private_associations" {
  count = var.num_private_subnets

  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_route_tables[count.index].id
}

# ============================================================================
# Route Tables - Public (one per public subnet)
# ============================================================================
resource "aws_route_table" "public_route_tables" {
  count = var.num_public_subnets

  vpc_id = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-public-rt-${count.index + 1}"
      Type = "Public"
    }
  )
}

resource "aws_route_table_association" "public_associations" {
  count = var.num_public_subnets

  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_route_tables[count.index].id
}

# ============================================================================
# Route Table - Firewall (static)
# ============================================================================

resource "aws_route_table" "firewall_route_table" {
  vpc_id = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-firewall-rt"
      Type = "Firewall"
    }
  )
}

resource "aws_route_table_association" "firewall_association" {
  subnet_id      = aws_subnet.firewall_subnet.id
  route_table_id = aws_route_table.firewall_route_table.id
}
