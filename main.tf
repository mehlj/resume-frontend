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

resource "aws_s3_bucket_object" "website_contents" {
  for_each = fileset("./src/", "**")
  bucket = aws_s3_bucket.mehlj-resume.bucket
  key = each.value
  source = "./src/${each.value}"
  etag = filemd5("./src/${each.value}")
  content_type = "text/html"
}