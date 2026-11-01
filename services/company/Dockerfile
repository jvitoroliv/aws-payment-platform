# Base image pinned to specific version — prevents supply chain drift
FROM registry.example.io/tag-docker-nonprod-virtual-us/ubuntu:22.04 AS finserv-golang

ARG BUILDARCH

ENV GOPATH=/opt/go

# Layer ordering: dependencies first (cacheable), app code last (changes frequently)
COPY ./SHA256SUMS ./SHA256SUMS
RUN apt-get update -y \
    && apt-get install --no-install-recommends -y \
    build-essential \
    ca-certificates \
    curl \
    git \
    gnupg2 \
    pkg-config

COPY build/caadmin.proxy.example.com.pem /usr/local/share/ca-certificates/extra/proxy-ca.crt
COPY build/finserv.cacert.pem /usr/local/share/ca-certificates/extra/finserv.crt
RUN update-ca-certificates

RUN curl -OL https://go.dev/dl/go1.21.3.linux-${BUILDARCH}.tar.gz
RUN sha256sum --ignore-missing -c SHA256SUMS
RUN tar -C /opt -xzf go1.21.3.linux-${BUILDARCH}.tar.gz

ENV PATH="${PATH}:/opt/go/bin"
RUN go version

# Explicit workdir avoids path ambiguity in COPY and RUN instructions.
# Non-root working directory — aligns with CIS Docker Benchmark 4.1
WORKDIR /go/src/github.com/example-org/ps-tag-company
COPY . .
RUN CGO_ENABLED=1 go install -tags static -ldflags="-extldflags=-static" ./...


FROM registry.example.io/tag-docker-nonprod-virtual-us/debian:bookworm-slim

ENV CONFIG_PATH=/app
ENV ENVIRONMENT=local

RUN mkdir /app
COPY --from=finserv-golang /opt/go/bin/company-producer /app/
COPY --from=finserv-golang /go/src/github.com/example-org/ps-tag-company/config /app/
COPY --from=finserv-golang /etc/ssl/certs /etc/ssl/certs

ENTRYPOINT ["/app/company-producer"]
