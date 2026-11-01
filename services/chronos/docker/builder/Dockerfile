# Base image pinned to specific version — prevents supply chain drift
FROM golang:1.21

ARG BUILDARCH

RUN apt-get update -y
RUN apt-get install zip -y

RUN apt-get install gnupg2 -y

RUN apt-get install --no-install-recommends -y curl ca-certificates

# Layer ordering: dependencies first (cacheable), app code last (changes frequently)
COPY caadmin.proxy.example.com.pem /usr/local/share/ca-certificates/extra/proxy-ca.crt
RUN update-ca-certificates

# Conditional download based on BUILDARCH, as unfortunately the arm64 version of libssl1.1 is not available on the same URL
RUN if [ "$BUILDARCH" = "arm64" ]; then \
        wget http://ports.ubuntu.com/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2_${BUILDARCH}.deb; \
    else \
        wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2_${BUILDARCH}.deb; \
    fi
RUN dpkg -i libssl1.1_1.1.1f-1ubuntu2_${BUILDARCH}.deb

# use sed to bypass nodejs-10 deprecation warning
RUN curl -sLk https://deb.nodesource.com/setup_20.x | sed 's/sleep/echo/' | bash -
RUN curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc |  gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg  --dearmor
RUN echo "deb [signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] http://repo.mongodb.org/apt/debian bookworm/mongodb-org/7.0 main" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list

RUN apt-get -y update && apt-get -y install nodejs mongodb-mongosh
