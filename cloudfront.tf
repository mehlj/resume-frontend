locals {
  s3_origin_id = "mehljresumeS3Origin"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name  = aws_s3_bucket.mehlj-resume.bucket_regional_domain_name
    origin_id    = local.s3_origin_id
  }

  aliases = ["resume.justenmehl.com"]

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "resume.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_100" # NA and Europe

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate_validation.cert_validate.certificate_arn
    ssl_support_method = "sni-only"
  }
}