# Proyecto: Alcaldía de Guayaquil (AWS)

## 📋 Descripción

Infraestructura escalable para el sistema de recaudación tributaria de la Municipalidad de Guayaquil. Implementa arquitectura multi-AZ con Auto Scaling y protección WAF.

## 🏗️ Arquitectura

- **VPC 3-Tier**: Segregación de capas (Public, App, Data)
- **Multi-AZ**: Alta disponibilidad en producción
- **Auto Scaling**: Ajuste automático de capacidad
- **WAF**: Protección contra OWASP Top 10

## 📁 Estructura

```
Alcaldia_Guayaquil/
├── dev/         # Ambiente de desarrollo (1 AZ, costos reducidos)
└── prod/        # Ambiente de producción (3 AZs, alta disponibilidad)
```

## 🚀 Despliegue

### Desarrollo

```bash
cd dev
terraform init
terraform plan
terraform apply
```

### Producción

```bash
cd prod
terraform init
terraform plan -out=plan.tfplan
# Revisar plan antes de aplicar
terraform apply plan.tfplan
```

## ⚙️ Variables Principales

- `vpc_cidr`: Rango de red (default: 10.1.0.0/16)
- `availability_zones`: AZs a usar
- `environment`: dev | test | prod
- `project_name`: Etiquetado de recursos

## 🔐 Seguridad

- ✅ WAF con reglas OWASP
- ✅ Segregación de red por capas
- ✅ NAT Gateway para

 salida controlada

- ✅ Security Groups restrictivos

## 👤 Contacto

**Autor**: Ronny Ortiz  
**Proyecto**: Municipalidad de Guayaquil
