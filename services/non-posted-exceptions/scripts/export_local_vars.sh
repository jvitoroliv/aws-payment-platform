#!/bin/bash
# shellcheck disable=SC1000-SC2200

echo "Setting env vars for local docker usage"

# Set the docker-compose flags based on the architecture
if [[ $(uname -m) == "arm64" || $(uname -m) == "x86_64" ]]; then
  DOCKER_COMPOSE_FLAGS="-f docker-compose.yml -f docker-compose.local_test.yml -f docker-compose.m1.yml"
else
  DOCKER_COMPOSE_FLAGS="-f docker-compose.yml -f docker-compose.local_test.yml"
fi

export GOPRIVATE="github.com/example-org/*"
export DOCKER_COMPOSE_FLAGS
export ENVIRONMENT=docker
