# shared-actions

This repository is the home for Tag-related GitHub actions and workflows that are reusable by various means.

[OpsLevel](https://app.opslevel.com/services/example-service)

[DeepSource](https://app.deepsource.com/gh/example-org/shared-actions)

## Table of Contents
- [Available Workflows](#available-workflows)
- [Available Actions](#available-actions)
- [Contributing](#contributing)
- [Versioning](#versioning)
- [Testing](#testing)
- [Pre-commit](#Pre-commit)


## Available Workflows
- [build-service](.github/workflows/build-service.yaml): Microservice build and test workflow
- [deploy-service](.github/workflows/deploy-service.yaml): Microservice deployment workflow

## Available Actions

- [.action_template/composite](/.action_template/composite/): Example composite action
- [.action_template/docker](/.action_template/docker/): Example docker action
- [flyway](flyway/README.md): Flyway migration action
- [gchat](gchat/README.md): gchat notification action

## Contributing

### Creating a new action

For actions the correct directory is `<action_name>/action.yaml`.
There is a script which copies the content of .action_template to a new folder, helping get started with action development.

```sh
# ./help actions create \[path\] \[--description|-d\] "a description for this module" \[--template|-t\] "docker|composite"

./help actions create pre_commit --description "Runs pre-commit hooks on all files" --template "composite"
```

#### List actions

```sh
./help actions list
```

  Be sure to include the following for automated versioning.
  ```yaml
  inputs:
    version:
      description: The semver of the action for automated tagging.
      default: 1.0.1
      required: false
  ```

### Creating a new workflow

  For workflows the correct syntax/location is `.github/workflows/<workflow_name>.yaml`.

  Be sure to include the following for automated versioning.
  ```yaml
  on:
    workflow_call:
      inputs:
        version:
          description: The semver of the workflow for automated tagging.
          default: 1.0.0
          type: string
          required: false
  ```

## Versioning

When using these workflows or actions be mindful to use a pinned version of the workflows, `@v1`, `@v2`, etc. This is to
ensure that you do not accidentally get breaking changes.

```yaml
jobs:
  - name: Example Workflow
    uses: example-org/shared-actions/.github/workflows/example-workflow.yml@example-workflow-v1
```

> These pinned major versions will automatically get patch and minor version updates when they are merged in.

You can use a more
restrictive SemVer such as `v1.0.0`, however you will need to update more regularly to receive patches.

```yaml
jobs:
  - name: Example Workflow
    uses: example-org/shared-actions/.github/workflows/example-workflow.yml@example-workflow-v1.0.0
```

The same applies for actions with slightly different syntax. See `Testing` section below for more details.

### Testing

The pull request workflow will generate a tag matching `<workflow/action-name>>-<version>-pre.<pr-number>` and push it to the respository. You
can test your workflows in your own external repository using the following syntax:

#### Workflows

```yaml
jobs:
  - name: Example Workflow Test
    uses: example-org/shared-actions/.github/workflows/example.yaml@example-v1.0.0-pre.16
```

#### Actions
```yaml
jobs:
  - name: Example Workflow Test
    uses: example-org/shared-actions/example@example-v1.0.0-pre.16
```

  After merging the pull request, release tags will be created for the workflows. See the Versioning section for more details.

## Pre-commit

Before working with this code, please ensure you have `pre-commit` and their required dependencies installed:

``` shell
brew install pre-commit
```
Then, install the pre-commit hooks:

```shell
git config --unset-all core.hooksPath
pre-commit install
```

To run all pre-commit hooks against all files in the repo, run the following:

```sh
pre-commit run --all-files
```

To run a single pre-commit hook against all files in the repo, run the following:
```sh
pre-commit run <hook_id> --all-files
```

Pre-commit hooks are defined in [`.pre-commit-config.yaml`](../.pre-commit-config.yaml)

To skip pre-commit hooks, add the `--no-verify` flag to your git command.


# PR Title Validation Workflow

## Overview
This GitHub Action workflow ensures that all pull requests (PRs) contain a valid Jira ticket in their title.
It performs the following validations:

- Extracts secrets from Vault
- Validates that the PR title starts with a valid Jira ticket ID.
- Ensures the Jira ticket belongs to a specific project.
- Checks if the Jira ticket is active (not `Done` or `Closed`).
- Allows specific users to bypass the validation (bots).

---

## Implementation

### 1. **Adding the Workflow to Your Repository**
Create a new workflow file inside your repository under:
```
.github/workflows/pr-title-check.yaml
```
Copy the following content into your workflow file:

```yaml
---
name: PR Title Validation

on:
  pull_request:

jobs:
  check-title:
    uses: example-org/shared-actions/.github/workflows/pr-title-check.yaml@pr-title-check-v1
    with:
      skip_author_list: "<YOUR_SKIP_AUTHOR_LIST>"
      jira_project: "<YOUR_JIRA_PROJECT_PREFIX>"
```

---

### 2. **Workflow Parameters**
This workflow accepts the following parameters:
- ** `version`**: The semantic version for automated tagging (bump this when updating the workflow, don't define this input when calling)
- **`skip_author_list`**: List of authors to skip validation (default: `app/renovate,app/dependabot`)
- **`jira_project`**: The JIRA project key (the prefix letters of the ticket) used for validation (default: `PROJ`)

If no parameters are provided, the workflow will use the default values listed above.

---

### 3. **How the Workflow Works**
1. **When called (typically on a PR events like creation, edit, or synchronization).**
2. **Retrieves Jira credentials securely from HashCorp Vault.**
3. **Extracts the PR title and checks if it contains a Jira ticket in the correct format.**
4. **Validates that the ticket belongs to the correct project (`JIRA_PROJECT`).**
5. **Queries Jira API to check if the ticket exists and is active.**
6. **Returns an error code (`exit 1`) if any validation fails, which can block the PR if the check is configurated as required in the repository settings**
7. **Allows whitelisted users (`SKIP_AUTHOR_LIST`) to bypass validation.**

---

## **Conclusion**
This workflow enforces **consistent Jira tracking in PR titles**, ensuring every PR is linked to a valid issue in Jira before merging.

# DR Active Region Management Workflow

## Overview
This GitHub Action workflow provides a reusable workflow for managing the active region in a multi-region setup for disaster recovery purposes.
It performs the following operations:

- Validates the active region input is either us-east-1 or us-west-2
- Runs Terraform plan operations for both regions
- Provides a summary of the changes to be made and waits for approval
- Determines the Order to apply changes to the regions so that inactive region changes are applied first
- Applies Terraform changes in the correct order to ensure smooth region transition

---

## Implementation

### 1. **Adding the Workflow to Your Repository**
Create a new workflow file inside your repository under:
```
.github/workflows/dr-active-region-management.yml
```
Copy the following content into your workflow file:

```yaml
---
name: Disaster Recovery Active Region Management

run-name: Set ${{ inputs.active_region }} as the active region in ${{ inputs.environment }}

on:
  workflow_dispatch:
    inputs:
      active_region:
        description: "Active region"
        required: true
        default: "us-east-1"
        type: choice
        options:
          - "us-east-1"
          - "us-west-2"
      environment:
        description: "Environment to run the pipeline for"
        required: true
        default: "dev"
        type: choice
        options:
          - "dev"
          - "test"
          - "stage"
          - "prod"

jobs:
  call-dr-active-region-management:
    uses: example-org/shared-actions/.github/workflows/dr-active-region-management.yml@dr-active-region-management-v1
    with:
      active_region: ${{ inputs.active_region }}
      environment: ${{ inputs.environment }}
      us_east_1_backend_config_path: <path to the backend config file for us-east-1 relative to the working directory>
      us_east_1_var_file_path: <path to the tfvars file for us-east-1 relative to the working directory>
      us_west_2_backend_config_path: <path to the backend config file for us-west-2 relative to the working directory>
      us_west_2_var_file_path: <path to the tfvars file for us-west-2 relative to the working directory>
      working_directory: <path to the Terraform working directory>
```

---

### 2. **Workflow Parameters**
This workflow accepts the following parameters:
- **`version`**: The semantic version for automated tagging (bump this when updating the workflow, don't define this input when calling)
- **`active_region`**: The AWS region to set as active (required, must be `us-east-1` or `us-west-2`)
- **`environment`**: The environment to run the workflow for (required)
- **`us_east_1_backend_config_path`**: Path to Terraform backend config file for us-east-1 region (required)
- **`us_east_1_var_file_path`**: Path to Terraform variables file for us-east-1 region (required)
- **`us_west_2_backend_config_path`**: Path to Terraform backend config file for us-west-2 region (required)
- **`us_west_2_var_file_path`**: Path to Terraform variables file for us-west-2 region (required)
- **`working_directory`**: The directory containing Terraform code (required)

---

### 3. **How the Workflow Works**
1. **Validates inputs** to ensure the active region and environment are valid.
2. **Generates a step summary** to provide clear documentation of what will happen.
3. **Runs Terraform plans** for both regions to determine what changes will be made.
4. **Orders regions** to ensure inactive region changes are applied first, followed by the new active region.
5. **Requests approval** via environment protection rules.
6. **Applies Terraform changes** in the correct order, with fail-fast strategy to stop on first error.
