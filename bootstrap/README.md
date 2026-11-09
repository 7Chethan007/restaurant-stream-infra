# bootstrap/

The one piece of this project that isn't managed by Terraform, and isn't
applied by GitHub Actions.

## Why this exists

GitHub Actions authenticates to GCP via Workload Identity Federation (OIDC)
instead of a stored key — see `../workload_identity.tf`. But WIF itself
needs a trust relationship (a Workload Identity Pool + OIDC provider)
to exist before any GitHub Actions run can authenticate at all. Nothing
running *inside* that not-yet-authenticated CI can be what creates the
thing that lets it authenticate — that's circular. So this one piece has
to be created by an already-authenticated human, once, outside both
Terraform state and CI.

Everything downstream of this — the VM, Pub/Sub, Firebase, the per-repo
deploy service accounts — is in `.tf` files and gets applied by GitHub
Actions (`.github/workflows/terraform-apply.yml`) after a PR merges. This
script is the entire manual footprint; nothing else in this project is
clicked together by hand or run locally.

## Run it once

```
export PROJECT_ID=restaurant-stream-10404
export GITHUB_ORG=7Chethan007
./bootstrap.sh
```

Creates:
- A GCS bucket (`${PROJECT_ID}-tfstate`) for Terraform state
- The `github-actions-pool` Workload Identity Pool + OIDC provider
- A `ci-terraform` service account, scoped so only `restaurant-stream-infra`'s
  own workflow can impersonate it, with the roles Terraform needs to manage
  this project's resources (compute, Pub/Sub, IAM, Firebase, API enablement)

## After running it

Set two GitHub Actions repository variables (not secrets — these values
aren't sensitive, they're public resource names) on `restaurant-stream-infra`:

| Variable | Value | Where it came from |
|---|---|---|
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | printed at the end of the script | `projects/<number>/locations/global/workloadIdentityPools/github-actions-pool/providers/github-actions-provider` |
| `GCP_CI_SERVICE_ACCOUNT` | printed at the end of the script | `ci-terraform@<project_id>.iam.gserviceaccount.com` |
| `TF_STATE_BUCKET` | printed at the end of the script | `<project_id>-tfstate` |

The workflows in `.github/workflows/` read these — nothing is hardcoded to
a specific project ID in the YAML.
