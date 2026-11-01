CMD_PACKAGE=github.com/example-org/ps-tag-accounts-receivable/cmd
CMDS=\
funding-group-consumer \

DOCKER_COMPOSE=docker compose -f docker-compose.yml -f docker-compose.override.yml
PROFILE_CONSUMER=--profile funding-group-consumer
PROFILE_UNIT_TEST=--profile unit-test
PROFILE_INTEGRATION_TEST=--profile integration-test

# Running the app, unit tests and integration tests in docker containers will attempt to build the containers by default, unless build=false is passed
build := true
# Overwrite build variable if build=false is specified in the command line
ifeq ($(filter build=false,$(MAKECMDGOALS)),build=false)
    build := false
endif

build: $(CMDS)

funding-group-consumer:
	go build $(CMD_PACKAGE)/funding-group-consumer

clean:
	rm -rf $(CMDS)
	rm coverage.out

unit-test:
	go test -v $(shell go list ./... | grep -v /test/)

coverage:
	go test -v $(shell go list ./... | grep -v /test/) -coverprofile coverage.out
	go tool cover -html=coverage.out

docker-build: docker-app-build docker-unit-test-build docker-integration-test-build

docker-app-build:
	$(DOCKER_COMPOSE) build funding-group-consumer

docker-start: $(if $(filter $(build),true), docker-build)
	$(DOCKER_COMPOSE) $(PROFILE_CONSUMER) up -d

docker-stop:
	$(DOCKER_COMPOSE) $(PROFILE_CONSUMER) stop

docker-clean:
	$(DOCKER_COMPOSE) down --remove-orphans --volumes

docker-test: docker-unit-test docker-integration-test

docker-unit-test: $(if $(filter $(build),true), docker-unit-test-build) docker-unit-test-run

docker-unit-test-build:
	$(DOCKER_COMPOSE) build unit-test

docker-unit-test-run:
	$(DOCKER_COMPOSE) $(PROFILE_UNIT_TEST) up --abort-on-container-exit --exit-code-from unit-test unit-test

docker-integration-test: $(if $(filter $(build),true), docker-integration-test-build) docker-integration-test-run

docker-integration-test-build:
	$(DOCKER_COMPOSE) build integration-test

docker-integration-test-run:
	$(DOCKER_COMPOSE) $(PROFILE_INTEGRATION_TEST) up --abort-on-container-exit --exit-code-from integration-test integration-test

.PHONY: build funding-group-consumer clean unit-test \
		docker-build docker-app-build docker-start docker-stop docker-clean docker-test \
		docker-unit-test docker-unit-test-build docker-unit-test-run \
		docker-integration-test docker-integration-test-build docker-integration-test-run