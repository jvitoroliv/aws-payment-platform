#!/usr/bin/env sh

# compile.sh
# compile shell script


set -ex

GOBIN=/go/src/github.com/example-org/ps-tag-non-posted-exceptions/build go install -gcflags="all=-N -l" \
  github.com/example-org/ps-tag-non-posted-exceptions/cmd/exception-producer
