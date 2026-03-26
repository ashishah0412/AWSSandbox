# AWS Sandbox Infrastructure Automation - Project Summary

## Project Overview
A comprehensive Azure DevOps-driven automation solution to provision and manage AWS Sandbox environments using Terraform, with intelligent cost control and network security measures.

---

## Architecture & Repository Structure

### Terraform Module Repositories
Each AWS component exists as an independent module in its own Azure DevOps repository:

| Repository | Purpose |
|---|---|
| **terraform-module-sbx-vpc** | VPC creation and core network setup |
| **terraform-module-sbx-subnet** | Subnet creation and management |
| **terraform-module-sbx-securitygroup** | Security Group configuration |
| **terraform-module-sbx-firewall** | Network Firewall deployment |
| **terraform-module-sbx-rbac** | IAM roles, policies, and RBAC configuration |
| **terraform-module-sbx-automation** | Cost budget, alerts, and automation controls |

### Master Orchestration Repository
- **Repository Name**: CEPS-AWS-Sandbox
- **Purpose**: Central repository that orchestrates all above modules
- **Default Region**: US-East-1 (with option to select other regions)
- **Deployment Method**: Azure DevOps Pipeline

---

## Core Requirements

### 1. Terraform Sandbox Provisioning

**Initial Network Configuration:**
- **3 Subnets to Create**:
  1. Private Subnet (SandboxPrivate)
  2. Public Subnet (SandboxPublic)
  3. Firewall Subnet (SandboxFirewall)

**Flexibility Features:**
- Capability to add/modify subnets post-deployment
- Region selection with US-East-1 as default

### 2. VPC Endpoint Enablement
- Enable VPC endpoints based on user input
- Support for flexible VPC Endpoint configuration

### 3. Network Firewall Deployment
- Deploy AWS Network Firewall in the Sandbox Account
- Monitor north-south traffic (ingress/egress)
- Monitor internal subnet-to-subnet traffic

---

## Cost Management & Automation Module
**Repository**: terraform-module-sbx-automation

### Design Principles

**A. Quarterly Budget Period**
- Budget reset every quarter
- Tag-based budget tracking (e.g., `environment=Sandbox`, `application=XYZ`)
- **Quarterly Budget Limit**: $1,000 USD

**B. Multi-Tier Alert System with SNS Notification**
- **Notification Recipient**: ashishah0412@gmail.com (via SNS)
- **Alert Escalation**:

| Threshold | Notification Channel | Action | Stakeholder |
|---|---|---|---|
| **70%** ($700) | Email via SNS | Notify user group (1st alert) | User Groups |
| **85%** ($850) | Email via SNS | Notify user group (2nd alert) | User Groups |
| **95%** ($950) | Email via SNS, EventBridge, Lambda, SSM | Stop applicable resources; Freeze resource creation via SCPs; Notify users, admins, management | User Groups, Admins, Management |

**C. Alert-Based Actions**
- Stop applicable resources (e.g., EC2, RDS instances)
- Freeze resource creation using Service Control Policies (SCPs)
- Escalation path: User notification → Admin → Management action

**D. Integration Components**
- AWS Budgets (budget definition and tracking)
- EventBridge (event orchestration at 95% threshold)
- Lambda (resource stop automation)
- Service Control Policies (SCP) - resource creation freeze
- SSM Automation (automated remediation)
- SNS Topics (email and SMS distribution)

**E. Tag-Based Filtering**
- Budget alerts filtered using tags: `environment=Sandbox` and `application=XYZ`
- Granular cost tracking per application within sandbox

**F. VPC Endpoints Configuration**
- **S3 Gateway Endpoint**: For secure S3 access without traversing the internet
- **DynamoDB Gateway Endpoint**: For serverless database access within VPC
- Both endpoints reduce data transfer costs and improve security posture

---

## Network Access Control Rules

### Security Architecture
NACL rules are applied to the three subnets to enforce:
- Default DENY policy (whitelist-only approach)
- Internal VPC communication allowed (10.10.0.0/16)
- Controlled external access from specific IPs

### NACL Rules - SandboxPrivate Subnet

**Inbound Rules:**
| Rule # | Type | Protocol | Port Range | Source | Action |
|---|---|---|---|---|---|
| 100 | All Traffic | TCP | All | 10.10.0.0/16 | Allow |
| 200 | HTTPS | TCP | 1025-65535 | 203.0.113.0/24 | Allow |
| * | All Traffic | All | All | 0.0.0.0/0 | Deny |

**Outbound Rules:**
| Rule # | Type | Protocol | Port Range | Destination | Action |
|---|---|---|---|---|---|
| 100 | All Traffic | TCP | All | 10.10.0.0/16 | Allow |
| 200 | HTTPS | TCP | 80, 443 | 203.0.113.0/24 | Allow |
| * | All Traffic | All | All | 0.0.0.0/0 | Deny |

---

### NACL Rules - SandboxFirewall Subnet

**Inbound Rules:**
| Rule # | Type | Protocol | Port Range | Source | Action |
|---|---|---|---|---|---|
| 100 | All Traffic | TCP | All | 10.10.0.0/16 | Allow |
| 200 | All Traffic | TCP | 1025-65535 | 10.10.5.0/24 | Allow |
| * | All Traffic | All | All | 0.0.0.0/0 | Deny |

**Outbound Rules:**
| Rule # | Type | Protocol | Port Range | Destination | Action |
|---|---|---|---|---|---|
| 100 | All Traffic | TCP | All | 10.10.0.0/16 | Allow |
| 200 | All Traffic | TCP | All | 10.10.5.0/24 | Allow |
| * | All Traffic | All | All | 0.0.0.0/0 | Deny |

---

### NACL Rules - SandboxPublic Subnet

**Inbound Rules:**
| Rule # | Type | Protocol | Port Range | Source | Action |
|---|---|---|---|---|---|
| 100 | All Traffic | TCP | All | 10.10.0.0/16 | Allow |
| 200 | All Traffic | TCP | 443, 80, Others* | 203.0.113.0/24 | Allow |
| * | All Traffic | All | All | 0.0.0.0/0 | Deny |

**Outbound Rules:**
| Rule # | Type | Protocol | Port Range | Destination | Action |
|---|---|---|---|---|---|
| 100 | All Traffic | TCP | All | 10.10.0.0/16 | Allow |
| 200 | All Traffic | TCP | 1025-65535 | 203.0.113.0/24 | Allow |
| * | All Traffic | All | All | 0.0.0.0/0 | Deny |

---

## Implementation Approach

### Phase 1: Foundation Modules
- [ ] VPC Module (terraform-module-sbx-vpc)
- [ ] Subnet Module (terraform-module-sbx-subnet)
- [ ] Security Group Module (terraform-module-sbx-securitygroup)
- [ ] RBAC/IAM Module (terraform-module-sbx-rbac)

### Phase 2: Network Security
- [ ] Network Firewall Module (terraform-module-sbx-firewall)
- [ ] NACL rules implementation
- [ ] VPC Endpoint configuration

### Phase 3: Cost Automation
- [ ] AWS Budget integration (terraform-module-sbx-automation)
- [ ] EventBridge rules and Lambda functions
- [ ] SNS topics and notifications
- [ ] SCP implementation for resource freeze

### Phase 4: Master Orchestration
- [ ] CEPS-AWS-Sandbox master repository setup
- [ ] Module composition and variable mapping
- [ ] Azure DevOps pipeline configuration
- [ ] Testing and validation

---

## Key Configuration Variables (CONFIRMED)

| Variable | Value | Usage |
|---|---|---|
| **AWS Region** | US-East-1 (default, configurable) | Primary deployment region |
| **VPC CIDR** | 10.10.0.0/16 | VPC network range |
| **Subnet CIDRs** | To be defined | Private, Public, Firewall subnets |
| **Specific IPs** | 203.0.113.0/24 | NACL rules for external access (SandboxPrivate & SandboxPublic inbound/outbound) |
| **Firewall IP** | 10.10.5.0/24 | SandboxFirewall subnet internal firewall device communication |
| **SNS Email** | ashishah0412@gmail.com | Budget alert notifications (70%, 85%, 95%) |
| **Quarterly Budget** | $1000 USD | Cost threshold for sandbox environment |
| **VPC Endpoints** | S3, DynamoDB | AWS service access without internet gateway |
| **Environment Tag** | Sandbox | Budget and resource tagging |
| **Application Tag** | XYZ (example) | Application-level cost tracking |

### IP Address Usage Map

**Specific IP (203.0.113.0/24)** - External/Partner IP Range
- **SandboxPrivate Subnet**:
  - Inbound Rule 200: HTTPS (TCP 1025-65535) from 203.0.113.0/24 → ALLOW
  - Outbound Rule 200: HTTPS (TCP 80, 443) to 203.0.113.0/24 → ALLOW
  
- **SandboxPublic Subnet**:
  - Inbound Rule 200: All Traffic (TCP 443, 80, others) from 203.0.113.0/24 → ALLOW
  - Outbound Rule 200: All Traffic (TCP 1025-65535) to 203.0.113.0/24 → ALLOW

**Firewall IP (10.10.5.0/24)** - Internal Firewall Device Range
- **SandboxFirewall Subnet**:
  - Inbound Rule 200: All Traffic (TCP 1025-65535) from 10.10.5.0/24 → ALLOW
  - Outbound Rule 200: All Traffic (TCP All) to 10.10.5.0/24 → ALLOW

**Internal VPC (10.10.0.0/16)** - All Subnets Rules 100
- All three subnets allow inbound/outbound TCP traffic within VPC
- Enables inter-subnet communication and VPC endpoint access

---

## Next Steps (READY FOR DEVELOPMENT)

All requirements have been confirmed and detailed. Proceeding with:

1. ✅ **Confirmed Repository Structure**: 6 golden modules + 1 master orchestration repo
2. ✅ **Confirmed Network Architecture**: 3 subnets (Private, Public, Firewall) with detailed NACL rules
3. ✅ **Confirmed IP Configuration**: 
   - Specific IP: 203.0.113.0/24 (external access)
   - Firewall IP: 10.10.5.0/24 (internal firewall)
   - Internal VPC: 10.10.0.0/16
4. ✅ **Confirmed Cost Automation**: 
   - Quarterly Budget: $1,000
   - SNS Recipient: ashishah0412@gmail.com
   - Alert Thresholds: 70%, 85%, 95%
5. ✅ **Confirmed VPC Endpoints**: S3 and DynamoDB
6. **Next Action**: Begin Terraform module development

