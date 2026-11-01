GOPATH := $(shell go env GOPATH)
PKG := "github.com/example-org/ps-tag-non-posted-exceptions"
PRODUCER_DIR := "internal"
KAFKA_MODEL_DIR := "internal/kafka_models"
PKG_LIST := $(shell go list ${PKG}/...)
COMPONENT_PKG_TESTS := "github.com/example-org/ps-tag-non-posted-exceptions/tests/component"
UNIT_PKG_LIST := $(shell go list ${PKG}/... | grep -v "${COMPONENT_PKG_TESTS}")
COMPONENT_PKG_LIST := $(shell go list ${COMPONENT_PKG_TESTS}/...)

fmt:
	gofmt -w -s ${PKG_LIST}

unit-test:
	@go test -v ${UNIT_PKG_LIST}

component-test:
	@go test -v ${COMPONENT_PKG_LIST}

race:
	@go test -race ${UNIT_PKG_LIST}

benchmark:
	@go test -run="-" -bench=".*" ${UNIT_PKG_LIST}

vendor:
	@go mod vendor

init-govulncheck:
	@go install golang.org/x/vuln/cmd/govulncheck@latest

vul-check: init-govulncheck
	@govulncheck ${PKG_LIST}

go-vet:
	@go vet ${PKG_LIST}

init-gen-avro:
	@go install github.com/actgardner/gogen-avro/v10/cmd/...@latest

generate-avro-models: init-gen-avro
	mkdir -p ${KAFKA_MODEL_DIR}
	${GOPATH}/bin/gogen-avro -package kafka_models ${KAFKA_MODEL_DIR} ${PRODUCER_DIR}/*.avsc
	chmod -R +r ${KAFKA_MODEL_DIR}

test: unit-test benchmark race

compile:
	./build/compile.sh

install-linter:
	curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b ${GOPATH}/bin latest

lint:
	golangci-lint run -c .github/linters/.golangci.yml --verbose

mocks:
	CGO_ENABLED=0 go install github.com/vektra/mockery/v2@v2.37.1
	mockery
