#!/bin/bash

ROOT_DIR="$( cd "${BASH_SOURCE[0]%/*}/../.." || exit; pwd )"
cd "$ROOT_DIR/docker/localstack"

docker compose down --remove-orphans --rmi local --volumes

#cleanup
rm -f ../../terraform/env/local/us-east-1/terraform.tfstate
rm -f ../../terraform/env/local/us-east-1/.terraform/terraform.tfstate
rm -f ../../terraform/env/local/us-east-1/.terraform.lock.hcl
rm -f ../../terraform/env/local/us-east-1/terraform.tfstate
rm -f ../../terraform/env/local/us-east-1/terraform.tfstate.backup
rm -f ../../terraform/env/local/us-east-1/.terraform.tfstate.lock.info
