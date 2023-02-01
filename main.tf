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

# You specify origin servers, like an Amazon S3 bucket or your own HTTP server, from which CloudFront gets your files which will then be distributed from CloudFront edge locations all over the world.

# An origin server stores the original, definitive version of your objects. If you're serving content over HTTP, your origin server is either an Amazon S3 bucket or an HTTP server, such as a web server. Your HTTP server can run on an Amazon Elastic Compute Cloud (Amazon EC2) instance or on a server that you manage; these servers are also known as custom origins.

# You upload your files to your origin servers. Your files, also known as objects, typically include web pages, images, and media files, but can be anything that can be served over HTTP.

# If you're using an Amazon S3 bucket as an origin server, you can make the objects in your bucket publicly readable, so that anyone who knows the CloudFront URLs for your objects can access them. You also have the option of keeping objects private and controlling who accesses them. See Serving private content with signed URLs and signed cookies.

# You create a CloudFront distribution, which tells CloudFront which origin servers to get your files from when users request the files through your web site or application. At the same time, you specify details such as whether you want CloudFront to log all requests and whether you want the distribution to be enabled as soon as it's created.

# CloudFront assigns a domain name to your new distribution that you can see in the CloudFront console, or that is returned in the response to a programmatic request, for example, an API request. If you like, you can add an alternate domain name to use instead.

# CloudFront sends your distribution's configuration (but not your content) to all of its edge locations or points of presence (POPs)— collections of servers in geographically-dispersed data centers where CloudFront caches copies of your files.

