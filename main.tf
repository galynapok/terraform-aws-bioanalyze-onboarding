locals {
  ingress_enabled     = var.enable_ssl && var.install_ingress == true  ? 1 : 0
  helm_release_values = var.helm_release_values_file != null && var.helm_release_values_file != "" ? [file(var.helm_release_values_file)] : []
  helm_release_merged_values_file = abspath("helm_charts/computed-${random_string.computed_values.result}-values.yaml")

} 
resource "random_string" "computed_values" {
  length           = 10
  special          = false
  lower            = true
  upper            = false
  override_special = ""
}

#########################################################################
# Terraform state backend with state lock 
#########################################################################
module "terraform_state_backend" {
   enabled    = module.this.enabled
   source = "cloudposse/tfstate-backend/aws"
   context = module.this.context
   attributes = ["state"]
   dynamodb_enabled =true
   enable_server_side_encryption = true
   acl = "private"
   terraform_backend_config_file_path = "."
   terraform_backend_config_file_name = "backend.tf"
   force_destroy                      = false
}

 #########################################################################
 # S3 bucket for user resources
 #########################################################################

module "s3_bucket" {
  enabled    = module.this.enabled
  source = "cloudposse/s3-bucket/aws"
  context = module.this.context
  versioning_enabled       = var.s3_versioning
  acl                      = "private"
  user_enabled             = false
  allowed_bucket_actions   = ["s3:GetObject", "s3:ListBucket", "s3:GetBucketLocation"]
}


 #########################################################################
 # IAM user 
 #########################################################################

module "aws_user" {
  source        = "cloudposse/iam-system-user/aws"
  version       = "0.22.5"
  path          = var.path
  context = module.this.context
}
 #########################################################################
 # Two AWS RDS Aurora Postgresql databases - One for Airflow
 # and one for BioAnalyze with backups, replications, etc. 
 #########################################################################

resource "random_password" "password" {
  for_each = var.databases
  length = 24
  special = true
  override_special = "_%@"

}

module "rds_cluster_aurora" {
  for_each         = var.databases
  source           = "cloudposse/rds-cluster/aws"
  engine_mode      = try(each.value.engine_mode, "provisioned")
  context          = module.this.context
  cluster_family   = try(each.value.cluster_family, "aurora-postgresql12")
  engine           = try(each.value.engine, "aurora-postgresql")
  cluster_size     = try(each.value.cluster_size, 0)
  admin_user       = try(each.value.admin_user, "admin")
  admin_password   = try(each.value.admin_password, aws_secretsmanager_secret_version.db-pass-val[each.key].secret_string)
  db_name          = each.key
  instance_type    = each.value.instance_type
  vpc_id           = var.vpc_id 
  security_groups  = try(each.value.security_groups, [])
  subnets          = var.subnets
  retention_period = try(each.value.retention_period, 5)  
  backup_window    = try(each.value.backup_window, "07:00-09:00")
  name             = each.value.name
  db_port          = try(each.value.db_port, 5432)
}


 #########################################################################
 # Create AWS Secrets for Airflow and BioAnalyze app with user access 
 #########################################################################

resource "aws_secretsmanager_secret" "db_secret" {
  for_each = var.databases
  name = format("%s-%s-aurora-master-password", var.name, each.key) 
}

resource "aws_secretsmanager_secret_version" "db-pass-val" {
  for_each = var.databases
   secret_id     = aws_secretsmanager_secret.db_secret[each.key].id
   secret_string = random_password.password[each.key].result
    lifecycle {
     ignore_changes = [secret_string]
    }
}
 
data "aws_iam_policy_document" "secret" {
  for_each = var.databases
  statement {
    actions   = ["secretsmanager:GetResourcePolicy", "secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret","secretsmanager:ListSecretVersionIds"]
    resources = [aws_secretsmanager_secret.db_secret[each.key].arn]
    effect    = "Allow"
  }
  statement {
    actions   = ["secretsmanager:ListSecrets", "secretsmanager:ListSecrets"]
    resources = ["*"]
    effect    = "Allow"
  }
}

resource "aws_iam_user_policy" "secret" {
  for_each = var.databases   
  name_prefix   = format("%s-secret-%s", module.aws_user.user_name, each.key)
  user   = module.aws_user.user_name
  policy = join("", data.aws_iam_policy_document.secret[each.key].*.json)
}



 #########################################################################
 # Create user policy for the state backend(s3 + dynamodb), 
 # the user resource s3 bucket
 #########################################################################
data "aws_iam_policy_document" "bucket" {
  count = module.this.enabled ? 1 : 0

  statement {
    actions   = ["s3:GetObject", "s3:ListBucket", "s3:GetBucketLocation"]
    resources =  [ format("%s/*", module.terraform_state_backend.s3_bucket_arn), module.terraform_state_backend.s3_bucket_arn]
    effect    = "Allow"
  }
  statement {
    actions   = ["s3:GetObject", "s3:ListBucket", "s3:GetBucketLocation"]
    resources =  [ format("%s/*", module.s3_bucket.bucket_arn), module.s3_bucket.bucket_arn]
    effect    = "Allow"
  }
   
  statement {
    actions   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem" ]
    resources =  [ module.terraform_state_backend.dynamodb_table_arn ]
  }    
}

resource "aws_iam_user_policy" "s3" {
  count  = module.this.enabled ? 1 : 0
  name   = module.aws_user.user_name
  user   = module.aws_user.user_name
  policy = join("", data.aws_iam_policy_document.bucket.*.json)
}



 #########################################################################
 # Deploy Ingress for BioAnalyze app.
 #########################################################################
module "bioanalyze_ingress" {
  count                   = local.ingress_enabled
  source                  = "dabble-of-devops-bioanalyze/eks-bitnami-nginx-ingress/aws"
  version                 = ">= 0.1.0"
  letsencrypt_email       = var.letsencrypt_email
  helm_release_values_dir = var.helm_release_values_dir
  helm_release_name       = var.helm_release_name_ingress
}

 #########################################################################
 # Get Ingress for BioAnalyze app.
 #########################################################################
data "kubernetes_service" "bioanalyze_ingress" {
  count = var.enable_ssl == true ? 1 : 0
  depends_on = [
    module.bioanalyze_ingress
  ]
  metadata {
    name = "${var.helm_release_name_ingress}-ingress-nginx-ingress-controller"
  }
}

data "aws_elb" "bioanalyze_ingress" {
  count = var.enable_ssl == true ? 1 : 0
  depends_on = [
    data.kubernetes_service.bioanalyze_ingress
  ]
  name = split("-", data.kubernetes_service.bioanalyze_ingress[0].status.0.load_balancer.0.ingress.0.hostname)[0]
}

 #########################################################################
 # Deploy BioAnalyze app. (current nginx)
 #########################################################################

resource "helm_release" "bioanalyze-app" {
  depends_on = [
    module.bioanalyze_ingress,
  ]
  name             = var.helm_release_name
  repository       = var.helm_release_repository
  chart            = var.helm_release_chart
  version          = var.helm_release_version
  namespace        = var.helm_release_namespace
  create_namespace = var.helm_release_create_namespace
  wait             = var.helm_release_wait
  values = local.helm_release_values
  set {
    name  = "fullnameOverride"
    value = var.helm_release_name
  }  
  set {
    name  = "service.port"
    value = var.helm_release_values_service_port
  }
  
  set {
    name  = "service.type"
    value = var.helm_release_values_service_type
  }
  set {
    name  =  "ingress.enabled"
    value = var.enable_ssl
  }
  set {
    // local 
    name = "ingress.hostname"
    value = regex("\\w+\\.\\w+\\.\\w+", format("%s.%s", var.aws_route53_record_name, var.aws_route53_zone_name)) 
  }  
  set {
    name = "ingress.annotations.kubernetes\\.io\\/ingress\\.class"
    value = var.ingress_class
  }
  set {
    name = "cert-manager.io\\/cluster-issuer"
    value = format("%s-letsencrypt", var.helm_release_name_ingress)
  }
}

resource "null_resource" "sleep_bioanalyze_app_update" {
  depends_on = [
    helm_release.bioanalyze-app
  ]
   triggers = {
    always_run = timestamp()
   }
   provisioner "local-exec" {
    command = <<EOT
      echo "Waiting for the bioanalyze-app service to come up"
      sleep 60
      EOT
    }
 }

 #########################################################################
 # BioanAlyze Service Type == LoadBalancer
 #########################################################################
data "kubernetes_service" "bioanalyze-app" {
  count = var.helm_release_values_service_type == "LoadBalancer" ? 1 : 0
  depends_on = [
    helm_release.bioanalyze-app,
    null_resource.sleep_bioanalyze_app_update
  ]
  metadata {
    name      = var.helm_release_name
    namespace = var.helm_release_namespace
  }
}

data "aws_elb" "bioanalyze-app" {
  count = var.helm_release_values_service_type == "LoadBalancer" ? 1 : 0
  depends_on = [
    helm_release.bioanalyze-app,
    data.kubernetes_service.bioanalyze-app,
  ]
  name = split("-", data.kubernetes_service.bioanalyze-app[0].status.0.load_balancer.0.ingress.0.hostname)[0]
}

output "aws_elb_bioanalyze_app" {
   value = data.aws_elb.bioanalyze-app
}

#########################################################################
# helm_release_values_service_type == ClusterIP and var.enable_ssl = true
#########################################################################


data "aws_route53_zone" "bioanalyze-app" {
  count = var.create_route53_record && var.enable_ssl  == true ? 1 : 0
  name  = var.aws_route53_zone_name
}

resource "aws_route53_record" "bioanalyze-app" {
  count = var.create_route53_record && var.enable_ssl  == true ? 1 : 0
  depends_on = [
    module.bioanalyze_ingress,
    helm_release.bioanalyze-app,
  ]
  zone_id = data.aws_route53_zone.bioanalyze-app[0].zone_id
  name    = var.aws_route53_record_name
  type    = "A"
  alias {
    name                   = data.aws_elb.bioanalyze-app[0].dns_name
    zone_id                = data.aws_elb.bioanalyze-app[0].zone_id
    evaluate_target_health = true
  }
}
#########################################################################
# Deploy airflow helm release to EKS
#########################################################################

resource "null_resource" "create_merged_file" {
  count    = module.this.enabled ? 1 : 0
  triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    command = <<EOT
    mkdir -p helm_charts
    touch ${local.helm_release_merged_values_file}
    EOT
  }
}


 module "helm_release_airflow" {
  count    = module.this.enabled && var.install_airflow ? 1 : 0 
  depends_on = [
    null_resource.create_merged_file,
  ]
  source                          = "dabble-of-devops-bioanalyze/eks-bitnami-apache-airflow/aws"
  helm_release_name               = "airflow"
  helm_release_version            = var.airflow_helm_release_version
  helm_release_values_dir         = abspath(var.airflow_helm_values_dir)
  use_external_db                 = var.airflow_use_external_db
  external_db_secret              = try(aws_secretsmanager_secret_version.db-pass-val["airflow"].secret_string, "") 
  external_db_host                = try(compact([for item in module.rds_cluster_aurora: try(regexall(".*airflow.*", item.endpoint)[0], "")])[0], "")
  external_db_user                = try(compact([for item in module.rds_cluster_aurora: length(regexall(".*airflow.*", item.endpoint)) > 0 ? item.master_username : ""])[0], "")
  helm_release_merged_values_file = local.helm_release_merged_values_file
  letsencrypt_email               = var.letsencrypt_email
  aws_route53_zone_name           = var.airflow_aws_route53_zone_name
  aws_route53_record_name         = var.airflow_aws_route53_record_name
  enable_ssl                      = var.airflow_enable_ssl
  context                         = module.this.context
  helm_release_values_files       = ["helm_charts/airflow_values.yaml"]
  airflow_password                = var.airflow_password
  helm_release_values_service_type = var.airflow_helm_service_type
}

output "helm_release_airflow" {
  value = module.helm_release_airflow
}
