output "key_name" {
  value = aws_key_pair.tenant.key_name
}

output "private_key_pem" {
  value     = tls_private_key.tenant.private_key_pem
  sensitive = true
}
