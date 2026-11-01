PKG := "github.com/example-org/ps-tag-company"
PKG_LIST := $(shell go list ${PKG}/...)
INTEGRATION_PKG_LIST := "github.com/example-org/ps-tag-company/tests"
UNIT_PKG_LIST := $(shell go list ${PKG}/... | grep -v "${INTEGRATION_PKG_LIST}")

fmt:
	gofmt -w -s ${PKG_LIST}

init-checker:
	@go install honnef.co/go/tools/cmd/staticcheck@latest

unit-test:
	@go test -v ${UNIT_PKG_LIST} -count=1

integration-test:
	go test -v ${INTEGRATION_PKG_LIST} -count=1

race:
	@go test -race ${UNIT_PKG_LIST}

benchmark:
	@go test -run="-" -bench=".*" ${UNIT_PKG_LIST}

lint:
	@staticcheck ${PKG_LIST}

vendor:
	@go mod vendor

init-govulncheck:
	@go install golang.org/x/vuln/cmd/govulncheck@latest

vul-check:
	@govulncheck ${PKG_LIST}

go-vet:
	@go vet ${PKG_LIST}

init-gen-avro:
	@go install github.com/actgardner/gogen-avro/v10/cmd/...@latest

generate-avro-models: init-gen-avro
	rm -f internal/kafka_models/*.go
	@go generate ./...

check: init-checker init-govulncheck lint vul-check
test: unit-test benchmark race

company-producer:
	go install $(GO_ARGS) github.com/example-org/ps-tag-company/cmd/company-producer

.PHONY: fmt init-checker unit-test integration-test race benchmark lint vendor init-govulncheck vul-check go-vet init-gen-avro generate-avro-models check test company-producer
