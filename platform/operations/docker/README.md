# docker
***
Dockerfiles for TAG infrastructure

## Overview
***
This directory contains Dockerfiles for various uses in the TAG infrastructure.

## Dockerfiles
***

Dockerfile.tag-terraform
: Builds a docker image with Terraform and other Terraform-related tools installed.
: Used in our CI pipeline to run all `pre-commit` checks. See the [pre-commit config](../.pre-commit-config.yaml) for more information.