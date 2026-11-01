#!/bin/bash

set -e

# Resolve script location regardless of caller's working directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Build image (only if needed) and run the tool
docker build -t sg-compare . >/dev/null 2>&1
docker run --rm \
    -e AWS_ACCESS_KEY_ID \
    -e AWS_SECRET_ACCESS_KEY \
    -e AWS_SESSION_TOKEN \
    -e AWS_REGION \
    -e AWS_PROFILE \
    -v ~/.aws:/root/.aws:ro \
    -v "${SCRIPT_DIR}:/app/utils/sg-compare:ro" \
    -v "${SCRIPT_DIR}/../../configurations/allowlists:/app/configurations/allowlists:ro" \
    sg-compare "$@"
