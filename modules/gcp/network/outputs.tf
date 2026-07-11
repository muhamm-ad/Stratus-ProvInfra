output "network_name" {
  value = google_compute_network.main.name
}

output "network_id" {
  value = google_compute_network.main.id
}

output "subnet_names" {
  value = {
    linux   = google_compute_subnetwork.linux.name
    windows = google_compute_subnetwork.windows.name
  }
}

output "subnet_ids" {
  value = {
    linux   = google_compute_subnetwork.linux.id
    windows = google_compute_subnetwork.windows.id
  }
}
