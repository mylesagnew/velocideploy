terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.80.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = "us-central1" # Change to your preferred GCP region
}

resource "tls_private_key" "tls-velo" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "google_compute_network" "vpc_network" {
  name                    = "${var.case_name}-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.case_name}-subnet"
  network       = google_compute_network.vpc_network.id
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
}

resource "google_compute_firewall" "default-ssh" {
  name    = "${var.case_name}-allow-ssh"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["${chomp(data.http.my_ip.response_body)}/32"]
}

resource "google_compute_firewall" "allow-frontend" {
  name    = "${var.case_name}-allow-frontend"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["8000"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow-gui" {
  name    = "${var.case_name}-allow-gui"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["8889"]
  }

  source_ranges = ["${chomp(data.http.my_ip.response_body)}/32"]
}

resource "google_compute_address" "public_ip" {
  name   = "${var.case_name}-ip"
  region = var.region
}

resource "google_compute_instance" "vm_instance" {
  name         = "${var.case_name}-instance"
  machine_type = "n1-standard-2" # Adjust to desired instance type
  zone         = "us-central1-a" # Change to your preferred GCP zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
      size  = 1024
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.subnet.id

    access_config {
      nat_ip = google_compute_address.public_ip.address
    }
  }

  metadata = {
    ssh-keys = "google:${tls_private_key.tls-velo.public_key_openssh}"
  }

  tags = ["${var.case_name}"]

  metadata_startup_script = <<-EOT
    #!/bin/bash
    echo "Instance has started up."
  EOT
}

resource "local_file" "private_key" {
  content        = tls_private_key.tls-velo.private_key_pem
  filename       = "${var.case_name}.pem"
  file_permission = "0400"
}

resource "local_file" "ansible-inventory" {
  filename = "./inventory"
  content     = <<EOF
[ubuntu]
${google_compute_address.public_ip.address}

[ubuntu:vars]
ansible_user=google
ansible_ssh_private_key_file=./${var.case_name}.pem
EOF
}

resource "null_resource" "ssh_command" {
  provisioner "local-exec" {
    command = "echo $'\nssh -i ${var.case_name}.pem google@${google_compute_address.public_ip.address}' >> velociraptor.sh"
  }
}
