#!/bin/bash

# place_lambdas_in_s3.sh
# S3 bucket configuration

# Strict mode: exit on error (-e), undefined var (-u), pipe failure (-o pipefail)
set -euo pipefail

place_lambdas_in_s3() {
  VERSION=$1
  ENVIRONMENT=$2

  if [[ -z $VERSION ]]; then
    echo "VERSION must be specified"
    exit 1
  fi

  if [[ -z $ENVIRONMENT ]]; then
    echo "ENVIRONMENT must be specified"
    exit 1
  fi

  EASTBUCKET="${ENVIRONMENT}-us-east-1-app-artifacts-lambda"
  WESTBUCKET="${ENVIRONMENT}-us-west-2-app-artifacts-lambda"
  
  echo "pushing lambdas to S3: ${EASTBUCKET}, ${WESTBUCKET}"

  lambdas=("billable-entity-cycling" "aging-event" "api")

  for lambda in "${lambdas[@]}"; do
    echo "Pulling ${lambda} lambda artifact..."

    curl -L \
      --user "${ARTIFACTORY_USER}:${ARTIFACTORY_PASSWORD}" \
      "${ARTIFACTORY_ENDPOINT}/chronos/${VERSION}/dist-files/$lambda-${VERSION}.zip" \
      -o "${lambda}.zip"

    echo "Pushing ${lambda} lambda to S3..."
    aws s3 cp "${lambda}.zip" "s3://${EASTBUCKET}/${VERSION}/chronos/${lambda}.zip" || exit
    aws s3 cp "${lambda}.zip" "s3://${WESTBUCKET}/${VERSION}/chronos/${lambda}.zip" || exit
    rm "${lambda}.zip"
  done
}

place_lambdas_in_s3 "$1" "$2"