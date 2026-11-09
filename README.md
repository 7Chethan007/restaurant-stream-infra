# restaurant-stream-infra

Local environment for the [restaurant-stream pipeline](https://github.com/7Chethan007/restaurant-stream-ui#readme) — the
only repo that owns the shared "cloud" layer. App repos (`ui`, `backend`,
`flink`) connect to what this repo starts; they never define it themselves.

## Why local instead of GCP

This project started on GCP (self-hosted Flink on a GCE VM, Pub/Sub,
Firebase Hosting, Terraform, keyless CI/CD via Workload Identity
Federation — see this repo's closed PR #1 for that version). It moved off
GCP after an unrelated billing-account issue made that path impractical for
a personal project with no budget. See the root workspace's `README.md` in
`flink_exp/` for the full story if curious — nothing below depends on it.

## What this repo owns

- **[Floci](https://floci.io)** — an open-source local AWS service emulator
  (same category as LocalStack). Runs as a single Docker container on port
  `4566`, speaks real AWS wire protocols, so the AWS CLI/SDK work against it
  unmodified by just pointing `AWS_ENDPOINT_URL` at `localhost:4566`.
- **Two Kinesis streams** — `restaurant-queries` (input) and
  `restaurant-results` (output), created by `scripts/create-streams.sh`.
  Kinesis instead of SQS/SNS because Flink has an **official** Kinesis
  connector — no custom source function needed, unlike the GCP Pub/Sub
  version required.
- **The shared Docker network** (`restaurant-stream-net`) that
  `restaurant-stream-backend` and `restaurant-stream-flink` join from their
  own `docker-compose.yml` files to reach Floci at `floci:4566`.

Nothing here deploys anywhere — there's no cloud account, no billing, no
CI/CD for infrastructure. `docker compose up` is the whole deploy story.

## Usage

```
docker compose up -d
./scripts/create-streams.sh
```

Then start `restaurant-stream-backend` and `restaurant-stream-flink`
(each from their own repo) — they join `restaurant-stream-net` and talk to
Floci directly.

## Status

Scaffolded, not yet run end-to-end. Next: get the backend publishing a
record to `restaurant-queries` and confirm it shows up via
`aws kinesis get-records`.
