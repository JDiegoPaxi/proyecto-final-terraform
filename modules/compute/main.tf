data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "frontend" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.frontend_instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [var.frontend_security_group_id]
  key_name                    = var.frontend_key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name          = "${var.tenant_id}-frontend"
    TenantId      = var.tenant_id
    TenantName    = var.tenant_name
    ServerRole    = "frontend"
    RequestedUser = var.frontend_username
  }
}

resource "aws_instance" "backend" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.backend_instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [var.backend_security_group_id]
  key_name                    = var.backend_key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name          = "${var.tenant_id}-backend"
    TenantId      = var.tenant_id
    TenantName    = var.tenant_name
    ServerRole    = "backend"
    RequestedUser = var.backend_username
  }
}

resource "aws_instance" "database" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.database_instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [var.database_security_group_id]
  key_name                    = var.database_key_name
  associate_public_ip_address = false

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name          = "${var.tenant_id}-database"
    TenantId      = var.tenant_id
    TenantName    = var.tenant_name
    ServerRole    = "database"
    RequestedUser = var.database_username
  }
}
