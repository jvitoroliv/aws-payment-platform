environment               = "dev"
region                    = "us-east-1"
subnet_ids                = ["subnet-0example000000001", "subnet-0example000000002", "subnet-0example000000003"]
vpc_id                    = "vpc-0example000000001"
aws_account_number        = "111111111111"
mongo_uri                 = "mongodb+srv://test-cluster.example.mongodb.net/dev?retryWrites=true&w=majority"
mongo_username            = "chronos"
concurrent_executions     = 50
artifact_bucket           = "dev-us-east-1-app-artifacts-lambda"
aging_event_sns_topic_arn = ""
card-processor_queue_arn        = "arn:aws:sqs:us-east-1:999999999999:dev-us-east-1-card-processor"
statements_queue_arn      = "arn:aws:sqs:us-east-1:999999999999:dev-us-east-1-statements"
memsize                   = 2048
scheduled_event_enabled   = true
