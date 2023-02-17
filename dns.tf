data "aws_route53_zone" "main" {
  name = "justenmehl.com."
}

resource "aws_acm_certificate" "cert" {
  provider          = aws.virginia
  domain_name       = "resume.justenmehl.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# cert validation DNS record
resource "aws_route53_record" "cert_dns" {
  allow_overwrite = true
  name            = tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_name
  records         = [tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_value]
  type            = tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_type
  zone_id         = data.aws_route53_zone.main.zone_id
  ttl             = 60
  provider        = aws.virginia
}

resource "aws_acm_certificate_validation" "cert_validate" {
  provider                = aws.virginia
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [aws_route53_record.cert_dns.fqdn]
}

# alias record for cloudfront
resource "aws_route53_record" "cf-record" {
  depends_on = [
    aws_cloudfront_distribution.s3_distribution
  ]

  zone_id = data.aws_route53_zone.main.zone_id
  name    = "resume.justenmehl.com"
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
  provider = aws.virginia
}
