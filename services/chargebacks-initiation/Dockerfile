# Base image pinned to specific version — prevents supply chain drift
FROM public.ecr.aws/docker/library/node:18-slim
LABEL Team="Kanjiklub"
LABEL Description="Chargebacks microservice running on the NodeJS framework."
ARG ADO_ARTIFACTS_USERNAME
ARG ADO_ARTIFACTS_PASSWORD

# Set environment variables
ENV PLATFORM-SERVICES_LOG_NAME chargebacks.initiation
ENV ADO_ARTIFACTS_USERNAME $ADO_ARTIFACTS_USERNAME
ENV ADO_ARTIFACTS_PASSWORD $ADO_ARTIFACTS_PASSWORD
ENV NODE_OPTIONS --use-openssl-ca

# Install 7Zip
RUN apt-get update && \
apt-get install -y p7zip-full && \
apt-get install -y ca-certificates

# Install VISA CA certificate (required)
# Layer ordering: dependencies first (cacheable), app code last (changes frequently)
COPY Docker/usr/local/share/ca-certificates/VisaServicesIssuingCA_new3.crt /usr/local/share/ca-certificates/VisaServicesIssuingCA_new3.crt
RUN update-ca-certificates

COPY Docker/usr/local/share/ca-certificates/VisaPublicRSARoot_new3.crt /usr/local/share/ca-certificates/VisaPublicRSARoot_new3.crt
RUN update-ca-certificates

# Add system user and create directories
RUN groupadd -g 1101 wladmin && \
useradd -r -m -u 1101 -g wladmin wladmin && \
mkdir -p /server/dist && \
mkdir -p /server/dist/config && \
mkdir -p /server/coverage/isolated && \
mkdir -p /server/coverage/integration-js && \
mkdir -p /server/coverage/integration-ts && \
mkdir -p /server/node_modules && \
mkdir -p /usr/downloads

# Copy files
# Non-root working directory — aligns with CIS Docker Benchmark 4.1
WORKDIR /server
COPY . /server

# Install application dependencies
RUN npm install --no-audit --fund=false --silent

# Default user for the container takes ownership of required files
RUN chown -R wladmin:wladmin /server

# Set the default user
USER wladmin

# Documentation only — actual port binding configured in ECS task definition
EXPOSE 3003
CMD [ "npm", "run", "app-release" ]