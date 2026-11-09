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
- **Workload Identity Federation** — lets each app repo's GitHub Actions
  workflow authenticate to GCP with its own OIDC token. No service-account
  JSON key is ever generated or stored as a secret.
- **Required APIs** — enabled here (`apis.tf`) rather than assumed to
  already be on, so a fresh project can go straight to `terraform apply`.

## Keyless deploy (OIDC, no SSH keys, no service-account keys)

`workload_identity.tf` sets up:

- One Workload Identity Pool + OIDC provider for `github.com`, restricted to
  repos under `var.github_org`.
- **`ci-deploy-vm`** — the service account `restaurant-stream-backend` and
  `restaurant-stream-flink` workflows impersonate. Granted
  `roles/iap.tunnelResourceAccessor` + `roles/compute.osAdminLogin` only —
  enough to open an IAP SSH tunnel and run commands as an OS Login user, no
  SSH keypair stored anywhere.
- **`ci-deploy-firebase`** — the service account `restaurant-stream-ui`'s
  workflow impersonates, granted `roles/firebasehosting.admin` only.
- `network.tf`'s SSH firewall rule allows only Google's IAP range
  (`35.235.240.0/20`) — never a public source — and the VM has
  `enable-oslogin = TRUE`, so SSH keys are issued per-session, not stored.

Each app repo's workflow needs only two values from this module's outputs
(`terraform output workload_identity_provider` and the relevant
`ci_deploy_*_service_account`) — no secrets to rotate:

```yaml
- uses: google-github-actions/auth@v2
  with:
    workload_identity_provider: <output: workload_identity_provider>
    service_account: <output: ci_deploy_vm_service_account or ci_deploy_firebase_service_account>
- run: |
    gcloud compute ssh restaurant-stream-vm --zone <zone> --tunnel-through-iap \
      --command="cd /opt/app && docker compose pull && docker compose up -d"
```

Note: this repo's own deploy (applying Terraform changes) is still run
manually (`terraform apply` from your machine) — not yet wired to CI, since
giving a CI identity permission to change infrastructure is a bigger
decision than giving it permission to redeploy an app, and hasn't been
made yet.

## Why Terraform for everything

Nothing in this project is clicked together by hand in the GCP console —
every resource above is declared here so the whole environment can be torn
down and recreated from source.

## Layout

Single root module, no multi-env workspaces (one personal environment):

| File | Provisions |
|---|---|
| `apis.tf` | Enables the GCP APIs every other resource here needs |
| `compute.tf` | The VM + its static external IP, OS Login enabled |
| `network.tf` | Firewall rules — IAP-only SSH, backend port, Flink UI port |
| `pubsub.tf` | Input/output topics + their pull subscriptions |
| `iam.tf` | VM's own service account (Pub/Sub publisher + subscriber) |
| `workload_identity.tf` | WIF pool/provider + the two CI deploy service accounts (keyless GitHub Actions auth) |
| `firebase.tf` | Firebase project/web-app/hosting-site for the UI repo's own `firebase deploy` to target |
| `scripts/startup.sh` | VM startup script — installs Docker + Compose plugin, nothing app-specific (that's each app repo's own CD job) |

## Usage

```
cp terraform.tfvars.example terraform.tfvars   # fill in your project_id
terraform init
terraform plan
terraform apply
```

## Status

Scaffolded and `terraform validate`-clean. Not yet applied against a real
GCP project — needs a project ID with Compute Engine, Pub/Sub, and Firebase
APIs enabled before `terraform apply` will succeed.
