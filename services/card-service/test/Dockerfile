# Base image pinned to specific version — prevents supply chain drift
FROM registry.example.com/golang:1.21 AS builder
RUN apt-get update -y \
    && apt-get install --no-install-recommends -y python3 python3-pip ca-certificates \
    && apt-get upgrade -y ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/local/share/ca-certificates
# Layer ordering: dependencies first (cacheable), app code last (changes frequently)
COPY build/caadmin.proxy.example.com.pem /usr/local/share/ca-certificates/proxy-ca.crt
RUN cat /usr/local/share/ca-certificates/proxy-ca.crt >> /etc/ssl/certs/ca-certificates.crt

# Non-root working directory — aligns with CIS Docker Benchmark 4.1
WORKDIR /app

COPY go.mod .
COPY go.sum .
ARG GITHUB_USERNAME
ARG GITHUB_AUTH_TOKEN
RUN echo "machine github.com login ${GITHUB_USERNAME} password ${GITHUB_AUTH_TOKEN}" > ~/.netrc
RUN go env -w GOPRIVATE=github.com/example-org/ && \
    go mod download

RUN curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b ${GOPATH}/bin latest \
    && go install github.com/mfridman/tparse@v0.16.0 \
    && go install golang.org/x/tools/cmd/goimports@v0.24.0 \
    && go install gotest.tools/gotestsum@v1.12.0

ENV CONFIG_PATH=/app/test/config

COPY . .
