#!/bin/bash

#!/bin/bash
# unit_test_build_version.sh
# build pipeline
# Usage: see --help or README.md


# Resolve script location regardless of caller's working directory
SCRIPT_DIR="$( cd "${BASH_SOURCE[0]%/*}" || exit; pwd )"
cd "$SCRIPT_DIR" || exit 1

docker-compose run --rm builder bash -c "make test"
docker-compose down