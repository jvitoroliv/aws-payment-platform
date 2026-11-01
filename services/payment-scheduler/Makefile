PKG := "github.com/example-org/ps-tag-payment-service"
PKG_LIST := $(shell go list ${PKG}/...)
INTEGRATION_PKG_LIST := "./test/..."
UNIT_PKG_LIST := $(shell go list ${PKG}/... | grep -v "${INTEGRATION_PKG_LIST}")
GOPATH := $(shell go env GOPATH)

fmt:
	gofmt -w -s ${PKG_LIST}

init-checker:
	@curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b ${GOPATH}/bin latest
	@go install golang.org/x/tools/cmd/goimports@latest

unit-test:
	@go test -v -shuffle=on ${UNIT_PKG_LIST}

integration-test:
	@go test -v -shuffle=on ${INTEGRATION_PKG_LIST}

race:
	@CGO_ENABLED=1 go test -race ${UNIT_PKG_LIST}

benchmark:
	@go test -run="-" -bench=".*" ${UNIT_PKG_LIST}

lint:
	@golangci-lint run --timeout 5m -D staticcheck internal/...
	@golangci-lint run --timeout 5m -D staticcheck cmd/...

vendor:
	@go mod vendor

imports:
	@goimports -l -w $(shell find . -type f -name '*.go' -not -path "./vendor/*" -not -path "./.mod/*")


check: init-checker lint imports
test: unit-test benchmark race