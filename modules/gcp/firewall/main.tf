terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

resource "google_compute_firewall" "ssh" {
  name      = "${var.name_prefix}-allow-ssh"
  network   = var.network_name
  project   = var.project_id
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "rdp" {
  name      = "${var.name_prefix}-allow-rdp"
  network   = var.network_name
  project   = var.project_id
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "iap" {
  name      = "${var.name_prefix}-allow-iap"
  network   = var.network_name
  project   = var.project_id
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22", "3389"]
  }

  source_ranges = ["35.235.240.0/20"]
}
