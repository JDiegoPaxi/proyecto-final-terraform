resource "tls_private_key" "tenant" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "tenant" {
  key_name   = var.tenant_id
  public_key = tls_private_key.tenant.public_key_openssh

  tags = {
    Name     = var.tenant_id
    TenantId = var.tenant_id
  }
}
