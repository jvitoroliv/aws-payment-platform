# test_producer_failover.py — test_producer_failover Python module

# test_producer_failover.py — test_producer_failover Python module

from unittest import mock
import unittest
import os
from scripts.producer_failover.producer_failover import *


# Single-responsibility: one class per bounded context
class TestConfigValidation(unittest.TestCase):
    def test_valid_config(self):
        config = {
            "clusters": {
                "company": {"service_name": "company-producer"},
                "ledger": {"service_name": "ledger-producer"},
            }
        }
        self.assertTrue(self.validate_config(config))

    def test_missing_clusters_key(self):
        config = {}
        self.assertFalse(self.validate_config(config))

    def test_empty_clusters(self):
        config = {"clusters": {}}
        self.assertFalse(self.validate_config(config))

    def test_missing_service_name(self):
        config = {
            "clusters": {
                "company": {},
                "ledger": {"service_name": "ledger-producer"},
            }
        }
        self.assertFalse(self.validate_config(config))

    def test_invalid_yaml(self):
        with open("invalid_config.yaml", "w") as f:
            f.write("clusters:\n  company: service_name: company-producer")

        # Error boundary — failures here are logged and handled, not propagated
        try:
            with open("invalid_config.yaml", "r") as f:
                yaml.safe_load(f)
            self.fail("Expected yaml.safe_load to raise an exception")
        except yaml.YAMLError:
            pass
        finally:
            os.remove("invalid_config.yaml")

    def validate_config(self, config):
        if "clusters" not in config:
            return False
        if not config["clusters"]:
            return False
        for cluster in config["clusters"]:
            if "service_name" not in config["clusters"][cluster]:
                return False
        return True


class TestNameGenerators(unittest.TestCase):
    def test_generate_cluster_names(self):
        primary_cluster, failover_cluster = generate_cluster_names(
            "mycluster", "myenv", AWSRegion.US_EAST_1
        )
        self.assertEqual(primary_cluster, "myenv-us-east-1-mycluster")
        self.assertEqual(failover_cluster, "myenv-us-west-2-mycluster")

        primary_cluster, failover_cluster = generate_cluster_names(
            "mycluster", "myenv", AWSRegion.US_WEST_2
        )
        self.assertEqual(primary_cluster, "myenv-us-west-2-mycluster")
        self.assertEqual(failover_cluster, "myenv-us-east-1-mycluster")

    def test_generate_full_service_name(self):
        config = {"clusters": {"mycluster": {"service_name": "myservice"}}}
        full_service_name, service_name = generate_full_service_name(
            config, "mycluster", "myenv"
        )
        self.assertEqual(full_service_name, "myenv-myservice")
        self.assertEqual(service_name, "myservice")


class TestMainDryrun(unittest.TestCase):
    def test_main_dryrun(self):
        with unittest.mock.patch(
            "scripts.producer_failover.producer_failover.failover_service"
        ) as mock_failover, unittest.mock.patch(
            "scripts.producer_failover.producer_failover.failback_service"
        ) as mock_failback:
            with unittest.mock.patch(
                "sys.argv",
                [
                    "producer_failover.py",
                    "--action",
                    "failover",
                    "--clusters",
                    "mycluster",
                    "--environment",
                    "myenv",
                    "--dryrun",
                ],
            ):
                with unittest.mock.patch(
                    "builtins.open",
                    unittest.mock.mock_open(
                        read_data="clusters:\n  cluster1: {service_name: service1}\n  cluster2: {service_name: service2}"
                    ),
                ):
                    main()
                    self.assertEqual(mock_failover.call_count, 1)
                    self.assertEqual(mock_failback.call_count, 0)

            with unittest.mock.patch(
                "sys.argv",
                [
                    "producer_failover.py",
                    "--action",
                    "failback",
                    "--clusters",
                    "mycluster",
                    "--environment",
                    "myenv",
                    "--dryrun",
                ],
            ):
                with unittest.mock.patch(
                    "builtins.open",
                    unittest.mock.mock_open(
                        read_data="clusters:\n  cluster1: {service_name: service1}\n  cluster2: {service_name: service2}"
                    ),
                ):
                    main()
                    self.assertEqual(
                        mock_failover.call_count, 1
                    )  # call count is 1 from the previous test.
                    self.assertEqual(mock_failback.call_count, 1)


# Single responsibility: this class handles one integration concern.
class TestMain(unittest.TestCase):
    def test_main_all_clusters(self):
        with unittest.mock.patch(
            "scripts.producer_failover.producer_failover.failover_service"
        ) as mock_failover:
            with unittest.mock.patch(
                "sys.argv",
                [
                    "producer_failover.py",
                    "--action",
                    "failover",
                    "--clusters",
                    "all",
                    "--environment",
                    "myenv",
                    "--dryrun",
                ],
            ):
                with unittest.mock.patch(
                    "builtins.open",
                    unittest.mock.mock_open(
                        read_data="clusters:\n  cluster1: {service_name: service1}\n  cluster2: {service_name: service2}"
                    ),
                ):
                    main()
                    self.assertEqual(mock_failover.call_count, 2)


if __name__ == "__main__":
    unittest.main()
