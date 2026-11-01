export GIT_COMMIT:=$(CODEBUILD_RESOLVED_SOURCE_VERSION)
export CGO_ENABLED=0
ifeq ($(CODEBUILD_RESOLVED_SOURCE_VERSION),)
GIT_COMMIT:=$(shell git rev-parse HEAD)
endif

LD_FLAGS="-s -w -X tag-mock-service-dev/pkg/version.GitCommit=$(GIT_COMMIT) -X tag-mock-service-dev/pkg/version.Mock-ServiceGitCommit=$(GIT_COMMIT)"

ifeq ($(GO_ARGS),)
GO_ARGS=-ldflags $(LD_FLAGS)
endif

CMDS=\
test-harness \
mock-service-mock-coreplatform \
mock-chronos \

all: $(CMDS) web

clean:
	rm -rf $(TOOLS) $(CMDS)
	rm -rf $(PWD)/out
	rm -f build/docker/test-harness/test-harness
	rm -rf build/docker/test-harness/web
	rm -f build/docker/mock-service-mock-coreplatform/mock-service-mock-coreplatform

test-harness:
	go build $(GO_ARGS) \
		ps-tag-test-harness/cmd/test-harness

mock-service-mock-coreplatform:
	go build $(GO_ARGS) \
		ps-tag-test-harness/cmd/mock-service-mock-coreplatform

mock-chronos:
	go build $(GO_ARGS) \
		ps-tag-test-harness/cmd/mock-chronos

DB_TEST=mock-service_test
ifeq ($(strip $(MOCK_SERVICE_MONGO_URI)),)
MONGO_URI=mongodb://localhost
else
MONGO_URI=$(MOCK_SERVICE_MONGO_URI)
endif

test: lint test_no_lint

test_no_lint:
	sleep 1
	#mongo $(MONGO_URI)/$(DB_TEST) --eval "db.dropDatabase()" > /dev/null
	#mongo $(MONGO_URI)/$(DB_TEST) vendor/tag-mock-service-dev/scripts/mongo_indexes/indexes.js
	CHRONOS_ENV=local MOCK_SERVICE_MONGO_DATABASE=$(DB_TEST) MOCK_SERVICE_MONGO_URI=$(MONGO_URI) \
        go test $(TEST_FLAGS) \
		$$(go list ./cmd/... )

test_no_cache: TEST_FLAGS:=$(sort $(TEST_FLAGS) -count=1)
test_no_cache: test

test_with_sonar: TEST_FLAGS:=$(sort $(TEST_FLAGS) -count=1 -coverprofile=coverage1.out)
test_with_sonar: test
	sonar-scanner

install: $(CMDS) $(TOOLS)
	mkdir -p $(GOPATH)/bin
	cp -v $(CMDS) $(GOPATH)/bin
	cp -v $(TOOLS) $(GOPATH)/bin

generate: config-to-tf-keys
	go generate $$(go list ./cmd/... )
	go generate $$(go list ./pkg/... )

vet: VET_FLAGS=-asmdecl -atomic -bool -buildtags -copylocks -methods -nilfunc -printf -rangeloops -shift -unsafeptr
vet:
	go vet $(VET_FLAGS) $$(go list ./cmd/... )
	go vet $(VET_FLAGS) $$(go list ./pkg/... )

fmt:
	for d in $$(go list -f "{{.Dir}}" ./cmd/...); do goimports -w $${d}/*.go; done
	#for d in $$(go list -f "{{.Dir}}" ./pkg/...); do goimports -w $${d}/*.go; done

jshint:
	cd web; jshint .

web: GULP=$(PWD)/web/node_modules/.bin/gulp
web: TAR_FILE=$(PWD)/pkg/webresources.tgz
web: npm-install
	$(GULP) clean --cwd ./web
	$(GULP) build-archive --cwd ./web

	if [ ! -e "$(TAR_FILE)" ]; \
	then \
		echo 'Expected file: $(TAR_FILE) to be created by gulp script'; \
		exit 1; \
	fi

	mkdir -p out/web

	tar -xf $(TAR_FILE) -C out/web
	rm $(TAR_FILE)

npm-install:
	npm --prefix ./web install

docker-build-debug: export GOOS=darwin
docker-build-debug: export GO_ARGS=-p 4 -gcflags "all=-N -l"
docker-build-debug: export MOCK_SERVICE_VERSION=latest
docker-build-debug: docker-build

docker-build: export MOCK_SERVICE_VERSION=latest
docker-build: export LOCAL_BUILD=true
docker-build:
	@build/docker/build.sh

docker-test: export MOCK_SERVICE_VERSION=latest
docker-test:
	@build/docker/test.sh

docker-start: export MOCK_SERVICE_VERSION=latest
docker-start:
	@docker-compose -f build/docker/docker-compose.yml build
	@docker-compose -f build/docker/docker-compose.yml up
	#@build/docker/run.sh

docker-stop: export MOCK_SERVICE_VERSION=latest
docker-stop:
	@docker-compose -f build/docker/docker-compose.yml down
	@-tmux kill-session -t mock-service

docker-push-jenkins:
	@docker-compose -parallel -f build/docker/docker-compose.yml build
	@docker-compose -parallel -f build/docker/docker-compose.yml push

start_everything:
	scripts/start_everything.sh

lint:
	# curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $$(go env GOPATH)/bin v1.27.0
	$(shell go env GOPATH)/bin/golangci-lint run --timeout 5m \
#		cmd/... \
#		pkg/...

imports:
	@echo "Checking import formatting..."
	@$(shell go env GOPATH)/bin/goimports -d $$(find . -name "*.go" -not -path "./vendor/*" -not -path "./web/*")

unit-test-summary:
	@echo "Running unit tests..."
	@go test -v -coverprofile=coverage.out $$(go list ./cmd/... ./pkg/...)

component-test:
	@echo "Running component tests..."
	@go test -v -tags=component $$(go list ./cmd/... ./pkg/...)

race:
	@echo "Running race condition tests..."
	@go test -race -v $$(go list ./cmd/... ./pkg/...)

vendor: export GOPRIVATE=github.com/example-org
vendor:
	git config url."git@github.com/example-org".insteadOf "https://github.com/example-org"
	sed -i "" -E -e '/^replace tag-mock-service-dev/d' go.mod
	echo 'replace tag-mock-service-dev => github.com/example-org/ps-tag-dev master' >> go.mod
	go mod tidy
	go mod vendor

.PHONY: all clean fmt generate test vet web docker-build-debug docker-build docker-test docker-run docker-start docker-stop docker-build-jenkins docker-test-jenkins docker-push-jenkins $(CMDS) $(TOOLS) start_everything lint test_no_lint vendor imports unit-test-summary component-test race
