#!/usr/bin/env bash
set -euo pipefail

# Run this once, by hand, with your own gcloud credentials. This is NOT
# `terraform apply` — it creates only the trust anchor that lets GitHub
# Actions authenticate at all. Nothing can create that trust relationship
# except an already-authenticated human (chicken-and-egg), so this one
# script is the entire manual footprint of this project's setup. Every
# other resource — the VM, Pub/Sub, Firebase, everything in the Terraform
# plan — is created by GitHub Actions after this runs, never by you running
# `terraform apply` locally.
#
# Usage: PROJECT_ID=restaurant-stream-10404 GITHUB_ORG=7Chethan007 ./bootstrap.sh

PROJECT_ID="${PROJECT_ID:?set PROJECT_ID}"
GITHUB_ORG="${GITHUB_ORG:?set GITHUB_ORG}"
GITHUB_REPO="restaurant-stream-infra"
STATE_BUCKET="${PROJECT_ID}-tfstate"

echo "== Enabling APIs needed for bootstrap itself =="
gcloud services enable \
  iam.googleapis.com \
  iamcredentials.googleapis.com \
  sts.googleapis.com \
  cloudresourcemanager.googleapis.com \
  storage.googleapis.com \
  --project "$PROJECT_ID"

echo "== Creating GCS bucket for Terraform state: $STATE_BUCKET =="
gcloud storage buckets create "gs://${STATE_BUCKET}" \
  --project "$PROJECT_ID" \
  --location "$(echo "${REGION:-us-central1}")" \
  --uniform-bucket-level-access
gcloud storage buckets update "gs://${STATE_BUCKET}" --versioning

echo "== Creating Workload Identity Pool + OIDC provider for GitHub Actions =="
gcloud iam workload-identity-pools create github-actions-pool \
  --project "$PROJECT_ID" \
  --location global \
  --display-name "GitHub Actions"

gcloud iam workload-identity-pools providers create-oidc github-actions-provider \
  --project "$PROJECT_ID" \
  --location global \
  --workload-identity-pool github-actions-pool \
  --display-name "GitHub Actions OIDC" \
  --attribute-mapping "google.subject=assertion.sub,attribute.repository=assertion.repository" \
  --attribute-condition "assertion.repository_owner == \"${GITHUB_ORG}\"" \
  --issuer-uri "https://token.actions.githubusercontent.com"

echo "== Creating the Terraform-CI service account =="
gcloud iam service-accounts create ci-terraform \
  --project "$PROJECT_ID" \
  --display-name "CI: apply Terraform for restaurant-stream-infra"

CI_TERRAFORM_SA="ci-terraform@${PROJECT_ID}.iam.gserviceaccount.com"
PROJECT_NUMBER="$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')"
POOL_RESOURCE="projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/github-actions-pool"

echo "== Letting only restaurant-stream-infra's workflow impersonate it =="
gcloud iam service-accounts add-iam-policy-binding "$CI_TERRAFORM_SA" \
  --project "$PROJECT_ID" \
  --role "roles/iam.workloadIdentityUser" \
  --member "principalSet://iam.googleapis.com/${POOL_RESOURCE}/attribute.repository/${GITHUB_ORG}/${GITHUB_REPO}"

echo "== Granting ci-terraform the roles it needs to manage this project's resources =="
for role in \
  roles/compute.admin \
  roles/pubsub.admin \
  roles/iam.serviceAccountAdmin \
  roles/resourcemanager.projectIamAdmin \
  roles/serviceusage.serviceUsageAdmin \
  roles/firebase.admin \
  roles/storage.admin
do
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member "serviceAccount:${CI_TERRAFORM_SA}" \
    --role "$role" \
    --condition=None
done

echo
echo "Done. Values for the GitHub Actions workflows (not secret, already in"
echo "the committed workflow YAML, shown here only to confirm they match):"
echo "  workload_identity_provider: ${POOL_RESOURCE}/providers/github-actions-provider"
echo "  service_account:            ${CI_TERRAFORM_SA}"
echo "  state bucket:               ${STATE_BUCKET}"
