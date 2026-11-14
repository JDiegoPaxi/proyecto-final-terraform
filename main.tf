locals {
  tenant_name = var.tenant_id
  requested_username = "${var.tenant_id}-ubuntu"
}

module "network" {
  source = "./modules/network"

  tenant_id          = var.tenant_id
  tenant_name        = local.tenant_name
  vpc_cidr           = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
  aws_region         = var.aws_region
}

module "security" {
  source = "./modules/security"

  tenant_id        = var.tenant_id
  tenant_name      = local.tenant_name
  vpc_id           = module.network.vpc_id
  ssh_allowed_cidr = var.ssh_allowed_cidr
}

module "ssh" {
  source = "./modules/ssh"

  tenant_id = var.tenant_id
}

resource "local_sensitive_file" "tenant_private_key" {
  filename        = "${var.ssh_key_directory}/${var.tenant_id}/${var.tenant_id}.pem"
  content         = module.ssh.private_key_pem
  file_permission = "0600"
}

module "compute" {
  source = "./modules/compute"

  tenant_id                  = var.tenant_id
  tenant_name                = local.tenant_name
  aws_region                 = var.aws_region
  public_subnet_id           = module.network.public_subnet_id
  frontend_security_group_id = module.security.frontend_security_group_id
  backend_security_group_id  = module.security.backend_security_group_id
  database_security_group_id = module.security.database_security_group_id
  frontend_key_name          = module.ssh.key_name
  backend_key_name           = module.ssh.key_name
  database_key_name          = module.ssh.key_name
  frontend_username          = local.requested_username
  backend_username           = local.requested_username
  database_username          = local.requested_username
  frontend_instance_type     = var.frontend_instance_type
  backend_instance_type      = var.backend_instance_type
  database_instance_type     = var.database_instance_type
  root_volume_size           = var.root_volume_size
}
