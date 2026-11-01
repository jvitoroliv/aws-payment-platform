# Contains standardized make targets that are called by CI

ci-pull:
	@# No Docker dependencies for ps-tag-config library
	@echo "No Docker images to pull for ps-tag-config"

ci-build:
	@# Build Go library (no binaries, just validate)
	@echo "::group::Building and validating Go library"
	go mod download
	go build .
	@echo "::endgroup::"
	@echo

ci-test:
	@# Run tests
	@echo "::group::Unit tests"
	go test -v .
	@echo "::endgroup::"
	@echo

ci-push-images:
	@# No images to push for ps-tag-config library
	@echo "No Docker images to push for ps-tag-config"

ci-promote-images:
	@# No images to promote for ps-tag-config library
	@echo "No Docker images to promote for ps-tag-config"

ci-cleanup:
	@# Clean up Go build cache and modules
	@echo "::group::Cleaning up Go build cache"
	go clean -cache -modcache -testcache
	@echo "::endgroup::"
	@echo

ci-docker-images:
	@# No Docker images for ps-tag-config library
	@echo "No Docker images for ps-tag-config library"

ci-create-tag:
	@# Create Git tag
	@if [ -z "${VERSION}" ]; then \
		echo "ERROR: VERSION environment variable is required"; \
		exit 1; \
	fi
	@echo "::group::Creating Git tag v${VERSION}"
	git config user.name 'GitHub Actions'
	git config user.email 'user@example-company.com'
	git tag -a "v${VERSION}" -m "Release version ${VERSION}"
	git push origin "v${VERSION}"
	@echo "::endgroup::"
	@echo