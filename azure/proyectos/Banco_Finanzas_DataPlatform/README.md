# Proyecto: Banco Finanzas - Plataforma de Datos (Azure)

## 📋 Descripción

Plataforma analítica de datos para procesos de gestión de riesgo crediticio. Cumple con estándares PCI-DSS y SOX.

## 🏗️ Componentes

- **Data Lake Gen2**: Almacenamiento jerárquico (Raw/Curated)
- **Synapse Analytics**: Procesamiento SQL masivo (DW1000c)
- **Private Endpoints**: Acceso denegado por defecto
- **Managed Identity**: Autenticación sin credenciales

## 🔐 Seguridad y Cumplimiento

- ✅ **PCI-DSS**: Cifrado en reposo (ZRS), red privada
- ✅ **SOX**: Auditoría habilitada, identidad administrada
- ✅ **ISO 27001**: Managed VNet, denegación por defecto

## 🚀 Despliegue

```bash
cd prod
terraform init
terraform plan
terraform apply -auto-approve=false
```

## 📊 Capacidad

- **Synapse SQL Pool**: DW1000c (10,000 DWUs)
- **Storage**: Zone-Redundant Storage (ZRS)
- **Network**: Managed Virtual Network isolada

## 👥 Colaboradores

- **Data Engineers**: Definición de estructura de datos
- **CISO Office**: Requisitos de seguridad y compliance

## 👤 Contacto

**Autor**: Ronny Ortiz  
**Cliente**: Sector Financiero Ecuador
