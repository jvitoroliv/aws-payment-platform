# terraform
***
TAG infrastructure source code

## Installing Terraform
***
Use `tfenv` to install and manage versions of Terraform.  See [tfenv](https://github.com/tfutils/tfenv) for more information.

```shell
brew install tfenv
```

We're currently using Terraform 1.6.5
```shell
tfenv install 1.6.5
tfenv use 1.6.5
```

## Authentication
***
Install [oktaws](https://auth.docs.apps.example.com/installation/) and run the following command to authenticate with AWS:
```shell
oktaws --region=us-east-1 default
```
Follow the prompts to enter your email, password, and MFA token.
When prompted, choose the number associated with following SAML role:
> 111111111111 - FINSERV TAG Dev-Test    : SAMLDevOpsUserAccess

Your credentials for your `default` profile will be stored in `~/.aws/credentials` and will be valid for 8 hours.

## Initialization
***

Before you begin, make sure you have the `AWS_DEFAULT_REGION` environment variable set. You can do this by running `export AWS_DEFAULT_REGION=us-east-1` or by adding it to your `~/.bash_profile` or `~/.zprofile` file.


Initialize the **global** Terraform resources and generate the plan:
```shell
cd terrafrom/environments/${environment}/global
terraform init -backend-config=dev.backend
terraform plan 
```

Initialize the **tag_core** Terraform and generate the plan:
```shell
cd terrafrom/tag_core
terraform init -backend-config=../environments/${environment}/${region}/${environment}.backend
terraform plan -var-file=../environments/${environment}/${region}/${environment}.tfvars
```

## Development
***
Before starting development, please follow the instructions in the [pre-commit](#pre-commit) section.

TODO: Add instructions for developing Terraform


### Pre-commit
***

Before working with this code, please ensure you have `pre-commit` and their required dependencies installed:

```shell
brew install pre-commit tflint
```

Then, install the pre-commit hooks:

```shell
git config --unset-all core.hooksPath
pre-commit install
```

To run all pre-commit hooks against all files in the repo, run:

```shell
pre-commit run --all-files
```

To run a single pre-commit hooks against all files in the repo, run:
```shell
pre-commit run <hook_id> --all-files
```

Pre-commit hooks are defined in [`.pre-commit-config.yaml`](../.pre-commit-config.yaml)

To skip pre-commit hooks, add the `--no-verify` flag to your git command.

#### Known Issues

None