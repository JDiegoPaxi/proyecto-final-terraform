terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }

  # El bucket debe existir previamente. La aplicación proporciona key y region
  # durante terraform init mediante -backend-config.
  backend "s3" {
    bucket       = "sis-asistencia-terraform-state"
    encrypt      = true
    use_lockfile = true
  }
}
