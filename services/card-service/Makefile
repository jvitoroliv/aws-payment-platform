PKG := "github.com/example-org/microservice-card-service"
PKG_LIST := $(shell go list ${PKG}/...)
INTEGRATION_PKG_LIST := "./test/integration/..."
COMPONENT_PKG_LIST := "./test/component/..."
UNIT_PKG_LIST := $(shell go list ${PKG}/... | grep -v "./test/...")
GOPATH := $(shell go env GOPATH)
CONFIG_PATH ?= $(shell pwd)/test/config
ENVIRONMENT ?= local
PRODUCER_DIR := "internal/card/runner/producer"

fmt:
	gofmt -w -s ${PKG_LIST}

init-checker:
	@curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b ${GOPATH}/bin latest
	@go install golang.org/x/tools/cmd/goimports@v0.24.0

unit-test:
	@go test -v ${UNIT_PKG_LIST}

unit-test-summary:
	@rm -f coverage.out test-results.md test-results.txt unit-tests.json
	@-gotestsum --format testname --jsonfile unit-tests.json -- -coverprofile=coverage.out ${UNIT_PKG_LIST} | tee test-results.txt
	@echo "# Test Results" > test-results.md
	@echo -n "\`" >> test-results.md
	@grep DONE test-results.txt >> test-results.md
	@echo -n "\`" >> test-results.md

	# Temporarily don't add the full test details as they are too large for the PR comment
	# @echo "<details><summary>Full Details</summary>" >> test-results.md
	# @echo "" >> test-results.md
	# @-tparse -all -format=markdown -file unit-tests.json >> test-results.md
	# @echo "" >> test-results.md
	# @echo "</details>" >> test-results.md

component-test:
	@CONFIG_PATH=${CONFIG_PATH} ENVIRONMENT=${ENVIRONMENT} go test -v ${COMPONENT_PKG_LIST}

integration-test:
	@CONFIG_PATH=${CONFIG_PATH} ENVIRONMENT=${ENVIRONMENT} go test -v ${INTEGRATION_PKG_LIST}

race:
	@CGO_ENABLED=1 go test -race ${UNIT_PKG_LIST}

benchmark:
	@go test -run="-" -bench=".*" ${UNIT_PKG_LIST}

lint:
	@golangci-lint run --timeout 5m -D staticcheck internal/...
	@golangci-lint run --timeout 5m -D staticcheck cmd/...
	@golangci-lint run --timeout 5m -D staticcheck pkg/...

vendor:
	@go mod vendor

imports:
	@goimports -l -w $(shell find . -type f -name '*.go' -not -path "./vendor/*" -not -path "./.mod/*")

mocks:
	CGO_ENABLED=0 go install github.com/vektra/mockery/v2@v2.46.3
	mockery

check: init-checker lint imports
test: unit-test benchmark race

flyway-clean:
	docker compose run --rm flyway -cleanDisabled=false clean

flyway-info:
	docker compose run --rm flyway info -locations=filesystem:sql/db/migrations,filesystem:sql/db/seeds/${ENVIRONMENT}

flyway-migrate:
	docker compose run --rm flyway migrate -locations=filesystem:sql/db/migrations,filesystem:sql/db/seeds/${ENVIRONMENT}

init-gen-avro:
	@go install github.com/hamba/avro/v2/cmd/avrogen@latest

generate-avro-models: init-gen-avro
	${GOPATH}/bin/avrogen -pkg translator -o ${PRODUCER_DIR}/translator/kafka_models.go -tags json:snake,yaml:upper-camel ${PRODUCER_DIR}/company.issuing.processing.card.avsc
# Include the CI makefile so the ci-* targets are available in the default Makefile

# Include the CI makefile so the ci-* targets are available in the default Makefile
include ci.mk
