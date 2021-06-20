provider "aws" {
  region = "eu-central-1"
}

provider "aws" {
  alias = "virginia"
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "cv.appr.me.tf"
    key    = "prod"
    region = "eu-central-1"
  }
}

module "acm" {
  source = "../modules/acm/"

  domain_name       = "cv.appr.me"
  alternative_names = []
  zone              = "appr.me"
  providers = {
    aws = aws.virginia
  }
}

module "cdn" {
  source = "../modules/cdn/"

  certificate_arn = module.acm.certificate_arn
  domain_name     = "cv.appr.me"
  zone            = "appr.me"

  root_object = {
    name        = var.input_name
    source      = abspath(var.input_path)
    type        = "application/pdf"
    disposition = "inline; filename=\"${var.input_name}\""
  }
}
