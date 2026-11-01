#!/usr/bin/env sh

# compile.sh
# compile shell script


set -ex

export GOBIN=/go/src/github.com/example-org/ps-tag-payment-service/build

go install -gcflags="all=-N -l" -buildvcs=false \
  github.com/example-org/ps-tag-payment-service/cmd/payment-scheduler-api

CGO_ENABLED=0 go install github.com/go-delve/delve/cmd/dlv@latest