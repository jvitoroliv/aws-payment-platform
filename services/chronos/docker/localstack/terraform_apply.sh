#!/usr/bin/env sh

# terraform_apply.sh
# terraform_apply shell script


terraform -chdir=/src/terraform/env/local/us-east-1 init -lock=false -reconfigure
terraform -chdir=/src/terraform/env/local/us-east-1 plan -lock=false -var aws_endpoint=host.docker.internal -var="subnet_ids=[$TF_VAR_local_subnet_id]"
terraform -chdir=/src/terraform/env/local/us-east-1 apply -lock=false -var aws_endpoint=host.docker.internal -auto-approve -var="subnet_ids=[$TF_VAR_local_subnet_id]"

rm -rf /src/terraform/env/local/us-east-1/.terraform/modules
rm -f /src/terraform/env/local/us-east-1/.terraform/terraform.tfstate
rm -f /src/terraform/env/local/us-east-1/.terraform.lock.hcl
rm -f /src/terraform/env/local/us-east-1/terraform.tfstate
rm -f /src/terraform/env/local/us-east-1/terraform.tfstate.backup