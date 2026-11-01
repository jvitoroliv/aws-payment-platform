# producer_failover.py

Use the boto3 library to interact with AWS ECS for performing failover and failback to our Kafka producers.

## install requirements
```bash
pip install -r requirements.txt
```

## run tests

```bash
python3 -m unittest test_producer_failover.py
```

## Usage

type `python3 producer_failover.py --help` for available options

## Example (dryrun)

```bash
python3 producer_failover.py --config_file ecs_config.yaml --action failover --environment=test --dryrun
2025-03-20 21:41:36,457 - INFO - [Dryrun] Would update service test-company-producer in cluster test-us-east-1-company (region: us-east-1) to desired count 0.
2025-03-20 21:41:36,457 - INFO - [Dryrun] Would update service test-company-producer in cluster test-us-west-2-company (region: us-west-2) to desired count 1.
2025-03-20 21:41:36,457 - INFO - [Dryrun] Would update service test-ledger-producer in cluster test-us-east-1-ledger (region: us-east-1) to desired count 0.
2025-03-20 21:41:36,457 - INFO - [Dryrun] Would update service test-ledger-producer in cluster test-us-west-2-ledger (region: us-west-2) to desired count 1.
2025-03-20 21:41:36,457 - INFO - [Dryrun] Would update service test-exception-producer in cluster test-us-east-1-non-posted-exceptions (region: us-east-1) to desired count 0.
2025-03-20 21:41:36,457 - INFO - [Dryrun] Would update service test-exception-producer in cluster test-us-west-2-non-posted-exceptions (region: us-west-2) to desired count 1.
2025-03-20 21:41:36,457 - INFO - [Dryrun] Would update service test-company-statements-ecs-service in cluster test-us-east-1-company-statements (region: us-east-1) to desired count 0.
2025-03-20 21:41:36,457 - INFO - [Dryrun] Would update service test-company-statements-ecs-service in cluster test-us-west-2-company-statements (region: us-west-2) to desired count 1.
2025-03-20 21:41:36,457 - INFO - [Dryrun] Would update service test-statement-cycle-producer in cluster test-us-east-1-statement-cycle (region: us-east-1) to desired count 0.
2025-03-20 21:41:36,457 - INFO - [Dryrun] Would update service test-statement-cycle-producer in cluster test-us-west-2-statement-cycle (region: us-west-2) to desired count 1.
2025-03-20 21:41:36,457 - INFO - [Dryrun] Would update service test-unpaid-balances-ecs-service in cluster test-us-east-1-unpaid-balances (region: us-east-1) to desired count 0.
2025-03-20 21:41:36,457 - INFO - [Dryrun] Would update service test-unpaid-balances-ecs-service in cluster test-us-west-2-unpaid-balances (region: us-west-2) to desired count 1
```

## Example (actual)

```bash
python producer_failover.py --config_file ecs_config.yaml --action failback --environment=test
2025-03-20 22:10:12,077 - INFO - Found credentials in shared credentials file: ~/.aws/credentials
2025-03-20 22:10:12,830 - INFO - Successfully updated service test-company-producer in cluster test-us-west-2-company (region: us-west-2) to desired count 0.
2025-03-20 22:10:13,736 - INFO - Successfully updated service test-company-producer in cluster test-us-east-1-company (region: us-east-1) to desired count 1.
2025-03-20 22:10:14,196 - INFO - Successfully updated service test-ledger-producer in cluster test-us-west-2-ledger (region: us-west-2) to desired count 0.
2025-03-20 22:10:14,883 - INFO - Successfully updated service test-ledger-producer in cluster test-us-east-1-ledger (region: us-east-1) to desired count 1.
2025-03-20 22:10:15,349 - INFO - Successfully updated service test-exception-producer in cluster test-us-west-2-non-posted-exceptions (region: us-west-2) to desired count 0.
2025-03-20 22:10:16,068 - INFO - Successfully updated service test-exception-producer in cluster test-us-east-1-non-posted-exceptions (region: us-east-1) to desired count 1.
2025-03-20 22:10:16,509 - INFO - Successfully updated service test-company-statements-ecs-service in cluster test-us-west-2-company-statements (region: us-west-2) to desired count 0.
2025-03-20 22:10:17,259 - INFO - Successfully updated service test-company-statements-ecs-service in cluster test-us-east-1-company-statements (region: us-east-1) to desired count 1.
2025-03-20 22:10:17,698 - INFO - Successfully updated service test-statement-cycle-producer in cluster test-us-west-2-statement-cycle (region: us-west-2) to desired count 0.
2025-03-20 22:10:18,421 - INFO - Successfully updated service test-statement-cycle-producer in cluster test-us-east-1-statement-cycle (region: us-east-1) to desired count 1.
2025-03-20 22:10:18,865 - INFO - Successfully updated service test-unpaid-balances-ecs-service in cluster test-us-west-2-unpaid-balances (region: us-west-2) to desired count 0.
2025-03-20 22:10:19,578 - INFO - Successfully updated service test-unpaid-balances-ecs-service in cluster test-us-east-1-unpaid-balances (region: us-east-1) to desired count 1.
```
