#!/bin/bash
# shellcheck disable=SC1000-SC2200
set -e

# Resolve script location regardless of caller's working directory
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
. "$SCRIPT_DIR/export_local_vars.sh"
cd "$SCRIPT_DIR/.."

echo "Bringing up builder and non-posted-exception-producer dependencies"

docker volume create mongodata
docker compose --profile local down
docker compose --profile local $DOCKER_COMPOSE_FLAGS up -d mongo-database kafka karapace-registry kafka-ui zookeeper

echo "Building non-posted-exception-producer binary"
docker compose $DOCKER_COMPOSE_FLAGS run --rm builder bash -c 'make compile'

make generate-avro-models

echo "Starting non-posted-exception-producer"
docker compose $DOCKER_COMPOSE_FLAGS run --build exception-producer
