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
      Proyecto     = "Recaudacion Impuestos"
      Entidad      = "Alcaldia de Guayaquil"
      Ambiente     = "Produccion"
      CentroCostos = "Direccion Sistemas"
      Compliance   = "ISO 27001"
    }
  }
}

# --------------------------------------------------------------------------------------------------
# GOBERNANZA Y SEGURIDAD (ISO/IEC 27001 - A.13.1 Gestión de seguridad de redes)
# --------------------------------------------------------------------------------------------------
# VPC con segmentación estricta para asegurar aislamiento de cargas de trabajo.
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "vpc-recaudacion-guayaquil"
  }
}

resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone = element(["us-east-1a", "us-east-1b"], count.index)

  tags = {
    Name = "subnet-public-${count.index}"
    Type = "Public"
  }
}

# Security Group para el Load Balancer (Solo permite HTTPS desde el mundo)
# Cumplimiento: Principio de Mínimo Privilegio
resource "aws_security_group" "lb_sg" {
  name        = "sg_alb_recaudacion"
  description = "Permitir trafico web seguro"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS desde Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --------------------------------------------------------------------------------------------------
# DISPONIBILIDAD Y ESCALABILIDAD (NIST CSF - Recuperación y Respuesta)
# --------------------------------------------------------------------------------------------------
# Auto Scaling Group para manejar picos de tráfico durante el pago de prediales (Enero/Febrero)
resource "aws_launch_template" "app_lt" {
  name_prefix   = "lt-recaudacion-"
  image_id      = "ami-12345678" # Placeholder para Amazon Linux 2
  instance_type = "t3.medium"

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.lb_sg.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "srv-recaudacion-web"
    }
  }
}

resource "aws_autoscaling_group" "app_asg" {
  desired_capacity    = 2
  max_size            = 10 # Escalado agresivo para alta demanda
  min_size            = 2
  vpc_zone_identifier = aws_subnet.public[*].id
  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Propósito"
    value               = "Alta Disponibilidad Prediales"
    propagate_at_launch = true
  }
}

# --------------------------------------------------------------------------------------------------
# SEGURIDAD DE APLICACIONES (AWS WAF)
# --------------------------------------------------------------------------------------------------
# Protección contra ataques comunes (SQL Injection, XSS) críticos para portales públicos.
resource "aws_wafv2_web_acl" "waf_recaudacion" {
  name        = "waf-recaudacion-guayaquil"
  description = "WAF para proteger el portal de pagos"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "WAFRecaudacionMetrics"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRules"
      sampled_requests_enabled   = true
    }
  }
}
