# prod_state_store.tf
# Manages prod_state_store Terraform configuration resources.

# create an S3 bucket to store the state file in
# Encryption at rest is enforced via bucket policy.
resource "aws_s3_bucket" "prod-terraform-state-storage-s3" {
  count  = var.is_prod == "true" ? 1 : 0
  bucket = "corp-prod-terraform-state-store-${var.aws_bucket_region}"
  region = var.aws_bucket_region
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  versioning {
    enabled = true
  }
  # Lifecycle rules prevent Terraform from reverting auto-scaled or externally managed attributes
  lifecycle {
    prevent_destroy = true
  }
  tags = {
    Name = "S3 Remote Prod Terraform State Store"
  }
}

resource "aws_s3_bucket_object" "prod-state_folder" {
  count                  = var.is_prod == "true" ? 1 : 0
  key                    = format("env:/%v/", "prod")
  bucket                 = aws_s3_bucket.prod-terraform-state-storage-s3[0].id
  source                 = "/dev/null"
  server_side_encryption = "AES256"
}

resource "aws_dynamodb_table" "prod-terraform-state-lock-dynamodb" {
  count          = var.is_prod == "true" ? 1 : 0
  name           = "tag-prod-state-store"
  hash_key       = "LockID"
  read_capacity  = 20
  write_capacity = 20
  attribute {
    name = "LockID"
    type = "S"
  }
  tags = {
    Name = "DynamoDB Prod Terraform State Lock Table"
  }
}
