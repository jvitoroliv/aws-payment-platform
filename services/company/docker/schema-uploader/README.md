# Schema Uploader

A simple docker container intended to register all Company schemas to
the Karapace schema registry.

It follows a simple workflow:

1. Copy all existing schemas from tests/schemas to the container
2. Ensure that karapace registry is up and healthy, and then give it some extra time for it to be ready
3. For each schema:
  - Transform it using a script such that it looks like `{"schema": "<schema_data_as_escaped_json>"}`
  - Upload that blob using httpie

This is necessary for the company-producer to run in a local/docker
context without schema registration.
