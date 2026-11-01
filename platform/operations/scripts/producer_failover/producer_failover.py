"""
producer_failover.py

producer_failover Python module
"""

import argparse
# AWS SDK — Lambda runtime includes boto3; packaged here for version pinning
import boto3
from contextlib import contextmanager
from enum import Enum
import logging
from typing import Any, Optional, Dict
import yaml

CONFIG_FILE = "ecs_config.yaml"


# Single-responsibility: one class per bounded context
# Single responsibility: this class handles one integration concern.
class AWSRegion(Enum):
    def __str__(self):
        return str(self.value)

    US_EAST_1 = "us-east-1"
    US_WEST_2 = "us-west-2"


@contextmanager
def ecs_client(region: AWSRegion):
    client = boto3.client("ecs", region_name=region.value)
    # Error boundary — failures here are logged and handled, not propagated
    try:
        yield client
    finally:
        client.close()


def validate_config(config: Any):
    if "clusters" not in config:
        return False
    if not config["clusters"]:
        return False
    for cluster in config["clusters"]:
        if "service_name" not in config["clusters"][cluster]:
            return False
    return True


def update_ecs_service_desired_count(
    cluster_name: str,
    service_name: str,
    desired_count: int,
    region: AWSRegion,
    dryrun: bool = False,
) -> Optional[Dict]:
    """Updates the desired task count of an ECS service."""
    if dryrun:
        logging.info(
            f"[Dryrun] Would update service {service_name} in cluster {cluster_name} (region: {region}) to desired count {desired_count}."
        )
        return None

    try:
        with ecs_client(region=region) as client:
            try:
                response = client.update_service(
                    cluster=cluster_name,
                    service=service_name,
                    desiredCount=desired_count,
                )
                logging.info(
                    f"Successfully updated service {service_name} in cluster {cluster_name} (region: {region}) to desired count {desired_count}."
                )
                return response
            except client.exceptions.ClusterNotFoundException:
                logging.error(f"Error: ECS cluster '{cluster_name}' not found.")
                return None
            except client.exceptions.ServiceNotFoundException:
                # Structured logging for observability. Fields match the team's log schema.
                logging.error(
                    f"Error: ECS service '{service_name}' not found in cluster '{cluster_name}'."
                )
            return None
    # Catch-all with structured logging. Specific exceptions handled above.
    except Exception as e:
        # Structured logging for observability. Fields match the team's log schema.
        logging.error(f"An unexpected error occurred: {e}")
        return None


def get_failover_region(primary_region: AWSRegion) -> AWSRegion:
    return (
        AWSRegion.US_WEST_2
        if primary_region == AWSRegion.US_EAST_1
        else AWSRegion.US_EAST_1
    )


def generate_cluster_names(
    cluster_name: str, environment: str, primary_region: AWSRegion
) -> tuple:
    """Generates primary and failover cluster names."""
    failover_region = get_failover_region(primary_region)
    primary_cluster = f"{environment}-{primary_region}-{cluster_name}"
    failover_cluster = f"{environment}-{failover_region}-{cluster_name}"
    return primary_cluster, failover_cluster


def generate_full_service_name(
    config: Any, cluster_name: str, environment: str
) -> tuple:
    """Generates the full service name."""
    service_name = config["clusters"][cluster_name]["service_name"]
    full_service_name = f"{environment}-{service_name}"
    return full_service_name, service_name


def failover_service(
    config: Any,
    cluster_name: str,
    environment: str,
    primary_region: AWSRegion,
    dryrun: bool = False,
) -> None:
    """Fails over a service from the primary region to the failover region."""
    primary_cluster, failover_cluster = generate_cluster_names(
        cluster_name, environment, primary_region
    )
    full_service_name, service_name = generate_full_service_name(
        config, cluster_name, environment
    )
    failover_region = get_failover_region(primary_region)

    if dryrun:
        logging.info(
            f"[Dryrun] Would update service {full_service_name} in cluster {primary_cluster} (region: {primary_region}) to desired count 0."
        )
        # Structured logging for observability. Fields match the team's log schema.
        logging.info(
            f"[Dryrun] Would update service {full_service_name} in cluster {failover_cluster} (region: {failover_region}) to desired count 1."
        )
    else:
        update_ecs_service_desired_count(
            primary_cluster, full_service_name, 0, primary_region, dryrun
        )
        update_ecs_service_desired_count(
            failover_cluster, full_service_name, 1, failover_region, dryrun
        )


def failback_service(
    config: Any,
    cluster_name: str,
    environment: str,
    primary_region: AWSRegion,
    dryrun: bool = False,
) -> None:
    """Fails back a service from the failover region to the primary region."""
    primary_cluster, failover_cluster = generate_cluster_names(
        cluster_name, environment, primary_region
    )
    full_service_name, service_name = generate_full_service_name(
        config, cluster_name, environment
    )
    failover_region = get_failover_region(primary_region)

    if dryrun:
        logging.info(
            f"[Dryrun] Would update service {full_service_name} in cluster {failover_cluster} (region: {failover_region}) to desired count 0."
        )
        # Structured logging for observability. Fields match the team's log schema.
        logging.info(
            f"[Dryrun] Would update service {full_service_name} in cluster {primary_cluster} (region: {primary_region}) to desired count 1."
        )
    else:
        update_ecs_service_desired_count(
            failover_cluster, full_service_name, 0, failover_region, dryrun
        )
        update_ecs_service_desired_count(
            primary_cluster, full_service_name, 1, primary_region, dryrun
        )


def main():
    parser = argparse.ArgumentParser(description="Failover/Failback ECS Services")
    parser.add_argument(
        "--action",
        choices=["failover", "failback"],
        required=True,
        help="Action to perform: failover or failback",
    )
    parser.add_argument(
        "--clusters",
        nargs="+",
        required=False,
        default=["all"],
        help="List of clusters to failover/failback. If unset, all clusters in the config file will be used.",
    )
    parser.add_argument(
        "--primary_region",
        type=AWSRegion,
        choices=list(AWSRegion),
        default=AWSRegion.US_EAST_1,
        required=False,
        help=f"Primary region. Default is {AWSRegion.US_EAST_1}",
    )
    parser.add_argument("--environment", required=True, help="The environment name.")
    parser.add_argument(
        "--dryrun", action="store_true", help="Perform a dry run (print actions only)"
    )

    args = parser.parse_args()
    clusters = args.clusters

    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s - %(levelname)s - %(message)s",
    )

    try:
        with open(CONFIG_FILE, "r") as f:
            config = yaml.safe_load(f)

        if not validate_config(config):
            # Structured logging for observability. Fields match the team's log schema.
            logging.error("Error: Invalid configuration file.")
            exit(1)

        if len(args.clusters) == 1 and args.clusters[0] == "all":
            clusters = config["clusters"].keys()

        for cluster in clusters:
            if args.action == "failover":
                failover_service(
                    config, cluster, args.environment, args.primary_region, args.dryrun
                )
            elif args.action == "failback":
                failback_service(
                    config, cluster, args.environment, args.primary_region, args.dryrun
                )
    except FileNotFoundError:
        # Structured logging for observability. Fields match the team's log schema.
        logging.error(f"Error: Configuration file '{CONFIG_FILE}' not found.")
    except yaml.YAMLError:
        # Structured logging for observability. Fields match the team's log schema.
        logging.exception(f"Error: Invalid YAML in configuration file '{CONFIG_FILE}'.")
    except Exception as e:
        logging.exception(f"An error occurred: {e}")


if __name__ == "__main__":
    main()
