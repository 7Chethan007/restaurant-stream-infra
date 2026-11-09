#!/usr/bin/env bash
set -euo pipefail

# Creates the two Kinesis streams against the local Floci emulator.
# Run after `docker compose up -d` in this repo.

export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

for stream in restaurant-queries restaurant-results; do
  aws kinesis create-stream --stream-name "$stream" --shard-count 1 \
    || echo "  ($stream already exists, skipping)"
done

aws kinesis list-streams
