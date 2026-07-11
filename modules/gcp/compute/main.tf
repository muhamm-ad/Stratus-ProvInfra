terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2404-lts"
  project = "ubuntu-os-cloud"
}

data "google_compute_image" "windows" {
  family  = "windows-2022"
  project = "windows-cloud"
}

resource "google_compute_instance" "linux" {
  count = var.linux_instances.count

  name         = "${var.name_prefix}-linux-${count.index + 1}"
  machine_type = var.linux_instances.machine_type
  zone         = "${var.region}-a"
  project      = var.project_id

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = 32
      type  = "pd-ssd"
    }
  }

  network_interface {
    subnetwork = var.linux_instances.subnet_name
    access_config {}
  }

  labels = {
    environment = lookup(var.tags, "Environment", "dev")
    project     = lookup(var.tags, "Project", "stratus")
    os          = "linux"
  }
}

resource "google_compute_instance" "windows" {
  count = var.windows_instances.count

  name         = "${var.name_prefix}-windows-${count.index + 1}"
  machine_type = var.windows_instances.machine_type
  zone         = "${var.region}-a"
  project      = var.project_id

  boot_disk {
    initialize_params {
      image = data.google_compute_image.windows.self_link
      size  = 32
      type  = "pd-ssd"
    }
  }

  network_interface {
    subnetwork = var.windows_instances.subnet_name
  }

  labels = {
    environment = lookup(var.tags, "Environment", "dev")
    project     = lookup(var.tags, "Project", "stratus")
    os          = "windows"
  }
}
