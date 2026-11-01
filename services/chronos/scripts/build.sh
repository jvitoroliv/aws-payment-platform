#!/bin/bash

# build.sh
# build pipeline


if [[ -z $1 ]]; then
    echo "No output dir provided"
    usage
    exit 2
fi

# Project Root
ROOT_DIR="$( cd "${BASH_SOURCE[0]%/*}/.." || exit; pwd )"
cd "$ROOT_DIR" || exit

# Build the lambda artifacts
lambdas=( "billable-entity-cycling" "aging-event" "api" )

for i in "${lambdas[@]}"
do
  echo "Building $i lambda artifact..."
  GOOS=linux go build -o "$1/$i/bootstrap" "$ROOT_DIR/lambda/$i" || exit
done

echo "Done building lambda artifacts"