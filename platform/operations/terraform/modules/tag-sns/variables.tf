# variables.tf
# Manages input variable declarations resources.

# Documented in the module README with accepted ranges.
variable "topic_name" {
  type = string
}
variable "tags" {
  type = map(string)
}
