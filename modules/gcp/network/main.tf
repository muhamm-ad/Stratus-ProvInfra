terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

resource "google_compute_network" "main" {
  name                    = "${var.name_prefix}-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  project                 = var.project_id
}

resource "google_compute_subnetwork" "linux" {
  name          = "${var.name_prefix}-subnet-linux"
  ip_cidr_range = var.subnet_configs.linux.cidr
  region        = var.region
  network       = google_compute_network.main.id
  project       = var.project_id
}

resource "google_compute_subnetwork" "windows" {
  name          = "${var.name_prefix}-subnet-windows"
  ip_cidr_range = var.subnet_configs.windows.cidr
  region        = var.region
  network       = google_compute_network.main.id
  project       = var.project_id
}

resource "google_compute_router" "main" {
  name    = "${var.name_prefix}-router"
  region  = var.region
  network = google_compute_network.main.id
  project = var.project_id
}

resource "google_compute_router_nat" "main" {
  name                               = "${var.name_prefix}-nat"
  router                             = google_compute_router.main.name
  region                             = google_compute_router.main.region
  project                            = var.project_id
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
