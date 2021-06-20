output "bucket_name" {
  description = "Name of S3 bucket used for cdn"
  value       = aws_s3_bucket.public.bucket
}
