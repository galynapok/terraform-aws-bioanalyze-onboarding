output "aurora_endpoints" {
  description = "List of database endpoints"
  value       = module.registration.aurora_endpoints
}

output "user" {
  description = "IAM user name"
  value       = module.registration.user
}

output "bucket_domain_name" {
  description = "User S3 bucket domain name"
  value       = module.registration.bucket_domain_name
}
