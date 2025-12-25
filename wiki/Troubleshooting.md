# Troubleshooting

Common issues, error messages, and solutions for Terraform multi-cloud infrastructure.

---

## 🔍 Quick Diagnostics

```bash
# Validate configuration
terraform validate

# Check formatting
terraform fmt -check -recursive

# Refresh state
terraform refresh

# Show current state
terraform show
```

---

## ❌ Common Errors

### Error: Duplicate Variable Declaration

**Symptom**:

```
Error: Duplicate variable declaration
A variable named "vpc_cidr" was already declared at main.tf:9,1-20
```

**Root Cause**: Variables defined in both `main.tf` and `variables.tf`

**Solution**:

```bash
# Remove duplicate definitions
# Keep variables in ONE place only (either main.tf OR variables.tf)
```

---

### Error: Module Not Installed

**Symptom**:

```
Error: Module not installed
This module is not yet installed. Run "terraform init"
```

**Solution**:

```bash
terraform init
terraform get -update
```

---

### Error: Unsu itable Value Type (prevent_destroy)

**Symptom**:

```
Error: Unsuitable value type
prevent_destroy = var.environment == "prod" ? true : false
Variables may not be used here.
```

**Root Cause**: `prevent_destroy` requires literal boolean, not conditional

**Solution**:

```hcl
# ❌ Wrong
lifecycle {
  prevent_destroy = var.environment == "prod" ? true : false
}

# ✅ Correct
lifecycle {
  prevent_destroy = true  # Literal value only
}
```

---

### Error: Unsupported Attribute

**Symptom**:

```
Error: Unsupported attribute
module.networking.vpc_id
This object does not have an attribute named "vpc_id"
```

**Root Cause**: Module missing outputs section

**Solution**:

```hcl
# Add to module's outputs.tf
output "vpc_id" {
  description = "ID del VPC"
  value       = aws_vpc.main.id
}
```

---

### Error: Reference to Undeclared Module

**Symptom**:

```
Error: Reference to undeclared module
No module call named "networking_dev" is declared
```

**Root Cause**: Module name mismatch

**Solution**:

```hcl
# ❌ Wrong
module "networking_dev" { ... }
# ...
subnet_id = module.networking.public_subnets[0]  # Different name!

# ✅ Correct
module "networking" { ... }
# ...
subnet_id = module.networking.public_subnets[0]  # Same name
```

---

### Error: CIDR Overlap

**Symptom**:

```
Error: Resource already exists
VPC CIDR overlaps with existing VPC
```

**Root Cause**: IP address collision

**Solution**:

1. Check `docs/IPAM_REGISTRY.md` for allocated ranges
2. Use next available CIDR from registry
3. Update registry with new allocation

---

### Error: Backend Initialization Failed

**Symptom**:

```
Error: Failed to get existing workspaces
AccessDenied: Access Denied
```

**Root Cause**: Missing S3/DynamoDB permissions

**Solution**:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::terraform-state-bucket",
        "arn:aws:s3:::terraform-state-bucket/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:*:*:table/terraform-locks"
    }
  ]
}
```

---

## 🐛 Debugging Tips

### Enable Debug Logging

```bash
# Terraform debug
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform-debug.log
terraform plan

# Provider-specific logging
export TF_LOG_PROVIDER=TRACE
```

### Inspect State

```bash
# List all resources
terraform state list

# Show specific resource
terraform state show aws_vpc.main

# Import existing resource
terraform import aws_vpc.main vpc-12345678
```

### Validate JSON/HCL

```bash
# Validate HCL syntax
terraform validate

# Format code
terraform fmt -recursive

# Show plan in JSON
terraform plan -out=tfplan
terraform show -json tfplan | jq
```

---

## 🔄 State Issues

### State Lock Stuck

**Symptom**: "Error acquiring the state lock"

**Solution**:

```bash
# ⚠️  ONLY if you're sure no other terraform is running
terraform force-unlock <lock-id>
```

### Drift Detected

**Symptom**: Resources deleted outside Terraform

**Solution**:

```bash
# Refresh state
terraform refresh

# If resource was deleted manually, remove from state
terraform state rm aws_instance.deleted_instance

# Recreate if needed
terraform apply
```

### State Corruption

**Symptom**: "Inconsistent dependency lock file"

**Solution**:

```bash
# Backup current state
cp terraform.tfstate terraform.tfstate.backup

# Reinitialize
rm -rf .terraform/
rm .terraform.lock.hcl
terraform init
```

---

## 🔐 Permissions Issues

### AWS Access Denied

```bash
# Verify credentials
aws sts get-caller-identity

# Test specific action
aws ec2 describe-vpcs

# Check IAM policy simulator
# https://policysim.aws.amazon.com/
```

### Azure Unauthorized

```bash
# Check current context
az account show

# List subscriptions
az account list --output table

# Set subscription
az account set --subscription "subscription-id"
```

### GCP Permission Denied

```bash
# Check active account
gcloud auth list

# Activate service account
gcloud auth activate-service-account --key-file=key.json

# Check project
gcloud config get-value project
```

---

## 📊 Performance Issues

### Slow Terraform Plan

**Symptom**: `terraform plan` takes >5 minutes

**Solutions**:

1. **Use target flag** for specific resources:

   ```bash
   terraform plan -target=module.networking
   ```

2. **Parallelize**:

   ```bash
   terraform plan -parallelism=20
   ```

3. **Reduce provider calls**:

   ```hcl
   # Cache data sources
   data "aws_caller_identity" "current" {}
   
   locals {
     account_id = data.aws_caller_identity.current.account_id
   }
   ```

---

## 🆘 Getting Help

### Error Not Listed Here?

1. **Search docs**: `docs/` directory
2. **Check audit report**: `docs/IAC_AUDIT_REPORT.md`
3. **GitHub Issues**: Create detailed issue
4. **Internal Slack**: #platform-engineering
5. **Email**: <platform@empresa.com>

### Creating Good Bug Reports

Include:

- Terraform version (`terraform version`)
- Provider versions
- Full error message
- Steps to reproduce
- Relevant code snippet
- Expected vs actual behavior

---

## 📖 Related Documentation

- [Module Usage Guide](Module-Usage-Guide) - Proper module usage
- [Security & Compliance](Security-and-Compliance) - Security best practices
- [Network Architecture](Network-Architecture) - Network design

---

**Back to**: [Wiki Home](Home) ←
