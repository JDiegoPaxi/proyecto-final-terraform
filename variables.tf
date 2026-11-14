variable "tenant_id" {
  description = "Identificador único del tenant; se utiliza en nombres y etiquetas."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,30}$", var.tenant_id))
    error_message = "tenant_id debe contener entre 2 y 31 caracteres: minúsculas, números o guiones, comenzando por letra o número."
  }
}

variable "ssh_key_directory" {
  description = "Carpeta base donde se guardan las claves privadas PEM, separadas en una subcarpeta por tenant."
  type        = string
  default     = "C:/llaves"
}

variable "aws_region" {
  description = "Región AWS donde se desplegará el tenant."
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "CIDR autorizado para SSH. El valor por defecto solo permite acceso local; cámbialo por tu IP pública/32 para administrar las instancias."
  type        = string
  default     = "166.114.174.56/32"

  validation {
    condition     = can(cidrhost(var.ssh_allowed_cidr, 0))
    error_message = "ssh_allowed_cidr debe ser un bloque CIDR válido."
  }
}

variable "frontend_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "backend_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "database_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "root_volume_size" {
  description = "Tamaño del volumen raíz en GiB para las tres EC2."
  type        = number
  default     = 20
}

