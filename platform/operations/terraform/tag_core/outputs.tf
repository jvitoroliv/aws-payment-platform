# outputs.tf
# Part of the output value definitions module.

output "previous" {
  value = {
    mock_version = local.mock_version
    active_region = local.active_region
  }
}
