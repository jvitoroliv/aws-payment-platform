#!/bin/bash

set -e

# Resolve script location regardless of caller's working directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Run the tool directly in the Python Docker container.
# Can use add a Dockerfile for a custom image if we ever add other dependencies.
docker run --rm \
    -v "${SCRIPT_DIR}:/app/utils/update-splunk-cidrs:ro" \
    -v "${SCRIPT_DIR}/../../configurations/allowlists:/app/configurations/allowlists:ro" \
    -v "${SCRIPT_DIR}/../../splunk:/app/splunk:rw" \
    python:3.13-slim "/app/utils/update-splunk-cidrs/update_splunk_cidrs.py"
