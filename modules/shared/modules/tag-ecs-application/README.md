# TAG ECS Application Terraform Module

## Versioning
The module is versioned with SemVer style tags that have the prefix `tag-ecs-application-`.

Github Actions generates tags like below for each PR that is merged to the master branch:
```
tag-ecs-application-2     # Major version tag
tag-ecs-application-2.1   # Minor version tag
tag-ecs-application-2.1.1 # SemVer tag
```

Major and Minor tags allow a user of the module to reference a minor or major version of the module and receive minor or patch version updates respectively without changing the source e.g.:
```hcl
module "tag_ecs_application" {
  # The latest 1.2.x version of the module will be utilized
  source = "github.com/example-org/shared-terraform//modules/tag-ecs-application?ref=tag-ecs-application-1.2"

  # Omitted
}
```

To bump the major or minor version; create a PR updating the `version-prefix.txt` file and Github Actions will generate new tags when the PR is merged.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.6 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >=5.46 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >=5.46 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_aws_alb"></a> [aws\_alb](#module\_aws\_alb) | terraform-aws-modules/alb/aws//wrappers | 9.9.0 |
| <a name="module_aws_ecs"></a> [aws\_ecs](#module\_aws\_ecs) | terraform-aws-modules/ecs/aws | 5.11.1 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_subscription_filter.application](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_subscription_filter) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS Region to deploy the ECS Service in | `string` | n/a | yes |
| <a name="input_aws_subnets"></a> [aws\_subnets](#input\_aws\_subnets) | AWS Subnets to deploy the ECS Service tasks in | `list(string)` | n/a | yes |
| <a name="input_aws_vpc_id"></a> [aws\_vpc\_id](#input\_aws\_vpc\_id) | AWS VPC to deploy the ECS Service in | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the ECS Cluster | `string` | n/a | yes |
| <a name="input_endpoint_security_cid_arg_arn"></a> [crowdstrike\_cid\_arg\_arn](#input\_crowdstrike\_cid\_arg\_arn) | ARN of the secret containing the Crowdstrike CID used to forward application data to Crowdstrike. Secret value must be in the format "--cid=${CID}" | `string` | n/a | yes |
| <a name="input_crowdstrike_sensor_version"></a> [crowdstrike\_sensor\_version](#input\_crowdstrike\_sensor\_version) | Crowdstrike Sensor version to use for the Crowdstrike init container. See https://registry.example.io/ui/repos/tree/General/crowdstrike-docker-prod-federated-us/falcon-container-sensor for the latest version. | `string` | `"7.17.0-5602.container.x86_64.Release.US-1"` | no |
| <a name="input_datadog_api_key_secret_arn"></a> [datadog\_api\_key\_secret\_arn](#input\_datadog\_api\_key\_secret\_arn) | ARN of the secret containing the Datadog API Key used to forward application data to Datadog | `string` | n/a | yes |
| <a name="input_datadog_image"></a> [datadog\_image](#input\_datadog\_image) | Datadog Docker image to use for the Datadog sidecar container | `string` | `"registry.example.io/tag-docker-prod-virtual-us/datadog/agent:7.54.0"` | no |
| <a name="input_docker_secret_arn"></a> [docker\_secret\_arn](#input\_docker\_secret\_arn) | ARN of the AWS Secrets Manager Secret containing the Docker credentials for retrieving Docker images | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment to deploy the ECS Service in | `string` | n/a | yes |
| <a name="input_load_balancer_defaults"></a> [load\_balancer\_defaults](#input\_load\_balancer\_defaults) | Map of default configuration for load balancers created by the 'load\_balancers' variable, refer to the 'defaults' variable of the terraform-aws-modules/alb/aws//wrappers module. | `any` | `{}` | no |
| <a name="input_load_balancers"></a> [load\_balancers](#input\_load\_balancers) | Map of AWS load balancers (ALB/NLB) to create, refer to the 'items' variable of the terraform-aws-modules/alb/aws//wrappers module. | `any` | `{}` | no |
| <a name="input_log_lambda_arn"></a> [log\_lambda\_arn](#input\_log\_lambda\_arn) | ARN of the Lambda function to forward application logs to | `string` | n/a | yes |
| <a name="input_services"></a> [services](#input\_services) | Map of services to deploy in the ECS Cluster, refer to the 'services' variable of the terraform-aws-modules/ecs/aws module.<br><br>Required special attributes for each element in the map:<br>`application_image` (string): Docker image to run as the main application container<br>`application_run_command` (string): Command to run inside the main application Docker image to start the application e.g. \"exec /app/my-app\"<br><br>Optional special attributes for each element in the map:<br>`application_environment_variables` (map(string)): Environment variables to pass to the application container. Key is name of the environment variable. Value is the value of the environment variable.<br>`application_log_subscription_filter_name` (string): Name of the CloudWatch Log Subscription Filter to create for the application container. Defaults to \"<service\_name>-application\"<br>`application_port_mappings` (list(object({containerPort = number, hostPort = number, protocol = string}))): List of port mappings to expose from the application container. Each element in the list must have the following attributes:<br>  `containerPort` (number): Port inside the application container to expose<br>  `hostPort` (number): Port on the host to expose the application container port to<br>  `protocol` (string): Protocol to use for the port mapping, either 'tcp' or 'udp'<br>`application_secret_arns` (map(string)): Secrets to pass as environment varibles to the application container. Key is name of the environment variable. Value must be an SSM Parameter Store parameter or a Secrets Manager secret ARN.<br>`application_target_groups` (list(object({load\_balancer = string, target\_group = string}))): List of target groups to attach to the application container. Each element in the list must have the following attributes:<br>  `load_balancer` (string): Key of the load balancer in the 'load\_balancers' map to attach the target group to<br>  `target_group` (string): Key of the target group in the 'load\_balancers' map to attach the application container to<br>  \_\_NOTE\_\_: This only works for target groups created by this instance of the module. For externally managed target groups, use the `load_balancer` attribute instead.<br>  \_\_NOTE\_\_: The `create_attachment` attribute in the target group should be set to `false` as AWS ECS will manage the targets<br>`crowdstrike_environment_variables` (map(string)): Environment variables to pass to the CrowdStrike Falcon init container. Key is name of the environment variable. Value is the value of the environment variable.<br>`datadog_environment_variables` (map(string)): Environment variables to pass to the Datadog sidecar container. Key is name of the environment variable. Value is the value of the environment variable.<br>`datadog_port_mappings` (list(object({containerPort = number, hostPort = number, protocol = string}))): List of port mappings to expose from the Datadog sidecar container. Each element in the list must have the following attributes:<br>  `containerPort` (number): Port inside the Datadog sidecar container to expose<br>  `hostPort` (number): Port on the host to expose the Datadog sidecar container port to<br>  `protocol` (string): Protocol to use for the port mapping, either 'tcp' or 'udp'<br>`enable_datadog_sidecar` (bool): Whether to enable the Datadog sidecar container. Defaults to true. | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ecs"></a> [ecs](#output\_ecs) | ECS resources created by the module |
| <a name="output_load_balancers"></a> [load\_balancers](#output\_load\_balancers) | Load balancers created by the module |
<!-- END_TF_DOCS -->