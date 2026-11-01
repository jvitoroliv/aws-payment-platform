## Getting Started
**Prereqs:**
1. Ensure you have docker installed. 

2. Ensure you have jq installed. 

3. Ensure you have the latest localstack container. 
    NOTE: docker pull localstack/localstack. 

##  Deploying
1. Run the start_localstack.sh script from docker/localstack.

## Shutting down
1. Run the stop_localstack.sh script from docker/localstack directory. 

## Troubleshooting
1. start_localstack.sh stick on "Waiting on localstack_main to be ready."
    run stop_localstack script to kill existing sessions, then rerun start. 

2. Terraform Stalls creating aws_cloudwatch_event_rule. 
    Ensure the local environments active region is set to "__local__"
