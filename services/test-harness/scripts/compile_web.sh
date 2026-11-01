#!/bin/bash
set -e

echo "::group::Building web static files with Docker"
docker compose build web-build

# Create output directory and copy the built files from the container to the host
mkdir -p out/web
docker create --name web-build-temp registry.example.io/docker-nonprod/app/ps-tag-web-build:${VERSION:-latest}
docker cp web-build-temp:/app/out/web out/web/
docker rm web-build-temp

echo "::endgroup::"
echo
