output "ssh_firewall_id" {
  value = google_compute_firewall.ssh.id
}

output "rdp_firewall_id" {
  value = google_compute_firewall.rdp.id
}

output "iap_firewall_id" {
  value = google_compute_firewall.iap.id
}
