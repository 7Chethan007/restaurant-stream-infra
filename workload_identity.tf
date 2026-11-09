# Keyless CI/CD: GitHub Actions authenticates with its own OIDC token,
# exchanged for short-lived GCP credentials. No service-account JSON key is
# ever generated or stored as a GitHub secret.
#
# The pool + provider themselves are NOT created here — they're the trust
# anchor that lets GitHub Actions authenticate to run Terraform at all, so
# nothing that depends on them (including this apply) can be what creates
# them (chicken-and-egg). bootstrap/bootstrap.sh creates them once, by hand,
# outside Terraform state. Everything downstream of that trust anchor
# (these service accounts, their bindings, and every other resource in this
# repo) IS Terraform-managed and applied by CI. See bootstrap/README.md.

data "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "github-actions-pool"
}

data "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = data.google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-actions-provider"
}

# --- VM deploy (backend + flink repos share one target VM, so one SA) ---

resource "google_service_account" "ci_deploy_vm" {
  account_id   = "ci-deploy-vm"
  display_name = "CI: deploy backend+flink to restaurant-stream-vm"
}

resource "google_service_account_iam_member" "ci_deploy_vm_wif" {
  for_each = toset(["restaurant-stream-backend", "restaurant-stream-flink"])

  service_account_id = google_service_account.ci_deploy_vm.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${data.google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_org}/${each.value}"
}

# IAP lets the workflow open an SSH tunnel without the VM having a public
# SSH surface; OS Login issues ephemeral keys per-session instead of a
# stored keypair.
resource "google_project_iam_member" "ci_deploy_vm_iap" {
  project = var.project_id
  role    = "roles/iap.tunnelResourceAccessor"
  member  = "serviceAccount:${google_service_account.ci_deploy_vm.email}"
}

resource "google_project_iam_member" "ci_deploy_vm_oslogin" {
  project = var.project_id
  role    = "roles/compute.osAdminLogin"
  member  = "serviceAccount:${google_service_account.ci_deploy_vm.email}"
}

# --- Firebase Hosting deploy (ui repo only) ---

resource "google_service_account" "ci_deploy_firebase" {
  account_id   = "ci-deploy-firebase"
  display_name = "CI: deploy restaurant-stream-ui to Firebase Hosting"
}

resource "google_service_account_iam_member" "ci_deploy_firebase_wif" {
  service_account_id = google_service_account.ci_deploy_firebase.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${data.google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_org}/restaurant-stream-ui"
}

resource "google_project_iam_member" "ci_deploy_firebase_role" {
  project = var.project_id
  role    = "roles/firebasehosting.admin"
  member  = "serviceAccount:${google_service_account.ci_deploy_firebase.email}"
}
