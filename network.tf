# ponytail: using the project's default VPC/subnet rather than provisioning
# a custom network — one VM, no multi-tier isolation need yet.

resource "google_compute_firewall" "allow_ssh_iap" {
  name    = "restaurant-stream-allow-ssh-iap"
  network = "default"
  # Google's fixed range for IAP TCP forwarding — never a public source.
  # Deploy workflows reach the VM only via `gcloud compute ssh
  # --tunnel-through-iap`, authenticated through Workload Identity
  # Federation (see workload_identity.tf), never a direct public SSH port.
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["restaurant-stream-vm"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_firewall" "allow_backend" {
  name          = "restaurant-stream-allow-backend"
  network       = "default"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["restaurant-stream-vm"]

  allow {
    protocol = "tcp"
    ports    = [tostring(var.backend_port)]
  }
}

resource "google_compute_firewall" "allow_flink_ui" {
  name          = "restaurant-stream-allow-flink-ui"
  network       = "default"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["restaurant-stream-vm"]

  allow {
    protocol = "tcp"
    ports    = [tostring(var.flink_ui_port)]
  }
}
