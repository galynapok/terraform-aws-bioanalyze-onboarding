
output "aurora_endpoints" {
  value = [for item in module.rds_cluster_aurora: try(item.endpoint, "")]
}

output "user" {
  value = try(module.aws_user.user_name, "") 
}

output "user_access_key_id" {
  value = try(module.aws_user.access_key_id, "") 
} 

output "secret_access_key" {
  value = try(module.aws_user.secret_access_key, "") 
} 

output "db_secrets" {
  value = [for item in aws_secretsmanager_secret.db_secret: try(item.name, "")]
}

output "s3_bucket" {
  value = try(module.s3_bucket.bucket_domain_name, "") 
}

output "bioanalyze_endpoint_lb" {
  value = try(data.aws_elb.bioanalyze-app[0].name, "") 
}