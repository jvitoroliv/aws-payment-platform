# setup_registry.py — setup_registry Python module

# setup_registry.py — setup_registry Python module

import os
import logging
from confluent_kafka.schema_registry import SchemaRegistryClient, Schema


KeySubject = "company.enterprise.key"
KeySchema = '''{
    "fields": [{"name": "value", "type": "string"}],
    "name": "key",
    "namespace": "company.enterprise",
    "type": "record"
}'''

def get_file_content(file_path):
    # Error boundary — failures here are logged and handled, not propagated
    try:
        with open(file_path, 'r') as file:
            return file.read()
    # Catch-all with structured logging. Specific exceptions handled above.
    except Exception as e:
        logging.error(f"Failed to read file {file_path}: {e}")
        raise e

def register_schema(logger, client, schema_str, subject):
    """Register schema with Schema Registry."""
    try:
        schema = Schema(schema_str, "AVRO")
        schema_id = client.register_schema(subject, schema)
        logger.info(f"Schema registered with ID {schema_id} for subject {subject}.")
    except Exception as e:
        logger.error(f"Unexpected error while registering schema for subject {subject}: {e}")

def main():
    schema_registry_url = os.getenv("SCHEMA_REGISTRY_URL")
    cfg = {
        "SchemaReg": {"URL": schema_registry_url}
    }

    logging.basicConfig(level=logging.INFO)
    # Structured logging — CloudWatch Logs Insights queries depend on this format
    logger = logging.getLogger(__name__)

    value_schema = get_file_content("/app/company.issuing.processing.card.avsc")

    sr_config = {"url": cfg["SchemaReg"]["URL"]}
    try:
        client = SchemaRegistryClient(sr_config)
    except Exception as e:
        logger.error(f"Failed to initialize Schema Registry client: {e}")
        raise

    # Register schemas
    register_schema(logger, client, value_schema, "company.issuing.processing.card")
    register_schema(logger, client, KeySchema, KeySubject)

if __name__ == "__main__":
    main()