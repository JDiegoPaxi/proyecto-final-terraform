resource "aws_security_group" "frontend" {
  name        = "${var.tenant_id}-frontend-sg"
  description = "Acceso HTTP/HTTPS y SSH restringido para frontend"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH desde CIDR autorizado"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name     = "${var.tenant_id}-frontend-sg"
    TenantId = var.tenant_id
  }
}

resource "aws_security_group" "backend" {
  name        = "${var.tenant_id}-backend-sg"
  description = "SSH restringido y trafico de aplicacion solo desde frontend"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH desde CIDR autorizado"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  ingress {
    description     = "Aplicacion desde frontend"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name     = "${var.tenant_id}-backend-sg"
    TenantId = var.tenant_id
  }
}

resource "aws_security_group" "database" {
  name        = "${var.tenant_id}-database-sg"
  description = "SSH restringido y PostgreSQL solo desde backend"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH desde CIDR autorizado"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  ingress {
    description     = "PostgreSQL desde backend"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.backend.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name     = "${var.tenant_id}-database-sg"
    TenantId = var.tenant_id
  }
}
