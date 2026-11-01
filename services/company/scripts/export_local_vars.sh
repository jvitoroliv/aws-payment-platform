#!/bin/bash

# strict bash mode
set -eu -o pipefail

echo "Setting env vars for local docker usage"

# Set the docker-compose flags based on the architecture
DOCKER_COMPOSE_FLAGS="-f docker-compose.yml -f docker-compose.local_test.yml"
if [[ "$(uname -m)" == "arm64" ]]; then
  DOCKER_COMPOSE_FLAGS="$DOCKER_COMPOSE_FLAGS -f docker-compose.m1.yml"
fi

export GOPRIVATE="github.com/example-org/*"
export DOCKER_COMPOSE_FLAGS
export ENVIRONMENT=docker
