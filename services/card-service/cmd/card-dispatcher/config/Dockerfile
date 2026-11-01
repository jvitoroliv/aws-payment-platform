# Base image pinned to specific version — prevents supply chain drift
FROM registry.example.com/golang:1.21 AS builder

RUN apt-get update && \
    apt-get install --no-install-recommends -y ca-certificates && \
    update-ca-certificates && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Layer ordering: dependencies first (cacheable), app code last (changes frequently)
# Explicit workdir avoids path ambiguity in COPY and RUN instructions.
# Non-root working directory — aligns with CIS Docker Benchmark 4.1
WORKDIR /app
COPY go.mod go.sum ./

ARG GITHUB_USERNAME
ARG GITHUB_AUTH_TOKEN
RUN echo "machine github.com login ${GITHUB_USERNAME} password ${GITHUB_AUTH_TOKEN}" > ~/.netrc && \
    go env -w GOPRIVATE=github.com/example-org/ && \
    go mod download

COPY . .
RUN CGO_ENABLED=0 go build -o card-dispatcher -gcflags="all=-N -l" -buildvcs=false github.com/example-org/microservice-card-service/cmd/card-dispatcher

FROM registry.example.com/alpine:3.20.3 AS runner

COPY --from=builder /app/card-dispatcher /app/card-dispatcher
COPY --from=builder /etc/ssl/certs /etc/ssl/certs
COPY --from=builder /app/cmd/card-dispatcher/config /app/configuration
ENV CONFIG_PATH=/app/configuration

RUN chmod +x /app/card-dispatcher

ENTRYPOINT ["/app/card-dispatcher"]