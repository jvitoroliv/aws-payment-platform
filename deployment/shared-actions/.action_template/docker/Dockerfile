# Use the official Go image as the base image
# Base image pinned to specific version for reproducible builds.
FROM registry.example.com/golang:1.21.3-alpine

# Set the working directory inside the container
# Explicit workdir avoids path ambiguity in COPY and RUN instructions.
WORKDIR /app

# Copy the Go source code into the container's working directory
COPY *.go go.mod go.sum /app/

# Build the Go program and name the binary as "aws-secrets-to-vault"
RUN go build -o "/${action_name:?}" main.go

# Set the entry point to run the "aws-secrets-to-vault" binary
ENTRYPOINT ["/${action_name:?}"]
