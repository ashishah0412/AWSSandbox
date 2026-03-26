# ============================================================================
# AWS Subnet Module - terraform-module-sbx-subnet
# ============================================================================
# Purpose: Create subnets (Private, Public, Firewall) with NACL rules
# Author: AWS Sandbox Team
# Version: 1.0.0
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

data "aws_availability_zones" "available" {
  state = "available"
}

# ============================================================================
# Private Subnet
# ============================================================================
resource "aws_subnet" "private_subnet" {
  vpc_id                          = var.vpc_id
  cidr_block                      = var.private_subnet_cidr
  availability_zone              = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch         = false

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-private-subnet"
      Type = "Private"
    }
  )
}

# ============================================================================
# Public Subnet
# ============================================================================
resource "aws_subnet" "public_subnet" {
  vpc_id                  = var.vpc_id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-public-subnet"
      Type = "Public"
    }
  )
}

# ============================================================================
# Firewall Subnet
# ============================================================================
resource "aws_subnet" "firewall_subnet" {
  vpc_id                  = var.vpc_id
  cidr_block              = var.firewall_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-firewall-subnet"
      Type = "Firewall"
    }
  )
}

# ============================================================================
# Network ACL - SandboxPrivate
# ============================================================================
resource "aws_network_acl" "private_nacl" {
  vpc_id     = var.vpc_id
  subnet_ids = [aws_subnet.private_subnet.id]

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-private-nacl"
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
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = var.specific_ip_cidr
    from_port  = 80
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
# Network ACL - SandboxPublic
# ============================================================================
resource "aws_network_acl" "public_nacl" {
  vpc_id     = var.vpc_id
  subnet_ids = [aws_subnet.public_subnet.id]

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-public-nacl"
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
# Network ACL - SandboxFirewall
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
# Route Tables
# ============================================================================
resource "aws_route_table" "private_route_table" {
  vpc_id = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-private-rt"
    }
  )
}

resource "aws_route_table" "public_route_table" {
  vpc_id = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-public-rt"
    }
  )
}

resource "aws_route_table" "firewall_route_table" {
  vpc_id = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-firewall-rt"
    }
  )
}

# ============================================================================
# Route Table Associations
# ============================================================================
resource "aws_route_table_association" "private_subnet_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "firewall_subnet_association" {
  subnet_id      = aws_subnet.firewall_subnet.id
  route_table_id = aws_route_table.firewall_route_table.id
}
