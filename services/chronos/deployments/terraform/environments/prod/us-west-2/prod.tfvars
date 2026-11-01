environment               = "prod"
region                    = "us-west-2"
subnet_ids                = ["subnet-0example000000001", "subnet-0example000000002", "subnet-0example000000003"]
vpc_id                    = "vpc-0example000000001"
aws_account_number        = "222222222222"
mongo_uri                 = "mongodb+srv://cluster-prod.example.mongodb.net/test?retryWrites=true&w=majority"
mongo_username            = "chronos"
artifact_bucket           = "prod-us-west-2-app-artifacts-lambda"
aging_event_sns_topic_arn = "arn:aws:sns:us-west-2:999999999999:prod-us-west-2-aging-event"
card-processor_queue_arn        = "arn:aws:sqs:us-west-2:999999999999:prod-us-west-2-card-processor"
statements_queue_arn      = "arn:aws:sqs:us-west-2:999999999999:prod-us-west-2-statements"
memsize                   = 2048
scheduled_event_enabled   = true
