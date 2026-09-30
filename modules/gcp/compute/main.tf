terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

locals {
  userdata_dir = "${path.module}/../../shared/userdata"

  linux_userdata = templatefile("${local.userdata_dir}/linux-userdata.yaml", {
    username      = coalesce(try(var.linux_instances.username, null), "")
    password_hash = coalesce(try(var.linux_instances.password_hash, null), "")
    extra         = coalesce(try(var.linux_instances.user_data, null), "")
  })

  windows_userdata = templatefile("${local.userdata_dir}/win-userdata.ps1", {
    username           = coalesce(try(var.windows_instances.username, null), "")
    password_to_change = coalesce(try(var.windows_instances.password_to_change, null), "")
    extra              = coalesce(try(var.windows_instances.user_data, null), "")
  })
}

resource "terraform_data" "linux_userdata" {
  input = local.linux_userdata
}

resource "terraform_data" "windows_userdata" {
  input = local.windows_userdata
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
      size  = try(var.linux_instances.disk.size, 32)
      type  = try(var.linux_instances.disk.type, "pd-ssd")
    }
  }

  network_interface {
    subnetwork = try(var.linux_instances.subnet_name, null)
    access_config {}
  }

  metadata = {
    user-data = local.linux_userdata
  }

  lifecycle {
    ignore_changes       = [metadata]
    replace_triggered_by = [terraform_data.linux_userdata]
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
      size  = try(var.windows_instances.disk.size, 50)
      type  = try(var.windows_instances.disk.type, "pd-ssd")
    }
  }

  network_interface {
    subnetwork = try(var.windows_instances.subnet_name, null)
  }

  metadata = {
    windows-startup-script-ps1 = local.windows_userdata
  }

  lifecycle {
    ignore_changes       = [metadata]
    replace_triggered_by = [terraform_data.windows_userdata]
  }

  labels = {
    environment = lookup(var.tags, "Environment", "dev")
    project     = lookup(var.tags, "Project", "stratus")
    os          = "windows"
  }
}
