# Únicas salidas públicas del proyecto: direcciones IP de los tres servidores.
output "frontend_ip" {
  description = "IP pública del servidor frontend."
  value       = module.compute.frontend_ip
}

output "backend_ip" {
  description = "IP pública del servidor backend."
  value       = module.compute.backend_ip
}

output "database_ip" {
  description = "IP privada del servidor de base de datos."
  value       = module.compute.database_ip
}
