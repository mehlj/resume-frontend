resource "aws_s3_bucket" "mehlj-resume" {
  bucket = "mehlj.io"
}

resource "aws_s3_bucket_acl" "resume_bucket_acl" {
  bucket = aws_s3_bucket.mehlj-resume.id
  acl    = "public-read"
}

resource "aws_s3_bucket_policy" "public_access_policy" {
  bucket = aws_s3_bucket.mehlj-resume.id
  policy = data.aws_iam_policy_document.public_access_policy.json
}

data "aws_iam_policy_document" "public_access_policy" {
  statement {
    actions = [
      "s3:GetObject",
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    effect = "Allow"

    resources = [
      aws_s3_bucket.mehlj-resume.arn,
      "${aws_s3_bucket.mehlj-resume.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_website_configuration" "mehlj-resume-host" {
  bucket = aws_s3_bucket.mehlj-resume.bucket

  index_document {
    suffix = "resume.html"
  }
}

resource "aws_s3_object" "html" {
  for_each = fileset("./src/", "**/*.html")

  bucket = aws_s3_bucket.mehlj-resume.bucket
  key = each.value
  source = "./src/${each.value}"
  etag = filemd5("./src/${each.value}")
  content_type = "text/html"
}

resource "aws_s3_object" "css" {
  for_each = fileset("./src/", "**/*.css")

  bucket = aws_s3_bucket.mehlj-resume.bucket
  key = each.value
  source = "./src/${each.value}"
  etag = filemd5("./src/${each.value}")
  content_type = "text/css"
}

resource "aws_s3_object" "images" {
  for_each = fileset("./src/", "**/*.png")

  bucket = aws_s3_bucket.mehlj-resume.bucket
  key = each.value
  source = "./src/${each.value}"
  etag = filemd5("./src/${each.value}")
  content_type = "image/png"
}

# resource "aws_s3_object" "js" {
#   for_each = fileset("./src/", "**/*.js")

#   bucket = aws_s3_bucket.mehlj-resume.bucket
#   key = each.value
#   source = "./src/${each.value}"
#   etag = filemd5("./src/${each.value}")
#   content_type = "application/javascript"
# }



# TODO pick up here, ref: https://www.oss-group.co.nz/blog/automated-certificates-aws

resource "aws_route53_zone" "main" {
  name         = "mehlj.io"
  provider     = aws.virginia
}

resource "aws_acm_certificate" "cert" {
  provider          = aws.virginia
  domain_name       = "mehlj.io"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_dns" {
  allow_overwrite = true
  name            = tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_name
  records         = [tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_value]
  type            = tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_type
  zone_id         = aws_route53_zone.main.zone_id
  ttl             = 60
  provider        = aws.virginia
}

resource "aws_acm_certificate_validation" "cert_validate" {
  provider                = aws.virginia
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [aws_route53_record.cert_dns.fqdn]

  timeouts {
    create = "90m"
  }
}












locals {
  s3_origin_id = "mehljresumeS3Origin"
}


resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name  = aws_s3_bucket.mehlj-resume.bucket_regional_domain_name
    origin_id    = local.s3_origin_id
  }

  aliases = ["mehlj.io"]

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

    viewer_protocol_policy = "allow-all"
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
    acm_certificate_arn = aws_acm_certificate.cert.arn
    ssl_support_method = "sni-only"
  }
}

resource "aws_route53_record" "mehlj-io" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "mehlj.io"
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
  provider = aws.virginia
}