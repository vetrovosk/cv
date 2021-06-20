output "certificate_arn" {
  description = "ARN of certificate"
  value       = aws_acm_certificate.default.arn
}
