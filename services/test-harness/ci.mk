# Contains standardized make targets that are called by CI

ci-pull:
	@# Pull any Docker dependencies
	docker compose pull --ignore-buildable

ci-build:
	@# Compile web static files first
	@echo "::group::Compiling web static files"
	./scripts/compile_web.sh
	@echo "::endgroup::"
	@echo

	@# Build Go binaries
	@echo "::group::Building Go binaries"
	docker compose run --rm builder make test-harness mock-chronos mock-service-mock-coreplatform
	@echo "::endgroup::"
	@echo

	@# Build Docker images
	@echo "::group::Building test-harness Docker image"
	docker compose build test-harness
	@echo "::endgroup::"
	@echo

	@echo "::group::Building mock-chronos Docker image"
	docker compose build mock-chronos
	@echo "::endgroup::"
	@echo

	@echo "::group::Building mock-service-mock-coreplatform Docker image"
	docker compose build mock-service-mock-coreplatform
	@echo "::endgroup::"
	@echo

ci-test:
	@# Run tests
	@echo "::group::Unit tests"
	docker compose run --rm builder make unit-test-summary
	@echo "::endgroup::"
	@echo

	@echo "::group::Component tests"
	docker compose run --rm builder make component-test
	@echo "::endgroup::"
	@echo

ci-push-images:
	@# Push Docker images
	@echo "::group::Pushing test-harness Docker image"
	jf docker push registry.example.io/docker-nonprod/app/ps-tag-test-harness:${VERSION}
	@echo "::endgroup::"
	@echo

	@echo "::group::Pushing mock-chronos Docker image"
	jf docker push registry.example.io/docker-nonprod/app/ps-tag-mock-chronos:${VERSION}
	@echo "::endgroup::"
	@echo

	@echo "::group::Pushing mock-service-mock-coreplatform Docker image"
	jf docker push registry.example.io/docker-nonprod/app/ps-tag-mock-service-mock-coreplatform:${VERSION}
	@echo "::endgroup::"
	@echo

# Unused, not properly implemented in pipelines yet
ci-promote-images:
	@# Promote Docker images
	@echo "::group::Promoting test-harness Docker image"
	jf rt docker-promote tag/ps-tag-test-harness tag-docker-nonprod-federated-us tag-docker-prod-federated-us --source-tag=${VERSION} --copy=true --dry-run=true
	@echo "::endgroup::"
	@echo

	@echo "::group::Promoting mock-chronos Docker image"
	jf rt docker-promote tag/ps-tag-mock-chronos tag-docker-nonprod-federated-us tag-docker-prod-federated-us --source-tag=${VERSION} --copy=true --dry-run=true
	@echo "::endgroup::"
	@echo

	@echo "::group::Promoting mock-service-mock-coreplatform Docker image"
	jf rt docker-promote tag/ps-tag-mock-service-mock-coreplatform tag-docker-nonprod-federated-us tag-docker-prod-federated-us --source-tag=${VERSION} --copy=true --dry-run=true
	@echo "::endgroup::"
	@echo

ci-cleanup:
	@# Clean up Docker resources
	docker compose down --remove-orphans --rmi local --volumes
	docker compose rm --force --stop --volumes

	@echo "::group::Cleaning up web build resources"
	docker rmi registry.example.io/docker-nonprod/app/ps-tag-web-build:${VERSION:-latest} 2>/dev/null || true
	docker rm web-build-temp 2>/dev/null || true
	rm -rf out/web
	@echo "::endgroup::"
	@echo

ci-docker-images:
	@# Print Docker images to be pushed
	@echo 'registry.example.io/docker-nonprod/app/ps-tag-test-harness:${VERSION} \
	registry.example.io/docker-nonprod/app/ps-tag-mock-chronos:${VERSION} \
	registry.example.io/docker-nonprod/app/ps-tag-mock-service-mock-coreplatform:${VERSION} \
	registry.example.io/docker-nonprod/app/ps-tag-builder:${VERSION} \
	registry.example.io/docker-nonprod/app/ps-tag-web-build:${VERSION}'
