#!/bin/bash

# build_artifactory.sh
# build pipeline

# Strict mode: exit on error (-e), undefined var (-u), pipe failure (-o pipefail)
set -euo pipefail

VERSION=$1
if [[ -z $VERSION ]]; then
    echo "No Version provided"
    exit 2
fi

# Project Root
ROOT_DIR="$( cd "${BASH_SOURCE[0]%/*}/.." && pwd)"
test -z "$ROOT_DIR" && echo "Failed to find project root" && exit 1

cd "$ROOT_DIR"
rm -rf dist-files
mkdir -p dist-files

# Build the lambda artifacts
lambdas=( "billable-entity-cycling" "aging-event" "api")

for i in "${lambdas[@]}"
do
  echo "Building $i lambda artifact..."
  GO111MODULE=off GOOS=linux go build -o "$ROOT_DIR/bootstrap" "$ROOT_DIR/lambda/$i"
  zip -j "$ROOT_DIR/$i.zip" "$ROOT_DIR/bootstrap"
  chmod -x "$ROOT_DIR/$i.zip"
  echo "Moving $i to release dir: $ROOT_DIR/dist-files/$i-$VERSION.zip"
  rm "$ROOT_DIR/bootstrap"
  mv "$ROOT_DIR/$i.zip" "$ROOT_DIR/dist-files/$i-$VERSION.zip"
done

echo "Done building lambda artifacts"

