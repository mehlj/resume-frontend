resource "aws_s3_bucket" "mehlj-resume" {
  bucket = "s3-website-test.hashicorp.com"
  acl    = "public-read"
}


resource "aws_s3_bucket_website_configuration" "mehlj-resume-host" {
  bucket = aws_s3_bucket.mehlj-resume.bucket

  index_document {
    suffix = "resume.html"
  }
}