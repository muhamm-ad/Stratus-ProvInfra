terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

resource "google_compute_network" "main" {
  name                    = "${var.name_prefix}_vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  project                 = var.project_id
}

resource "google_compute_subnetwork" "workload" {
  for_each = var.subnet_configs

  name          = "${var.name_prefix}_subnet_${each.key}"
  ip_cidr_range = each.value.cidr
  region        = var.region
  network       = google_compute_network.main.id
  project       = var.project_id
}

moved {
  from = google_compute_subnetwork.linux
  to   = google_compute_subnetwork.workload["linux"]
}

moved {
  from = google_compute_subnetwork.windows
  to   = google_compute_subnetwork.workload["windows"]
}

resource "google_compute_router" "main" {
  name    = "${var.name_prefix}_router"
  region  = var.region
  network = google_compute_network.main.id
  project = var.project_id
}

resource "google_compute_router_nat" "main" {
  name                               = "${var.name_prefix}_nat"
  router                             = google_compute_router.main.name
  region                             = google_compute_router.main.region
  project                            = var.project_id
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
