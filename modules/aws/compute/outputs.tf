output "linux_instances" {
  value = [
    for linux in aws_instance.linux : {
      id         = nonsensitive(linux.id)
      name       = nonsensitive(linux.tags.Name)
      type       = nonsensitive(linux.instance_type)
      private_ip = nonsensitive(linux.private_ip)
      public_ip  = nonsensitive(linux.public_ip)
      public_dns = nonsensitive(linux.public_dns)
    }
  ]
}

output "windows_instances" {
  value = [
    for win in aws_instance.windows : {
      id         = nonsensitive(win.id)
      name       = nonsensitive(win.tags.Name)
      type       = nonsensitive(win.instance_type)
      private_ip = nonsensitive(win.private_ip)
      public_ip  = nonsensitive(win.public_ip)
      public_dns = nonsensitive(win.public_dns)
    }
  ]
}
