variable "domain_name" {
  description = "Domain name of the cloudfront distribution"
  type        = string
}

variable "zone" {
  description = "Route53 zone for the new domain"
  type        = string
}

variable "certificate_arn" {
  description = "ARN of SSL certificate"
  type        = string
}

variable "root_object" {
  description = "Name of the index file"
  type = string
}

variable "source_dir" {
  description = "Path to directory to sync to S3"
  type        = string
}