output "vm_static_ip" {
  description = "Public IP for the backend (API + SSE) and Flink UI. UI repo's CD and the browser both target this."
  value       = google_compute_address.vm_static_ip.address
}

output "pubsub_input_topic" {
  value = google_pubsub_topic.input.name
}

output "pubsub_output_topic" {
  value = google_pubsub_topic.output.name
}

output "vm_service_account_email" {
  value = google_service_account.vm.email
}

output "firebase_hosting_site_id" {
  value = google_firebase_hosting_site.ui.site_id
}

output "firebase_web_app_id" {
  value = google_firebase_web_app.ui.app_id
}

# --- Values each app repo's GitHub Actions workflow needs for
# google-github-actions/auth@v2 (workload_identity_provider + service_account
# inputs) — no secrets, no keys, just these two strings per repo. ---

output "workload_identity_provider" {
  description = "Full resource name for google-github-actions/auth's workload_identity_provider input (same value for every repo)"
  value       = data.google_iam_workload_identity_pool_provider.github.name
}

output "ci_deploy_vm_service_account" {
  description = "Service account email restaurant-stream-backend and restaurant-stream-flink workflows impersonate to SSH-deploy (via IAP) to the VM"
  value       = google_service_account.ci_deploy_vm.email
}

output "ci_deploy_firebase_service_account" {
  description = "Service account email restaurant-stream-ui's workflow impersonates to run firebase deploy"
  value       = google_service_account.ci_deploy_firebase.email
}
