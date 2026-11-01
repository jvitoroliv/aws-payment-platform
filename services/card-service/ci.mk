# Contains standardized make targets that are called by CI

ci-pull:
	@# Pull any Docker dependencies
	docker compose pull --ignore-buildable

ci-build:
	@# Build Docker images
	@echo "::group::Building card-dispatcher Docker image"
	docker compose build card-dispatcher
	@echo "::endgroup::"
	@echo

	@echo "::group::Building card-producer Docker image"
	docker compose build card-producer
	@echo "::endgroup::"
	@echo

	@echo "::group::Building card-service-db-datadog-agent Docker image"
	docker compose build card-service-db-datadog-agent
	@echo "::endgroup::"
	@echo

	@echo "::group::Building card-service-api Docker image"
	docker compose build card-service-api
	@echo "::endgroup::"
	@echo

	@echo "::group::Building company-consumer Docker image"
	docker compose build company-consumer
	@echo "::endgroup::"
	@echo

	@echo "::group::Building tests Docker image"
	docker compose build tests
	@echo "::endgroup::"
	@echo

	@echo "::group::Building postgres-database Docker image"
	docker compose build postgres-database
	@echo "::endgroup::"
	@echo

ci-test:
	@# Run tests
	@echo "::group::Linting"
	docker compose run --rm tests -c 'make lint'
	@echo "::endgroup::"
	@echo

	@echo "::group::Import checks"
	docker compose run --rm tests -c 'make imports'
	@echo "::endgroup::"
	@echo

	@echo "::group::Unit tests"
	docker compose run --rm tests -c 'make unit-test-summary'
	@echo "::endgroup::"
	@echo

	@echo "::group::Flyway migrations - Dev"
	# 'flyway clean' doesn't remove Postgres roles so the Postgres container and its volume must be removed for a clean run
	docker compose down postgres-database -v
	docker compose run --rm flyway migrate -locations=filesystem:sql/db/migrations,filesystem:sql/db/seeds/dev
	@echo "::endgroup::"

	@echo "::group::Flyway migrations - Test"
	docker compose down postgres-database -v
	docker compose run --rm flyway migrate -locations=filesystem:sql/db/migrations,filesystem:sql/db/seeds/test
	@echo "::endgroup::"

	@echo "::group::Flyway migrations - Stage"
	docker compose down postgres-database -v
	docker compose run --rm flyway migrate -locations=filesystem:sql/db/migrations,filesystem:sql/db/seeds/stage
	@echo "::endgroup::"

	@echo "::group::Flyway migrations - Prod"
	docker compose down postgres-database -v
	docker compose run --rm flyway migrate -locations=filesystem:sql/db/migrations,filesystem:sql/db/seeds/prod
	@echo "::endgroup::"

	@echo "::group::Flyway migrations - Docker"
	docker compose down postgres-database -v
	docker compose run --rm flyway migrate -locations=filesystem:sql/db/migrations,filesystem:sql/db/seeds/docker
	@echo "::endgroup::"
	@echo

	@echo "::group::Component tests"
	docker compose run --rm tests -c 'make component-test'
	@echo "::endgroup::"
	@echo

	@echo "::group::Integration tests"
	docker compose run --rm tests -c 'make integration-test'
	@echo "::endgroup::"
	@echo

	@echo "::group::Race condition checks"
	docker compose run --rm tests -c 'make race'
	@echo "::endgroup::"
	@echo

# Unused, not properly implemented in pipelines yet
ci-validate-images:
	@# Validate Docker images
	@echo "TODO: validate specified images exist within repos to help with push and promote targets."
	@echo

ci-push-images:
	@# Push Docker images
	@echo "::group::Pushing card-dispatcher Docker image"
	jf docker push registry.example.io/docker-nonprod/app/card-dispatcher:${VERSION}
	@echo "::endgroup::"
	@echo

	@echo "::group::Pushing card-producer Docker image"
	jf docker push registry.example.io/docker-nonprod/app/card-producer:${VERSION}
	@echo "::endgroup::"
	@echo

	@echo "::group::Pushing card-service-api Docker image"
	jf docker push registry.example.io/docker-nonprod/app/card-service-api:${VERSION}
	@echo "::endgroup::"
	@echo

	@echo "::group::Pushing card-service-db-datadog-agent Docker image"
	jf docker push registry.example.io/docker-nonprod/app/card-service-db-datadog-agent:${VERSION}
	@echo "::endgroup::"
	@echo

	@echo "::group::Pushing company-consumer Docker image"
	jf docker push registry.example.io/docker-nonprod/app/card-service-company-consumer:${VERSION}
	@echo "::endgroup::"
	@echo

# Unused, not properly implemented in pipelines yet
ci-promote-images:
	@# Promote Docker images
	@echo "::group::Promoting card-dispatcher Docker image"
	jf rt docker-promote tag/card-dispatcher tag-docker-nonprod-federated-us tag-docker-prod-federated-us --source-tag=${VERSION} --copy=true --dry-run=true
	@echo "::endgroup::"
	@echo

	@echo "::group::Promoting card-producer Docker image"
	jf rt docker-promote tag/card-producer tag-docker-nonprod-federated-us tag-docker-prod-federated-us --source-tag=${VERSION} --copy=true --dry-run=true
	@echo "::endgroup::"
	@echo

	@echo "::group::Promoting card-service-api Docker image"
	jf rt docker-promote tag/card-service-api tag-docker-nonprod-federated-us tag-docker-prod-federated-us --source-tag=${VERSION} --copy=true --dry-run=true
	@echo "::endgroup::"
	@echo

	@echo "::group::Promoting card-service-db-datadog-agent Docker image"
	jf rt docker-promote tag/card-service-db-datadog-agent tag-docker-nonprod-federated-us tag-docker-prod-federated-us --source-tag=${VERSION} --copy=true --dry-run=true
	@echo "::endgroup::"
	@echo

	@echo "::group::Promoting company-consumer Docker image"
	jf rt docker-promote tag/card-service-company-consumer tag-docker-nonprod-federated-us tag-docker-prod-federated-us --source-tag=${VERSION} --copy=true --dry-run=true
	@echo "::endgroup::"
	@echo

ci-cleanup:
	@# Clean up Docker resources
	docker compose down --remove-orphans --rmi local --volumes
	docker compose rm --force --stop --volumes

ci-docker-images:
	@# Print Docker images to be pushed
	@echo 'registry.example.io/docker-nonprod/app/card-dispatcher:${VERSION} \
	registry.example.io/docker-nonprod/app/card-producer:${VERSION} \
	registry.example.io/docker-nonprod/app/card-service-api:${VERSION} \
	registry.example.io/docker-nonprod/app/card-service-db-datadog-agent:${VERSION} \
	registry.example.io/docker-nonprod/app/card-service-company-consumer:${VERSION}'
