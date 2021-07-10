resource "aws_s3_bucket" "public" {
  bucket = "${var.domain_name}-cdn"
  acl    = "private"

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = []
    max_age_seconds = 86400
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.public.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_identity" "cloudfront" {
  comment = "Created by terraform"
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.public.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.cloudfront.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "policy" {
  bucket = aws_s3_bucket.public.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

locals {
  s3_origin_id = aws_s3_bucket.public.bucket
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.public.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.cloudfront.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Created by terraform"
  default_root_object = var.root_object

  aliases = [var.domain_name]

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

    min_ttl                = 0
    default_ttl            = 31536000
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = var.certificate_arn
    minimum_protocol_version       = "TLSv1.2_2019"
    ssl_support_method             = "sni-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

data "aws_route53_zone" "zone" {
  name         = "${var.zone}."
  private_zone = false
}

resource "aws_route53_record" "a" {
  zone_id  = data.aws_route53_zone.zone.id
  name     = var.domain_name
  for_each = toset(["A", "AAAA"])
  type     = each.key

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

locals {
  pdf = "^.*(\\.pdf)$"
}

resource "aws_s3_bucket_object" "object" {
  for_each = fileset(var.source_dir, "*")

  bucket              = aws_s3_bucket.public.id
  key                 = each.value
  source              = "${var.source_dir}/${each.value}"
  etag                = filemd5("${var.source_dir}/${each.value}")
  content_type        = contains(regex(local.pdf, each.value), ".pdf") ? "application/pdf" : null
  content_disposition = contains(regex(local.pdf, each.value), ".pdf") ? "inline; filename=\"${each.value}\"" : null
}

locals {
  etags = sort(tolist([
    for object in aws_s3_bucket_object.object : object.etag
  ]))
}

resource "null_resource" "create-invalidation" {
  provisioner "local-exec" {
    command = "aws cloudfront create-invalidation --region us-east-1 --distribution-id ${aws_cloudfront_distribution.s3_distribution.id} --paths '/' '/*'"
  }

  triggers = {
    etags = join(",", local.etags)
  }
}