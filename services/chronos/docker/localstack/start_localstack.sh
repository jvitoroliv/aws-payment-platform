#!/bin/bash

#!/bin/bash
# start_localstack.sh
# local value computations
# Usage: see --help or README.md


export CHRONOS_ENV=local

set +x -e

echo "Checking for JQ"
if [[ $(command -v jq) == "" ]]; then
  echo "jq isn't installed but is required for this script "
  exit 2
fi

echo "Checking for docker"
docker info || exit

ROOT_DIR="$( cd "${BASH_SOURCE[0]%/*}/../.." || exit; pwd )"
cd "$ROOT_DIR/docker/localstack"


TMPDIR=/private$TMPDIR docker compose up localstack builder aspire-dashboard -d

# Function to check if the container is available
check_container() {
    # Loop until curl command returns success (HTTP 200 OK)
    until curl -s -o /dev/null -I -w "%{http_code}" http://localhost:4566 | grep -q "200"; do
        echo "Waiting for localstack container to be available..."
        sleep 1
    done
    echo "Container localstack is available!"
}

# Call the function to check if the container is available
check_container


#Mock S3
echo "Mock S3"
aws --endpoint-url="http://localhost:4566" s3 mb "s3://local-us-east-1-app-artifacts-lambda"

# Build the lambda artifacts
lambdas=( "billable-entity-cycling" "aging-event" "api" )
for i in "${lambdas[@]}"
do
  echo "Building $i lambda artifact..."
  GOOS=linux go build -o "bootstrap" "../../lambda/$i" || exit
  zip -j $i.zip bootstrap
  aws --endpoint-url="http://localhost:4566" s3 cp "./$i.zip" "s3://local-us-east-1-app-artifacts-lambda/chronos/$i.zip"
  rm $i.zip
  rm bootstrap
done

# Create the VPC and capture the output JSON
vpc_output=$(aws --endpoint-url="http://localhost:4566" ec2 create-vpc --cidr-block 10.0.0.0/16)

# Extract the VPC ID from the JSON output
vpc_id=$(echo $vpc_output | jq -r '.Vpc.VpcId')

# Create the Subnet and extract its id
SUBNET_ID=`aws --endpoint-url="http://localhost:4566" ec2 create-subnet --vpc-id $vpc_id --cidr-block 10.0.1.0/24 --availability-zone us-east-1a --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=MySubnet}]' --query "Subnet.SubnetId" --output text`

# Create TF local_subnet_id env variable to inject the subnet id into terraform
export TF_VAR_local_subnet_id="\"$SUBNET_ID\""

echo -e "Subnet ID : $SUBNET_ID"

echo "running terraform"
docker compose run --rm tf_chronos

echo "getting API ID"
API_ID="$(aws --endpoint-url=http://localhost:4566 apigateway get-rest-apis | jq '.items[0].id' | tr -d '"')"

echo "Chronos deployed to local stack"
echo "here are some useful commands:"
echo -e "List Lambda functions: aws --endpoint-url=http://localhost:4566 lambda list-functions"
echo -e "Invoke API: curl http://localhost:4566/restapis/$API_ID/local/_user_request_/"
