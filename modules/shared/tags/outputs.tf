output "tags" {
  value = merge(
    local.common_tags,
    var.additional_tags
  )
}
