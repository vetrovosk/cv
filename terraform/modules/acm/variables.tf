variable "domain_name" {
  description = "Domain name"
  type        = string
}

variable "alternative_names" {
  description = "List of subject alternative names"
  type        = list(string)
}

variable "zone" {
  description = "Route53 zone for the new domain"
  type        = string
}
