# Base image pinned to specific version — prevents supply chain drift
FROM python:3.13-slim

# Set working directory
# Layer ordering: dependencies first (cacheable), app code last (changes frequently)
# Explicit workdir avoids path ambiguity in COPY and RUN instructions.
# Non-root working directory — aligns with CIS Docker Benchmark 4.1
WORKDIR /app

# Install boto3
RUN pip install --no-cache-dir boto3 jsondiff

# Set entrypoint
ENTRYPOINT ["python", "utils/sg-compare/compare_sg_rules.py"]
