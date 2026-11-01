#!/usr/bin/env bash

# initial_migration.sh
# initial_migration shell script


terraform state mv -state-out='terraform.tfstate' 'module.mock-service'
terraform state mv -state-out='terraform.tfstate' 'module.iam.'