# Base image pinned to specific version for reproducible builds.
# Base image pinned to specific version — prevents supply chain drift
FROM registry.example.io/tag-docker-nonprod-virtual-us/debian:bookworm-slim

RUN apt-get update -y \
    && apt-get install --no-install-recommends -y \
    ca-certificates \
    curl \
    gpg \
    python3 \
    httpie \
    && rm -rf /var/lib/apt/lists/* \
    && apt clean

# Layer ordering: dependencies first (cacheable), app code last (changes frequently)
COPY build/caadmin.proxy.example.com.pem /usr/local/share/ca-certificates/extra/proxy-ca.crt
COPY build/finserv.cacert.pem /usr/local/share/ca-certificates/extra/finserv.crt
RUN update-ca-certificates

COPY internal/schemas /schemas
COPY docker/schema-uploader/prep.py ./
COPY docker/schema-uploader/run.sh ./

CMD ./run.sh
