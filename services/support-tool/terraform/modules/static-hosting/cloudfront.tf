# cloudfront.tf
# Part of the cloudfront Terraform configuration module.

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "support tool cloudfront origin access identity"
}

resource "aws_cloudfront_distribution" "www_distribution" {

  origin {

    domain_name = format("%s.s3.amazonaws.com", var.domain)
    origin_id   = var.domain

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  web_acl_id          = aws_waf_web_acl.waf_acl.id
  enabled             = true
  default_root_object = "index.html"

  // All values are defaults from the AWS console.
  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = var.domain
    min_ttl                = 0
    default_ttl            = 300
    max_ttl                = 1200

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  aliases = [var.domain]

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = var.ssl_certificate_arn
    ssl_support_method  = "sni-only"
  }

  custom_error_response {
    error_code            = 404
    error_caching_min_ttl = 0
    response_code         = 200
    response_page_path    = "/index.html"
  }
}

// This Route53 record will point at our CloudFront distribution.
resource "aws_route53_record" "www" {
  zone_id = var.hosted_zone_id
  name    = var.domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.www_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.www_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}