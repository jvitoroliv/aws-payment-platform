#!/bin/bash
# shellcheck disable=SC1000-SC2200
# strict bash mode
set -eu -o pipefail

# Resolve script location regardless of caller's working directory
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. "$SCRIPT_DIR/export_local_vars.sh"
cd "$SCRIPT_DIR/.."

go mod vendor
docker volume create mongodata
docker compose --profile local down
docker compose --profile local $DOCKER_COMPOSE_FLAGS up --build

# Uncomment the following lines to insert test data and reset the publishing status.
# docker compose exec mongo-database mongo mock-service reset-companyledger-publish-status.js