# Provisions the Firebase project/app/site that restaurant-stream-ui's own
# CD workflow (`firebase deploy`) pushes the built frontend to. Terraform
# only owns the resource, not the deploy — same split as the VM.

resource "google_firebase_project" "default" {
  provider = google-beta
  project  = var.project_id

  depends_on = [google_project_service.apis]
}

resource "google_firebase_web_app" "ui" {
  provider     = google-beta
  project      = var.project_id
  display_name = "restaurant-stream-ui"

  depends_on = [google_firebase_project.default]
}

resource "google_firebase_hosting_site" "ui" {
  provider = google-beta
  project  = var.project_id
  site_id  = "${var.project_id}-ui"

  depends_on = [google_firebase_project.default]
}
