# s3.tf
# Part of the S3 bucket configuration module.

# Versioning enabled for audit trail and recovery.
resource "aws_s3_bucket" "website_bucket" {
  bucket = var.domain
  policy = data.template_file.bucket_policy.rendered

  website {
    index_document = "index.html"
  }
}

data "template_file" "bucket_policy" {
  template = file("${path.module}/policies/s3_ip_restrict_policy.json")

  vars = {
    bucket         = var.domain
    cloudfront_oai = aws_cloudfront_origin_access_identity.origin_access_identity.s3_canonical_user_id
  }
}