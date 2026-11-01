# locals.tf
# Manages local value computations resources.

# Static variables
locals {
  app_name                    = "INSERT_APP_NAME" # Logical name of the application. Should be equal to the name of subfolder used by the application in the repository.
  long_app_name               = "INSERT_APP_NAME" # Applicaiton name replacing periods with underscores. This is needed in order to create some AWS resources that have special character constraints in the resource name.
  short_app_name              = "INSERT_APP_NAME" # Short version of the application name. This is needed in order to create some AWS resources that have length constraints in the resource name.
  ecr_repository_name         = "platform-services-ecr"      # The name of the AWS ECR cluster in the PLATFORM-SERVICES accounts
  lambda_dotnet_main_assembly = "INSERT_APP_NAME" # The name of the main assembly of the application. This is used to set the LAMBDA_DOTNET_MAIN_ASSEMBLY environment variable.
  lambda_command = [                              # The command to run when the Lambda function is invoked. This is used to set the LAMBDA_COMMAND environment variable.
    "INSERT_APP_NAME"
  ]

  cloudwatch_rule_enabled = {
    test  = false
    stage = false
    prod  = false
  }

  enable_datadog = {
    test  = false
    stage = false
    prod  = true
  }

  dotnet_environment = {
    test  = "test"
    stage = "stage"
    prod  = "prod"
  }

  ecr_repository_host = {
    test  = "111111111111.dkr.ecr.us-east-1.amazonaws.com"
    stage = "555555555555.dkr.ecr.us-east-1.amazonaws.com"
    prod  = "666666666666.dkr.ecr.us-east-1.amazonaws.com"
  }

  region = {
    test  = "us-east-1"
    stage = "us-east-1"
    prod  = "us-east-1"
  }

  vpc_name = {
    test  = "VPC-CORP-TEST"
    stage = "CORP-PAYMENTS-DEMO-VPC"
    prod  = "CORP-Prod-VPC"
  }
}

# Compose variables
locals {
  lambda_image_uri = "${local.ecr_repository_host[terraform.workspace]}/${local.ecr_repository_name}/${local.app_name}:${var.variable_map["buildNumber"]}"
}
