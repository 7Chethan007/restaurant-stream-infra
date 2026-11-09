resource "google_pubsub_topic" "input" {
  name = "restaurant-queries"

  depends_on = [google_project_service.apis]
}

resource "google_pubsub_topic" "output" {
  name = "restaurant-results"

  depends_on = [google_project_service.apis]
}

# Pull subscriptions: both consumers (Flink job, backend SSE server) poll
# rather than needing a push endpoint exposed to Pub/Sub.

resource "google_pubsub_subscription" "input_flink" {
  name  = "restaurant-queries-flink-sub"
  topic = google_pubsub_topic.input.name
}

resource "google_pubsub_subscription" "output_backend" {
  name  = "restaurant-results-backend-sub"
  topic = google_pubsub_topic.output.name
}
