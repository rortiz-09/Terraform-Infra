# ==================================================================================================
# OUTPUTS
# ==================================================================================================
output "vpc_id" {
  description = "ID del VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block del VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnets" {
  description = "IDs de subnets públicos"
  value       = aws_subnet.public[*].id
}

output "app_subnets" {
  description = "IDs de subnets de aplicación"
  value       = aws_subnet.app[*].id
}

output "data_subnets" {
  description = "IDs de subnets de datos"
  value       = aws_subnet.data[*].id
}

output "nat_gateway_ips" {
  description = "IPs públicas de NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}

output "ipam_summary" {
  description = "Resumen de asignación de IPs"
  value       = module.ipam.summary
}
