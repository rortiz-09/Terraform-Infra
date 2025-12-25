# Module Usage Guide

Comprehensive guide to using reusable Terraform modules for multi-cloud infrastructure deployment.

---

## 📦 Available Modules

### AWS Modules

- `networking` - VPC 3-tier with IPAM
- `security/kms` - Encryption key management
- `governance/service-control-policies` - SCPs
- `logging/cloudtrail` - Audit logging
- `monitoring/cloudwatch-alarms` - Alerting

### Azure Modules

- `governance/policy-assignments` - Azure Policies
- `logging/activity-log` - Centralized logging
- `monitoring/monitor-alerts` - Azure Monitor

### Utility Modules

- `naming` - Naming convention
- `ipam-calculator` - Automatic subnet calculation

---

## 🌐 Networking Module

### Basic Usage

```hcl
module "networking" {
  source = "../../../aws/modules/networking"

  vpc_cidr           = "10.64.0.0/16"  # From IPAM Registry
  project_name       = "my-project"
  environment        = "prod"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  
  enable_nat_gateway  = true
  single_nat_gateway  = false  # Per-AZ NAT for prod
}
```

### Outputs Available

```hcl
output "vpc_id" {
  value = module.networking.vpc_id
}

output "public_subnets" {
  value = module.networking.public_subnets
}

output "app_subnets" {
  value = module.networking.app_subnets
}

output "data_subnets" {
  value = module.networking.data_subnets
}

output "nat_gateway_ips" {
  value = module.networking.nat_gateway_ips
}
```

### Cost Optimization

```hcl
# Development: Single NAT Gateway
module "networking_dev" {
  source = "../../../aws/modules/networking"
  
  vpc_cidr           = "10.64.0.0/16"
  environment        = "dev"
  availability_zones = ["us-east-1a"]  # Single AZ
  
  enable_nat_gateway  = true
  single_nat_gateway  = true  # ⬅️ Cost saving
}

# Production: High Availability
module "networking_prod" {
  source = "../../../aws/modules/networking"
  
  vpc_cidr           = "10.4.0.0/16"
  environment        = "prod"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  
  enable_nat_gateway  = true
  single_nat_gateway  = false  # ⬅️ NAT per AZ
}
```

---

## 🔐 Security Module (KMS)

### Usage

```hcl
module "kms" {
  source = "../../../aws/modules/security/kms"

  key_alias       = "alias/my-project-prod"
  key_description = "Encryption key for ${var.project_name}"
  environment     = "prod"
  
  enable_key_rotation = true
  deletion_window     = 30
  
  key_administrators = [
    "arn:aws:iam::123456789012:role/AdminRole"
  ]
  
  key_users = [
    "arn:aws:iam::123456789012:role/ApplicationRole"
  ]
}

# Use in resources
resource "aws_s3_bucket_server_side_encryption_configuration" "bucket" {
  bucket = aws_s3_bucket.data.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = module.kms.key_id
      sse_algorithm     = "aws:kms"
    }
  }
}
```

---

## 📊 CloudWatch Alarms Module

### Usage

```hcl
module "alarms" {
  source = "../../../aws/modules/monitoring/cloudwatch-alarms"

  project_name = "my-project"
  environment  = "prod"
  
  email_endpoints = [
    "ops-team@empresa.com",
    "platform-team@empresa.com"
  ]
}

# Alarms automatically created:
# - High CPU (EC2)
# - ALB 5XX errors
# - Unhealthy targets
# - RDS CPU/storage
# - Lambda errors/throttles
# - Composite system-critical
```

---

## 🛡️ Azure Policy Assignments

### Usage

```hcl
module "azure_policies" {
  source = "../../../azure/modules/governance/policy-assignments"

  subscription_id = data.azurerm_subscription.current.id
  location        = "eastus2"
  
  enforce_storage_cmk    = true
  deny_public_ips        = true
  require_tls_12         = true
  enable_defender        = true
  
  mandatory_tags = {
    Environment = "prod"
    Owner       = "platform-team"
    CostCenter  = "engineering"
  }
  
  allowed_regions = ["brazilsouth"]
}
```

---

## 📝 Naming Convention Module

### Usage

```hcl
module "naming" {
  source = "../../../modules/utility/naming"
  
  organization = "empresa"
  project      = "banco-finanzas"
  environment  = "prod"
  workload     = "dataplatform"
}

# Outputs standardized names:
# vpc-empresa-banco-finanzas-prod-dataplatform
# rg-empresa-banco-finanzas-prod-dataplatform
# st-empresa-banco-finanzas-prod-dataplatform
```

---

## 🧮 IPAM Calculator Module

### Auto Subnet Calculation

```hcl
module "ipam" {
  source = "../../../modules/utility/ipam-calculator"

  vpc_cidr           = "10.4.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  
  enable_public_tier = true
  enable_app_tier    = true
  enable_data_tier   = true
}

# Automatic output:
# public_subnets = [
#   "10.4.0.0/22",    # AZ-a (1,019 IPs)
#   "10.4.4.0/22",    # AZ-b (1,019 IPs)
#   "10.4.8.0/22"     # AZ-c (1,019 IPs)
# ]
# 
# app_subnets = [
#   "10.4.64.0/20",   # AZ-a (4,091 IPs)
#   "10.4.80.0/20",   # AZ-b (4,091 IPs)
#   "10.4.96.0/20"    # AZ-c (4,091 IPs)
# ]
#
# data_subnets = [
#   "10.4.128.0/20",  # AZ-a (4,091 IPs)
#   "10.4.144.0/20",  # AZ-b (4,091 IPs)
#   "10.4.160.0/20"   # AZ-c (4,091 IPs)
# ]
```

---

## 🏗️ Complete Project Example

### Production Setup

```hcl
# ==================================================================================================
# PROYECTO: Mi Aplicación - PRODUCCIÓN
# ==================================================================================================

terraform {
  required_version = ">= 1.7.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Remote backend (recommended)
  backend "s3" {
    bucket         = "empresa-terraform-state"
    key            = "mi-app/prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

provider "aws" {
  region = "us-east-1"
  
  default_tags {
    tags = {
      Project      = "Mi Aplicación"
      Environment  = "prod"
      ManagedBy    = "Terraform"
      Owner        = "platform-team"
      CostCenter   = "engineering"
    }
  }
}

# Dynamic AZ discovery
data "aws_availability_zones" "available" {
  state = "available"
  
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# Networking with IPAM
module "networking" {
  source = "../../modules/networking"

  vpc_cidr           = "10.100.0.0/16"  # From IPAM Registry
  project_name       = "mi-app"
  environment        = "prod"
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 3)
  
  enable_nat_gateway  = true
  single_nat_gateway  = false  # Multi-AZ for HA
}

# KMS for encryption
module "kms" {
  source = "../../modules/security/kms"

  key_alias       = "alias/mi-app-prod"
  key_description = "Encryption key for Mi App production"
  environment     = "prod"
  
  enable_key_rotation = true
}

# CloudWatch alarms
module "alarms" {
  source = "../../modules/monitoring/cloudwatch-alarms"

  project_name    = "mi-app"
  environment     = "prod"
  email_endpoints = ["ops@empresa.com"]
}

# Outputs
output "vpc_id" {
  value = module.networking.vpc_id
}

output "kms_key_id" {
  value = module.kms.key_id
}
```

---

## 🔄 Module Versioning

### Using Git Tags

```hcl
# Pin to specific version
module "networking" {
  source = "git::https://github.com/empresa/terraform-modules.git//aws/networking?ref=v1.2.0"
  
  # ... variables ...
}

# Use latest from branch
module "networking" {
  source = "git::https://github.com/empresa/terraform-modules.git//aws/networking?ref=main"
  
  # ... variables ...
}
```

---

## 📖 Related Documentation

- [Network Architecture](Network-Architecture) - IPAM details
- [Security & Compliance](Security-and-Compliance) - Security modules
- [Troubleshooting](Troubleshooting) - Common issues

---

**Next**: [Troubleshooting](Troubleshooting) →
