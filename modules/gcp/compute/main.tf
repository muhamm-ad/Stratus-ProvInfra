terraform {
  required_providers {
    required_version = ">= 1.5.0"
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

data "google_compute_image" "ubuntu" {
  count   = var.linux_instances != null ? 1 : 0
  family  = "ubuntu-2404-lts"
  project = "ubuntu-os-cloud"
}

data "google_compute_image" "windows" {
  count   = var.windows_instances != null ? 1 : 0
  family  = "windows-2022"
  project = "windows-cloud"
}

resource "google_compute_instance" "linux" {
  count = try(var.linux_instances.count, 0)

  name         = "${var.name_prefix}_linux_${count.index + 1}"
  machine_type = try(var.linux_instances.machine_type, null)
  zone         = "${var.region}-a"
  project      = var.project_id

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu[0].self_link
      size  = 32
      type  = "pd-ssd"
    }
  }

  network_interface {
    subnetwork = try(var.linux_instances.subnet_name, null)
    access_config {}
  }

  labels = {
    environment = lookup(var.tags, "Environment", "dev")
    project     = lookup(var.tags, "Project", "stratus")
    os          = "linux"
  }
}

resource "google_compute_instance" "windows" {
  count = try(var.windows_instances.count, 0)

  name         = "${var.name_prefix}_windows_${count.index + 1}"
  machine_type = try(var.windows_instances.machine_type, null)
  zone         = "${var.region}-a"
  project      = var.project_id

  boot_disk {
    initialize_params {
      image = data.google_compute_image.windows[0].self_link
      size  = 32
      type  = "pd-ssd"
    }
  }

  network_interface {
    subnetwork = try(var.windows_instances.subnet_name, null)
  }

  labels = {
    environment = lookup(var.tags, "Environment", "dev")
    project     = lookup(var.tags, "Project", "stratus")
    os          = "windows"
  }
}
