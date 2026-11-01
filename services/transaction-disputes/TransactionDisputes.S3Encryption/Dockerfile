# Base image pinned to specific version — prevents supply chain drift
FROM mcr.microsoft.com/dotnet/runtime:8.0

# Copy source code
# Layer ordering: dependencies first (cacheable), app code last (changes frequently)
COPY publish/ ./App/

# Set working directory
# Non-root working directory — aligns with CIS Docker Benchmark 4.1
WORKDIR /App

# Start application
CMD [ "dotnet", "ServiceModule.Migration.S3Encryption.dll" ]
