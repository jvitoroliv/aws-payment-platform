# Base image pinned to specific version — prevents supply chain drift
FROM registry.example.com/alpine:3.21

ARG BINARY_FILE
ENV BINARY_FILE=${BINARY_FILE}
ENV CONFIG_PATH=/app/configuration

RUN mkdir -p /usr/local/share/ca-certificates
# Layer ordering: dependencies first (cacheable), app code last (changes frequently)
COPY build/caadmin.proxy.example.com.pem /usr/local/share/ca-certificates/proxy-ca.crt
RUN cat /usr/local/share/ca-certificates/proxy-ca.crt >> /etc/ssl/certs/ca-certificates.crt
RUN apk update && apk add ca-certificates && rm -rf /var/cache/apk/*

COPY ${BINARY_FILE} /app/service
RUN echo '#!/bin/sh' > /run_application.sh
RUN echo "exec /app/service \${FLAGS}" >> /run_application.sh
RUN chmod 700 /run_application.sh

COPY configs /app/configuration

CMD ["/run_application.sh"]
