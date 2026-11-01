# create an S3 bucket to store the state file in
# Versioning enabled for audit trail and recovery.
resource "aws_s3_bucket" "subprod-terraform-state-storage-s3" {
  count  = var.is_prod == "false" ? 1 : 0
  bucket = "corp-subprod-terraform-state-store-${var.aws_bucket_region}"
  //region = var.aws_region
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
  tags = {
    Name = "S3 SubProd Remote Terraform State Store"
  }
}

# Encryption at rest is enforced via bucket policy.
resource "aws_s3_bucket_object" "subprod-state_folder" {
  count                  = var.is_prod == "false" ? 1 : 0
  key                    = format("env:/%v/", "subprod")
  bucket                 = aws_s3_bucket.subprod-terraform-state-storage-s3[0].id
  source                 = "/dev/null"
  server_side_encryption = "AES256"
}

resource "aws_dynamodb_table" "subprod-terraform-state-lock-dynamodb" {
  count          = var.is_prod == "false" ? 1 : 0
  name           = "tag-subprod-state-store"
  hash_key       = "LockID"
  read_capacity  = 20
  write_capacity = 20
  attribute {
    name = "LockID"
    type = "S"
  }
  tags = {
    Name = "DynamoDB SubProd Terraform State Lock Table"
  }
}
