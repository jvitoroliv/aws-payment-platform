# ATC Module
- This module is built to help control the traffic between our ALB regions
- Eventually it could be used for blue / green cutover on stack by revision but for now it routes by region

## Configuration

### Adding new records
Add a new element to `var.records` in the `${env}.tfvars` file of the target deployment environment.

`var.records` is a map of which the name is the name of the DNS records to create. The `targets` map within each element contains each destination DNS record to route to.

Multiple targets can be created with differing routing weights. The weight determines what proportion of traffic will be routed to the target.

### Updating the routing

The portion of traffic routed to each target corresponds to its configured weight in proportion to the total weight of all weighted records of the same name.
For more information see the [AWS docs](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/routing-policy-weighted.html).

Update the `weight` of the targets in the `${env.tfvars}` to adjust the routing portions.

For TAG, the routing is primarily used to handle failover between two AWS Regions. The primary region is `us-east-1` which normally receives all of the traffic. The secondary region is `us-west-2` which generally only receives traffic if there is a problem in `us-east-1`.

#### Examples
_Note_: Some attributes are redacted to simplify the examples

1. __All traffic routed to one target__:
    ```hcl
    # All traffic will be routed to the `us-east-1` target
    "dev.example.com" = {
        targets = {
            "us-east-1" = {
                weight = 100
            }
            "us-west-2" = {
                weight = 0
            }
        }
    }
    ```

1. __Traffic is shared evenly between multiple targets__:
    ```hcl
    # Each target receives one third of the traffic
    "dev.example.com" = {
        targets = {
            "us-east-1" = {
                weight = 100
            }
            "us-west-2" = {
                weight = 100
            }
            "us-west-1" = {
                weight = 100
            }
        }
    }
    ```

1. __Traffic is shared unevenly between multiple targets__:
    ```hcl
    # The us-east-1 target receives half of the traffic, others receive a quarter
    "dev.example.com" = {
        targets = {
            "us-east-1" = {
                weight = 50
            }
            "us-west-2" = {
                weight = 25
            }
            "us-west-1" = {
                weight = 25
            }
        }
    }
    ```

### Using Terraform to apply changes
_Note_: Replace `${env}` with the target deployment environment e.g. `dev`, `test`, `stage`, `prod`

1. Connect to theVPN
1. Retrieve fresh AWS credentials: `oktaws default`
1. Initialize Terraform for the target deployment environment: `terraform init -backend-config=envs/${env}/${env}.backend`
1. Generate a Terraform plan: `terraform plan --var-file=envs/${env}/${env}.tfvars -out.tf.plan`
1. Carefully validate the changes in the plan. DNS changes can cause an outage so be careful.
1. Apply the validated changes: `terraform apply tf.plan`
