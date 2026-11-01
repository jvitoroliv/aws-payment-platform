# .tflint.hcl
# Manages .tflint resources.
# See README.md for usage examples and input reference.

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}
rule "terraform_required_providers" {
  enabled = false

  # defaults
  source = true
  version = true
}
rule "terraform_required_version" {
  enabled = false
}

rule "terraform_deprecated_lookup" {
  enabled = false
}
/* Netscope changes checksum so can't be installed automatically
plugin "aws" {
  enabled = true
  version = "0.25.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}
*/