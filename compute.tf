# Single VM for both the FastAPI backend and the Flink job (JobManager +
# TaskManager), run as separate containers via Docker Compose. Decided
# against splitting these across two VMs — no load reason to, and it halves
# the Terraform/ops surface for a personal project.

resource "google_compute_address" "vm_static_ip" {
  name   = "restaurant-stream-ip"
  region = var.region
}

resource "google_compute_instance" "vm" {
  name         = "restaurant-stream-vm"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["restaurant-stream-vm"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 30
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.vm_static_ip.address
    }
  }

  service_account {
    email  = google_service_account.vm.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    # OS Login issues short-lived SSH keys per authenticated identity
    # instead of a stored keypair — pairs with the IAP-only firewall rule
    # and the ci-deploy-vm service account in workload_identity.tf.
    enable-oslogin = "TRUE"
  }

  metadata_startup_script = file("${path.module}/scripts/startup.sh")

  depends_on = [google_project_service.apis]
}
