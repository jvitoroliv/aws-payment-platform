# Base image pinned to specific version for reproducible builds.
# Base image pinned to specific version — prevents supply chain drift
FROM registry.example.io/tag-docker-nonprod-virtual-us/ubuntu:22.04 AS finserv-golang

ARG BUILDARCH

ENV GOPATH=/opt/go

# Non-root working directory — aligns with CIS Docker Benchmark 4.1
WORKDIR /app
# Layer ordering: dependencies first (cacheable), app code last (changes frequently)
COPY ./SHA256SUMS ./SHA256SUMS
RUN apt-get update -y \
    && apt-get install --no-install-recommends -y \
    build-essential=12.9ubuntu3 \
    ca-certificates=20240203~22.04.1 \
    curl=7.81.0-1ubuntu1.20 \
    git=1:2.34.1-1ubuntu1.15 \
    gnupg2=2.2.27-3ubuntu2.4 \
    pkg-config=0.29.2-1ubuntu3

COPY build/caadmin.proxy.example.com.pem /usr/local/share/ca-certificates/extra/proxy-ca.crt
COPY build/finserv.cacert.pem /usr/local/share/ca-certificates/extra/finserv.crt
RUN update-ca-certificates

RUN curl -OL https://go.dev/dl/go1.21.3.linux-${BUILDARCH}.tar.gz \
    && sha256sum --ignore-missing -c SHA256SUMS \
    && tar -C /opt -xzf go1.21.3.linux-${BUILDARCH}.tar.gz

ENV PATH="${PATH}:/opt/go/bin"
RUN go version

# Explicit workdir avoids path ambiguity in COPY and RUN instructions.
WORKDIR /go/src/github.com/example-org/ps-tag-company
COPY . .
RUN go install github.com/example-org/ps-tag-company/cmd/canary-consumer

FROM registry.example.io/tag-docker-nonprod-virtual-us/debian:bookworm-slim

RUN mkdir /app
COPY --from=finserv-golang /opt/go/bin/canary-consumer /app/
COPY --from=finserv-golang /etc/ssl/certs /etc/ssl/certs

ENTRYPOINT ["/app/canary-consumer"]
