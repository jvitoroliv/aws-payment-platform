GOPATH := $(shell go env GOPATH)
PKG := "github.com/example-org/ps-tag-ledger"
PKG_LIST := $(shell go list ${PKG}/...)
COMPONENT_PKG_TESTS := "github.com/example-org/ps-tag-ledger/tests/component"
INTEGRATION_PKG_TESTS := "github.com/example-org/ps-tag-ledger/tests/integration"
UNIT_PKG_LIST := $(shell go list ${PKG}/... | grep -v "${COMPONENT_PKG_TESTS}" | grep -v "${INTEGRATION_PKG_TESTS}")
COMPONENT_PKG_LIST := $(shell go list ${COMPONENT_PKG_TESTS}/...)
INTEGRATION_PKG_LIST := $(shell go list ${INTEGRATION_PKG_TESTS}/...)

fmt:
	gofmt -w -s ${PKG_LIST}

version:
	go version

init-checker:
	curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin v1.64.8

unit-test:
	@go test -v ${UNIT_PKG_LIST}

export TESTCONTAINERS_HUB_IMAGE_NAME_PREFIX=registry.example.io/tag-docker-prod-virtual-us
component-test:
	@go test -v ${COMPONENT_PKG_LIST}

integration-test:
	@go test -v ${INTEGRATION_PKG_LIST}

race:
	@go test -race ${UNIT_PKG_LIST}

vendor:
	@go mod vendor

init-govulncheck:
	@go install golang.org/x/vuln/cmd/govulncheck@latest

vul-check:
	@govulncheck ${PKG_LIST}

go-vet:
	@go vet ${PKG_LIST}

check: init-checker init-govulncheck lint vul-check

test: unit-test component-test race

compile:
	./build/compile.sh

install-linter:
	curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b ${GOPATH}/bin v1.64.8

lint:
	golangci-lint run -c .github/linters/.golangci.json --verbose


