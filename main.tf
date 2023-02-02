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


locals {
  s3_origin_id = "mehljresumeS3Origin"
}


resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.mehlj-resume.bucket_regional_domain_name
    #origin_access_control_id = aws_cloudfront_origin_access_control.default.id
    origin_id                = local.s3_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "resume.html"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
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
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE", "MX"]
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}