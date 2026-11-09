# restaurant-stream-infra

Terraform for the [restaurant-stream pipeline](https://github.com/7Chethan007/restaurant-stream-ui#readme) — the
only repo that touches GCP infrastructure. App repos (`ui`, `backend`,
`flink`) deploy *onto* what this repo provisions; they never create cloud
resources themselves.

## What this repo owns

- **GCE VM** — single instance running the backend + Flink job via Docker
  Compose (self-hosted, no Kubernetes).
- **Static external IP** — reserved and attached to the VM, so the backend
  has a stable public address for the UI to call.
- **Firewall rules** — open only the ports the backend/SSE and Flink UI
  actually need.
- **Pub/Sub topics** — `restaurant-queries` (input) and `restaurant-results`
  (output).
- **Service accounts / IAM** — scoped credentials for the VM to publish/
  subscribe to Pub/Sub, nothing broader.

## Why Terraform for everything

Nothing in this project is clicked together by hand in the GCP console —
every resource above is declared here so the whole environment can be torn
down and recreated from source.

## Status

Not yet written. Planned layout: a single root module (no multi-env
workspaces yet — this is one personal environment), `terraform.tfvars` for
project ID / region / machine type.
