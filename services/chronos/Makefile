default: fmt
default: mod

fmt:
	for d in $$(go list -f "{{.Dir}}" ./cmd/...); do goimports -w $${d}/*.go; done
	for d in $$(go list -f "{{.Dir}}" ./pkg/...); do goimports -w $${d}/*.go; done
	for d in $$(go list -f "{{.Dir}}" ./automation/...); do goimports -w $${d}/*.go; done

mod:
	git config --global url."https://${GITHUB_AUTH_TOKEN}@github.com/".insteadOf "https://github.com/"
	go mod tidy
	go mod vendor

start:
	./docker/localstack/start_localstack.sh

test: mod lint test_no_lint

test_no_lint:
	CHRONOS_ENV=local go test $(TEST_FLAGS) \
		$$(go list ./lambda/... ) \
		$$(go list ./pkg/... ) \

test_no_cache: TEST_FLAGS:=$(sort $(TEST_FLAGS) -count=1)
test_no_cache: test

lint:
	curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $$(go env GOPATH)/bin v1.55.2
	GOFLAGS="-buildvcs=false" golangci-lint run --timeout 2m lambda/... --skip-dirs="vendor|github.com/example-org/ps-tag-log"
	GOFLAGS="-buildvcs=false" golangci-lint run --timeout 2m pkg/... --skip-dirs="vendor|github.com/example-org/ps-tag-log"
	GOFLAGS="-buildvcs=false" golangci-lint run automated-tests/... --skip-dirs="vendor|github.com/example-org/ps-tag-log"

mocks:
	CGO_ENABLED=0 go install github.com/vektra/mockery/v2@v2.37.1
	mockery

generate_openapi:
	CHRONOS_ENV=local go run tools/generate_openapi/generate_openapi.go