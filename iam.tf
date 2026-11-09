# Single service account for the VM: publish to the input topic's dead-letter
# path isn't needed, but it does both publish (results) and subscribe
# (queries) across the two topics, so one SA with both roles keeps this
# simple instead of minting one per direction.

resource "google_service_account" "vm" {
  account_id   = "restaurant-stream-vm"
  display_name = "restaurant-stream backend+Flink VM"
}

resource "google_project_iam_member" "vm_pubsub_publisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.vm.email}"
}

resource "google_project_iam_member" "vm_pubsub_subscriber" {
  project = var.project_id
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:${google_service_account.vm.email}"
}
