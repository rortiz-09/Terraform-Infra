terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Proyecto = "Claro Ecuador VDI"
      Servicio = "Citrix Virtual Apps"
    }
  }
}

# --------------------------------------------------------------------------------------------------
# COMPUTO DE ALTO RENDIMIENTO (Citrix Workloads)
# --------------------------------------------------------------------------------------------------
resource "aws_instance" "citrix_vda" {
  count         = 5
  ami           = "ami-12345678"    # Windows Server 2022 Base
  instance_type = "g4dn.xlarge"     # GPU enable para renderizado gráfico
  subnet_id     = "subnet-12345678" # Placeholder

  # User Data para unirse al dominio y registrarse en el Citrix Cloud Connector
  user_data = <<EOF
<powershell>
# Script de registro en Active Directory
Add-Computer -DomainName "corp.claro.com.ec" -Restart
</powershell>
EOF

  tags = {
    Name = "vda-prod-${count.index}"
  }
}

# --------------------------------------------------------------------------------------------------
# ALMACENAMIENTO DE PERFILES (FSx for Windows File Server)
# --------------------------------------------------------------------------------------------------
# Almacenamiento SMB nativo de alto rendimiento para perfiles móviles (FSLogix).
resource "aws_fsx_windows_file_system" "profiles" {
  storage_capacity    = 1024
  throughput_capacity = 32
  subnet_ids          = ["subnet-12345678"] # Placeholder

  self_managed_active_directory {
    dns_ips     = ["10.0.0.10", "10.0.0.11"]
    domain_name = "corp.claro.com.ec"
    password    = "AvoidPlaintextPasswords!"
    username    = "Admin"
  }
}
