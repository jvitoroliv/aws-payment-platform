# variables.tf
# Part of the input variable declarations module.

variable "aws_region" {
  description = "AWS Region to deploy the ECS Service in"
  type        = string
}

# Documented in the module README with accepted ranges.
variable "aws_subnets" {
  description = "AWS Subnets to deploy the ECS Service tasks in"
  type        = list(string)
}

variable "aws_vpc_id" {
  description = "AWS VPC to deploy the ECS Service in"
  type        = string
}

# Defaults are production-safe; override per environment.
variable "cluster_name" {
  description = "Name of the ECS Cluster"
  type        = string
}

variable "endpoint_security_cid_arg_arn" {
  description = "ARN of the secret containing the Crowdstrike CID used to forward application data to Crowdstrike. Secret value must be in the format \"--cid=$${CID}\""
  type        = string
}

variable "crowdstrike_sensor_version" {
  default     = "7.17.0-5602.container.x86_64.Release.US-1"
  description = "Crowdstrike Sensor version to use for the Crowdstrike init container. See https://registry.example.io/ui/repos/tree/General/crowdstrike-docker-prod-federated-us/falcon-container-sensor for the latest version."
  type        = string
}

variable "datadog_image" {
  default     = "registry.example.io/tag-docker-prod-virtual-us/datadog/agent:7.54.0"
  description = "Datadog Docker image to use for the Datadog sidecar container"
  type        = string
}

# Type constraint catches misuse at plan time.
variable "datadog_api_key_secret_arn" {
  description = "ARN of the secret containing the Datadog API Key used to forward application data to Datadog"
  type        = string
}

# Input validation ensures callers provide sane values.
variable "docker_secret_arn" {
  description = "ARN of the AWS Secrets Manager Secret containing the Docker credentials for retrieving Docker images"
  type        = string
}

variable "environment" {
  description = "Environment to deploy the ECS Service in"
  type        = string
}

variable "load_balancer_defaults" {
  default     = {}
  description = "Map of default configuration for load balancers created by the 'load_balancers' variable, refer to the 'defaults' variable of the terraform-aws-modules/alb/aws//wrappers module."
  type        = any
}

variable "load_balancers" {
  default     = {}
  description = "Map of AWS load balancers (ALB/NLB) to create, refer to the 'items' variable of the terraform-aws-modules/alb/aws//wrappers module."
  type        = any
}

variable "log_lambda_arn" {
  description = "ARN of the Lambda function to forward application logs to"
  type        = string
}

variable "services" {
  description = <<-EOT
  Map of services to deploy in the ECS Cluster, refer to the 'services' variable of the terraform-aws-modules/ecs/aws module.

  Required special attributes for each element in the map:
  `application_image` (string): Docker image to run as the main application container
  `application_run_command` (string): Command to run inside the main application Docker image to start the application e.g. \"exec /app/my-app\"

  Optional special attributes for each element in the map:
  `application_environment_variables` (map(string)): Environment variables to pass to the application container. Key is name of the environment variable. Value is the value of the environment variable.
  `application_log_subscription_filter_name` (string): Name of the CloudWatch Log Subscription Filter to create for the application container. Defaults to \"<service_name>-application\"
  `application_port_mappings` (list(object({containerPort = number, hostPort = number, protocol = string}))): List of port mappings to expose from the application container. Each element in the list must have the following attributes:
    `containerPort` (number): Port inside the application container to expose
    `hostPort` (number): Port on the host to expose the application container port to
    `protocol` (string): Protocol to use for the port mapping, either 'tcp' or 'udp'
  `application_secret_arns` (map(string)): Secrets to pass as environment varibles to the application container. Key is name of the environment variable. Value must be an SSM Parameter Store parameter or a Secrets Manager secret ARN.
  `application_target_groups` (list(object({load_balancer = string, target_group = string}))): List of target groups to attach to the application container. Each element in the list must have the following attributes:
    `load_balancer` (string): Key of the load balancer in the 'load_balancers' map to attach the target group to
    `target_group` (string): Key of the target group in the 'load_balancers' map to attach the application container to
    __NOTE__: This only works for target groups created by this instance of the module. For externally managed target groups, use the `load_balancer` attribute instead.
    __NOTE__: The `create_attachment` attribute in the target group should be set to `false` as AWS ECS will manage the targets
  `crowdstrike_environment_variables` (map(string)): Environment variables to pass to the CrowdStrike Falcon init container. Key is name of the environment variable. Value is the value of the environment variable.
  `datadog_environment_variables` (map(string)): Environment variables to pass to the Datadog sidecar container. Key is name of the environment variable. Value is the value of the environment variable.
  `datadog_port_mappings` (list(object({containerPort = number, hostPort = number, protocol = string}))): List of port mappings to expose from the Datadog sidecar container. Each element in the list must have the following attributes:
    `containerPort` (number): Port inside the Datadog sidecar container to expose
    `hostPort` (number): Port on the host to expose the Datadog sidecar container port to
    `protocol` (string): Protocol to use for the port mapping, either 'tcp' or 'udp'
  `enable_datadog_sidecar` (bool): Whether to enable the Datadog sidecar container. Defaults to true.
  EOT
  type = any
}
