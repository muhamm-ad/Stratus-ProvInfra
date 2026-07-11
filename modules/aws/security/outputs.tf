output "security_group_id" {
  value = aws_security_group.main.id
}

output "key_name" {
  value = aws_key_pair.main.key_name
}
