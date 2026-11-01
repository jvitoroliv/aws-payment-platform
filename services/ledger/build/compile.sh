#!/usr/bin/env sh

#!/bin/bash
# compile.sh
# compile shell script
# Usage: see --help or README.md


set -ex

GOBIN=/go/src/github.com/example-org/ps-tag-ledger/build go install -gcflags="all=-N -l" \
  github.com/example-org/ps-tag-ledger/cmd/ledger-producer
