# .tflint.hcl
# Manages .tflint resources.
# See README.md for usage examples and input reference.

config {
  call_module_type = "local"
}
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
