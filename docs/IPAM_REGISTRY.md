# IPAM Registry - Multi-Cloud Network Allocations

## 📊 Registro Centralizado de Direccionamiento IP

---

## AWS - 10.0.0.0/8

### Production Environment

| Unidad Organizativa | Proyecto | VPC CIDR | Ambiente | Región | Status |
|---------------------|----------|----------|----------|--------|--------|
| **Hub Shared Services** | Transit Gateway | 10.0.0.0/16 | Shared | us-east-1 | Reserved |
| **Hub Shared Services** | Monitoring | 10.1.0.0/16 | Shared | us-east-1 | Reserved |
| Gobierno | Alcaldía Guayaquil | 10.4.0.0/16 | Prod | us-east-1 | Active |
| Gobierno | Alcaldía Guayaquil DR | 10.5.0.0/16 | Prod | us-west-2 | Reserved |
| Gobierno | Prefectura Guayas | 10.8.0.0/16 | Prod | us-east-1 | Active |
| Telecomunicaciones | Claro Ecuador VDI | 10.12.0.0/16 | Prod | us-east-1 | Active |

### Non-Production Environment

| Unidad Organizativa | Proyecto | VPC CIDR | Ambiente | Región | Status |
|---------------------|----------|----------|----------|--------|--------|
| Gobierno | Alcaldía Guayaquil | 10.64.0.0/16 | Dev | us-east-1 | Active |
| Gobierno | Prefectura Guayas | 10.68.0.0/16 | Dev | us-east-1 | Reserved |
| Telecomunicaciones | Claro Ecuador | 10.72.0.0/16 | Dev | us-east-1 | Reserved |

### Sandbox Environment

| Unidad Organizativa | Proyecto | VPC CIDR | Ambiente | Región | Status |
|---------------------|----------|----------|----------|--------|--------|
| Multi-OU | Sandbox General | 10.128.0.0/16 | Sandbox | us-east-1 | Available |

---

## Azure - 172.16.0.0/12

### Production Environment

| Unidad Organizativa | Proyecto | VNet CIDR | Ambiente | Región | Status |
|---------------------|----------|-----------|----------|--------|--------|
| **Hub Shared Services** | Azure Firewall Hub | 172.16.0.0/16 | Shared | East US 2 | Reserved |
| **Hub Shared Services** | Gateway Services | 172.17.0.0/16 | Shared | East US 2 | Reserved |
| Finanzas | Banco DataPlatform | 172.18.0.0/16 | Prod | East US 2 | Active |
| Retail | Supermaxi E-Commerce | 172.20.0.0/16 | Prod | East US 2 | Active |
| Industria | Pronaca SAP | 172.22.0.0/16 | Prod | East US 2 | Active |
| Gobierno | Alcaldía Quito | 172.24.0.0/16 | Prod | East US 2 | Reserved |
| Salud | Expediente Electrónico | 172.26.0.0/16 | Prod | East US 2 | Reserved |

### Non-Production Environment

| Unidad Organizativa | Proyecto | VNet CIDR | Ambiente | Región | Status |
|---------------------|----------|-----------|----------|--------|--------|
| Finanzas | Banco DataPlatform | 172.28.0.0/16 | Dev | East US 2 | Reserved |
| Retail | Supermaxi E-Commerce | 172.29.0.0/16 | Dev | East US 2 | Reserved |
| Industria | Pronaca SAP | 172.30.0.0/16 | Dev | East US 2 | Reserved |

---

## GCP - 192.168.0.0/16

### Production Environment

| Unidad Organizativa | Proyecto | VPC CIDR | Ambiente | Región | Status |
|---------------------|----------|----------|----------|--------|--------|
| **Hub Shared Services** | Shared VPC | 192.168.0.0/19 | Shared | us-central1 | Reserved |
| Gobierno | Municipio Otavalo | 192.168.32.0/19 | Prod | us-central1 | Active |
| Logística | Predictiva AI | 192.168.64.0/19 | Prod | us-central1 | Active |
| Fintech | Banca Abierta | 192.168.96.0/19 | Prod | us-central1 | Active |

### Non-Production Environment

| Unidad Organizativa | Proyecto | VPC CIDR | Ambiente | Región | Status |
|---------------------|----------|----------|----------|--------|--------|
| Gobierno | Municipio Otavalo | 192.168.128.0/19 | Dev | us-central1 | Reserved |
| Logística | Predictiva AI | 192.168.160.0/19 | Dev | us-central1 | Reserved |
| Fintech | Banca Abierta | 192.168.192.0/19 | Dev | us-central1 | Reserved |

---

## 📋 Subnet Breakdown Example

### AWS Alcaldía Guayaquil (10.4.0.0/16)

| Tier | Subnet Name | CIDR | AZ | Purpose | Hosts |
|------|-------------|------|-----|---------|-------|
| Public | snet-public-1a | 10.4.0.0/22 | us-east-1a | ALB, NAT GW | 1,019 |
| Public | snet-public-1b | 10.4.4.0/22 | us-east-1b | ALB, NAT GW | 1,019 |
| Public | snet-public-1c | 10.4.8.0/22 | us-east-1c | ALB, NAT GW | 1,019 |
| App | snet-app-1a | 10.4.64.0/20 | us-east-1a | EC2 Web/API | 4,091 |
| App | snet-app-1b | 10.4.80.0/20 | us-east-1b | EC2 Web/API | 4,091 |
| App | snet-app-1c | 10.4.96.0/20 | us-east-1c | EC2 Web/API | 4,091 |
| Data | snet-data-1a | 10.4.128.0/20 | us-east-1a | RDS, ElastiCache | 4,091 |
| Data | snet-data-1b | 10.4.144.0/20 | us-east-1b | RDS, ElastiCache | 4,091 |
| Data | snet-data-1c | 10.4.160.0/20 | us-east-1c | RDS, ElastiCache | 4,091 |

---

## 🔍 IP Allocation Summary

| Cloud | Total Range | Allocated | Reserved | Available |
|-------|-------------|-----------|----------|-----------|
| AWS | 10.0.0.0/8 | 6 VPCs | 5 VPCs | 16.7M IPs |
| Azure | 172.16.0.0/12 | 5 VNets | 5 VNets | 1M IPs |
| GCP | 192.168.0.0/16 | 3 VPCs | 3 VPCs | 65K IPs |

---

## 🛡️ Network Isolation Rules

### Inter-VPC Communication

| Source OU | Target OU | Allowed | Method |
|-----------|-----------|---------|--------|
| Any Spoke | Hub | ✅ Yes | Transit GW / Peering |
| Spoke A | Spoke B | ❌ No | Deny (use Hub) |
| Prod | Non-Prod | ❌ No | Strict separation |
| AWS | Azure | ❌ No | Separate networks |

### Cross-Cloud Communication

Para comunicación inter-cloud (AWS ↔ Azure ↔ GCP):

- **VPN Site-to-Site** (encrypted tunnels)
- **Private connectivity** (AWS Direct Connect, Azure ExpressRoute, GCP Interconnect)
- **NO** overlap de rangos IP

---

## 📝 Change Management

### Proceso para Nueva Asignación

1. **Request**: Solicitar rango en IPAM registry
2. **Verify**: Verificar no overlap con rangos existentes
3. **Allocate**: Asignar desde rango disponible de OU
4. **Document**: Actualizar este registry
5. **Deploy**: Implementar con Terraform
6. **Validate**: Confirmar conectividad

### Responsabilidades

- **Platform Team**: Mantener IPAM registry actualizado
- **Project Teams**: Reportar uso de subnets
- **Security Team**: Auditar segmentación

---

**Última Actualización**: 2025-12-25  
**Maintainer**: Platform Engineering Team  
**Status**: Active - Production
