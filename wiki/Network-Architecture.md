# Network Architecture

Comprehensive network design with IPAM strategy, tier-based segmentation, and hub-spoke topology for multi-cloud deployment.

---

## 🌐 IPAM Strategy

### Global IP Allocation

| Cloud | Range | Allocation | Projects |
|-------|-------|------------|----------|
| **AWS** | 10.0.0.0/8 | Gobierno, Telecoms | 3 |
| **Azure** | 172.16.0.0/12 | Finanzas, Retail, Industria | 5 |
| **GCP** | 192.168.0.0/16 | Municipios, Logística, Fintech | 3 |

### Design Principles

✅ **Zero IP Overlap** - No CIDR collisions across 11 projects  
✅ **Scalability** - Capacity for 10x growth  
✅ **Segmentation** - Prod/Non-prod/Sandbox separation  
✅ **OU Isolation** - Dedicated ranges per organizational unit

See full registry: [IPAM_REGISTRY.md](../docs/IPAM_REGISTRY.md)

---

## 🏗️ Tier-Based Architecture

Every VPC/VNet implements 3-tier segmentation:

### Tier 1: Public (/22 per AZ)

- **Purpose**: Internet-facing resources
- **Resources**: ALB, NAT Gateway, Bastion
- **Capacity**: ~1,019 IPs per AZ
- **Internet**: Bidirectional via Internet Gateway

### Tier 2: Application (/20 per AZ)

- **Purpose**: Business logic workloads
- **Resources**: EC2, ECS, AKS, App Services
- **Capacity**: ~4,091 IPs per AZ
- **Internet**: Outbound only via NAT Gateway

### Tier 3: Data (/20 per AZ)

- **Purpose**: Data persistence layer
- **Resources**: RDS, SQL Database, ElastiCache
- **Capacity**: ~4,091 IPs per AZ
- **Internet**: None (fully isolated)

---

## 🔗 Hub-Spoke Topology

### AWS Architecture

```
┌─────────────────────────────────────┐
│       VPC Hub (10.0.0.0/16)        │
│  ┌──────────┐     ┌──────────┐     │
│  │  Transit │     │   NAT    │     │
│  │  Gateway │     │ Gateways │     │
│  └────┬─────┘     └──────────┘     │
└───────┼──────────────────────────────┘
        │
    ┌───┴───┬────────┬────────┐
    │       │        │        │
┌───▼───┐ ┌─▼────┐ ┌─▼────┐ ┌─▼────┐
│Spoke 1│ │Spoke2│ │Spoke3│ │SpokeN│
│(10.4) │ │(10.8)│ │(10.12)│ │ ...  │
└───────┘ └──────┘ └──────┘ └──────┘
```

**Components**:

- Transit Gateway for centralized routing
- Shared services in Hub (DNS, Monitoring)
- Isolated workloads in Spokes

### Azure Architecture

```
┌─────────────────────────────────────┐
│      Hub VNet (172.16.0.0/16)      │
│  ┌──────────┐     ┌──────────┐     │
│  │  Azure   │     │   VPN    │     │
│  │ Firewall │     │ Gateway  │     │
│  └────┬─────┘     └──────────┘     │
└───────┼──────────────────────────────┘
        │ VNet Peering
    ┌───┴───┬────────┬────────┐
    │       │        │        │
┌───▼───┐ ┌─▼────┐ ┌─▼────┐ ┌─▼────┐
│Spoke 1│ │Spoke2│ │Spoke3│ │SpokeN│
│(172.18)│(172.20)│(172.22)│ │ ...  │
└───────┘ └──────┘ └──────┘ └──────┘
```

**Components**:

- Azure Firewall for outbound filtering
- VNet Peering for private connectivity
- Private Endpoints for PaaS services

---

## 📋 IPAM Calculator

Automated subnet calculation based on VPC CIDR and tier strategy.

### Usage Example

```hcl
module "ipam" {
  source = "../../../modules/utility/ipam-calculator"

  vpc_cidr           = "10.64.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  enable_public_tier = true
  enable_app_tier    = true
  enable_data_tier   = true
}

# Output:
# Public subnets: 10.64.0.0/22, 10.64.4.0/22, 10.64.8.0/22
# App subnets:    10.64.64.0/20, 10.64.80.0/20, 10.64.96.0/20
# Data subnets:   10.64.128.0/20, 10.64.144.0/20, 10.64.160.0/20
```

---

## 🛡️ Network Security Controls

### Layer 4 (Network)

- Network Security Groups (Azure)
- Security Groups (AWS)
- Firewall Rules (GCP)
- **Default**: Deny all, allow specific

### Layer 7 (Application)

- Application Gateway (Azure)
- Application Load Balancer (AWS)
- Cloud Armor (GCP)

### Traffic Flow Control

```
Internet → ALB/AppGW → WAF → App Tier → Data Tier
              ↓
           NAT Gateway (for outbound)
```

---

## 🔍 Cross-Cloud Connectivity

For multi-cloud scenarios:

| Method | Use Case | Encryption |
|--------|----------|------------|
| **VPN Site-to-Site** | AWS ↔ Azure | IPSec |
| **AWS Direct Connect** | On-prem → AWS | Private fiber |
| **Azure ExpressRoute** | On-prem → Azure | Private fiber |
| **GCP Interconnect** | On-prem → GCP | Private fiber |

**Critical**: Ensure no IP overlap when connecting clouds

---

## 📊 Network Monitoring

### Metrics Tracked

- VPC Flow Logs (AWS)
- NSG Flow Logs (Azure)
- VPC Flow Logs (GCP)

### Alerts Configured

- Unusual traffic patterns
- Port scanning attempts
- DDoS indicators
- Bandwidth threshold breaches

---

## 📖 Related Documentation

- [IPAM Registry](../docs/IPAM_REGISTRY.md) - Complete IP allocations
- [Security & Compliance](Security-and-Compliance) - Security controls
- [Module Usage](Module-Usage-Guide) - Using networking module

---

**Next**: [Security & Compliance](Security-and-Compliance) →
