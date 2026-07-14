output "network_name" {
  value = google_compute_network.main.name
}

output "network_id" {
  value = google_compute_network.main.id
}

output "subnet_names" {
  value = { for workload, subnet in google_compute_subnetwork.workload : workload => subnet.name }
}

output "subnet_ids" {
  value = { for workload, subnet in google_compute_subnetwork.workload : workload => subnet.id }
}
