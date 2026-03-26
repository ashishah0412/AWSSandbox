# ============================================================================
# AWS Security Group Module - terraform-module-sbx-securitygroup
# ============================================================================
# Purpose: Create Security Groups for Sandbox resources
# Author: AON Sandbox Team
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
        Module      = "terraform-module-sbx-securitygroup"
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
# Security Group - Private Resources
# ============================================================================
resource "aws_security_group" "private_sg" {
  name_prefix = "${var.environment}-private-"
  description = "Security group for private resources in ${var.environment} sandbox"
  vpc_id      = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-private-sg"
      Type = "Private"
    }
  )

  # Allow ingress from within VPC
  ingress {
    description = "Allow TCP from VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  # Allow ingress from Specific IPs
  ingress {
    description = "Allow HTTP/HTTPS from Specific IPs"
    from_port   = 80
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.specific_ip_cidr]
  }

  # Allow all outbound traffic to VPC
  egress {
    description = "Allow TCP to VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  # Allow outbound HTTPS to specific IPs
  egress {
    description = "Allow HTTPS to Specific IPs"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.specific_ip_cidr]
  }

  # Allow outbound DNS
  egress {
    description = "Allow DNS to anywhere"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow outbound HTTPS to anywhere (for updates, patches)
  egress {
    description = "Allow HTTPS egress to internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# Security Group - Public Resources
# ============================================================================
resource "aws_security_group" "public_sg" {
  name_prefix = "${var.environment}-public-"
  description = "Security group for public resources in ${var.environment} sandbox"
  vpc_id      = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-public-sg"
      Type = "Public"
    }
  )

  # Allow ingress from VPC
  ingress {
    description = "Allow TCP from VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  # Allow ingress from specific IPs - HTTP
  ingress {
    description = "Allow HTTP from Specific IPs"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.specific_ip_cidr]
  }

  # Allow ingress from specific IPs - HTTPS
  ingress {
    description = "Allow HTTPS from Specific IPs"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.specific_ip_cidr]
  }

  # Allow egress to VPC
  egress {
    description = "Allow TCP to VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  # Allow egress to specific IPs
  egress {
    description = "Allow all to Specific IPs"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.specific_ip_cidr]
  }

  # Allow outbound DNS
  egress {
    description = "Allow DNS to anywhere"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow outbound HTTPS
  egress {
    description = "Allow HTTPS egress to internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# Security Group - Firewall
# ============================================================================
resource "aws_security_group" "firewall_sg" {
  name_prefix = "${var.environment}-firewall-"
  description = "Security group for firewall resources in ${var.environment} sandbox"
  vpc_id      = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-firewall-sg"
      Type = "Firewall"
    }
  )

  # Allow ingress from VPC
  ingress {
    description = "Allow TCP from VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  # Allow ingress from Firewall IPs
  ingress {
    description = "Allow high ports from Firewall IPs"
    from_port   = 1025
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.firewall_ip_cidr]
  }

  # Allow egress to VPC
  egress {
    description = "Allow TCP to VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  # Allow egress to Firewall IPs
  egress {
    description = "Allow all to Firewall IPs"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.firewall_ip_cidr]
  }

  # Allow outbound DNS
  egress {
    description = "Allow DNS to anywhere"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# Security Group - Database
# ============================================================================
resource "aws_security_group" "database_sg" {
  name_prefix = "${var.environment}-database-"
  description = "Security group for database resources in ${var.environment} sandbox"
  vpc_id      = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-database-sg"
      Type = "Database"
    }
  )

  # Allow MySQL/Aurora from Private subnet
  ingress {
    description = "Allow MySQL from Private subnet"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.private_subnet_cidr]
  }

  # Allow PostgreSQL from Private subnet
  ingress {
    description = "Allow PostgreSQL from Private subnet"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.private_subnet_cidr]
  }

  # Allow RDS listener
  ingress {
    description = "Allow RDS from VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  # Allow all outbound
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# Security Group - Management/Bastion
# ============================================================================
resource "aws_security_group" "management_sg" {
  name_prefix = "${var.environment}-management-"
  description = "Security group for management/bastion resources in ${var.environment} sandbox"
  vpc_id      = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-management-sg"
      Type = "Management"
    }
  )

  # Allow SSH from specific IPs
  ingress {
    description = "Allow SSH from Specific IPs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.specific_ip_cidr]
  }

  # Allow RDP from specific IPs
  ingress {
    description = "Allow RDP from Specific IPs"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = [var.specific_ip_cidr]
  }

  # Allow all traffic within VPC
  ingress {
    description = "Allow all from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr_block]
  }

  # Allow all outbound
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# Security Group Rules - Inter-SG Communication
# ============================================================================

# Allow Private SG to communicate with Database SG
resource "aws_security_group_rule" "private_to_database" {
  type                     = "egress"
  from_port                = 3306
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.private_sg.id
  source_security_group_id = aws_security_group.database_sg.id
  description              = "Allow Private to Database SG"
}

# Allow Public SG to communicate with Private SG
resource "aws_security_group_rule" "public_to_private" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.public_sg.id
  source_security_group_id = aws_security_group.private_sg.id
  description              = "Allow Public to Private SG"
}

# Allow Private SG from Public SG
resource "aws_security_group_rule" "private_from_public" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.private_sg.id
  source_security_group_id = aws_security_group.public_sg.id
  description              = "Allow Private from Public SG"
}
