# --------------------------------------------------------------------------------------------------
# Outputs del Módulo de Networking (AWS)
# Descripción: Expone los IDs de recursos creados para su uso en otros módulos/proyectos
# Autor: Ronny
# --------------------------------------------------------------------------------------------------

output "vpc_id" {
  description = "ID de la VPC creada"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block de la VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnets" {
  description = "Lista de IDs de subnets públicas (una por AZ)"
  value       = aws_subnet.public[*].id
}

output "app_subnets" {
  description = "Lista de IDs de subnets de aplicación (capa privada)"
  value       = aws_subnet.app[*].id
}

output "data_subnets" {
  description = "Lista de IDs de subnets de datos (capa aislada)"
  value       = aws_subnet.data[*].id
}

output "nat_gateway_ids" {
  description = "Lista de IDs de NAT Gateways creados"
  value       = aws_nat_gateway.main[*].id
}

output "internet_gateway_id" {
  description = "ID del Internet Gateway"
  value       = aws_internet_gateway.igw.id
}
