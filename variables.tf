##################################################
# AWS
##################################################

variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS Region"
}

variable "path" {
  type        = string
  description = "Path in which to create the user"
  default     = "/"
}

variable "vpc_id" {
  type        = string
  description = ""
  default     = ""
}

variable "subnets" {
  type        = list
  description = ""
  default     = []
}

variable "s3_versioning" {
  type = bool
  description = "Enable versioning for user resources S3 bucket"
  default = true
}

variable "databases" {
    type = map(any)
}

variable "helm_release_name" {
  type        = string
  description = "helm release name"
  default     = "bioanalyze-app"
}

variable "helm_release_repository" {
  type        = string
  description = "helm release chart repository for BioAnalyze deployment"
  default     = "https://charts.bitnami.com/bitnami"
}

variable "helm_release_chart" {
  type        = string
  description = "helm release chart for BioAnalyze deployment"
  default     = "nginx"
}

variable "helm_release_namespace" {
  type        = string
  description = "helm release namespace for BioAnalyze deployment"
  default     = "default"
}

variable "helm_release_version" {
  type        = string
  description = "helm release version for BioAnalyze deployment"
  default     = "9.5.13"
}

variable "helm_release_wait" {
  type    = bool
  default = true
}

variable "helm_release_create_namespace" {
  type    = bool
  default = true
}

variable "helm_release_values_dir" {
  type        = string
  description = "Directory to put rendered values template files or additional keys. Should be helm_charts/{helm_release_name}"
  default     = "helm_charts"
}

variable "helm_release_values_file" {
  type        = string
  description = "File to put additional values for helm release"
  default = ""
}


variable "helm_release_values_service_type" {
  type        = string
  description = "Service type to set for exposing the airflow service. The default is to use the ClusterIP and an ingress. Alternative is to use a LoadBalancer, but this only recommended for testing."
  default     = "ClusterIP"
}

variable "helm_release_values_service_port" {
  type        = string
  description = "Service port to set for exposing the nginx service"
  default     = "80"
}

##################################################
# Helm Release Variables - Enable SSL
# corresponds to input to resource "helm_release"
##################################################

variable "enable_ssl" {
  description = "Enable SSL Support?"
  type        = bool
  default     = true
}

# these variables are only needed if enable_ssl == true

variable "letsencrypt_email" {
  type        = string
  description = "Email to use for https setup. Not needed unless enable_ssl"
  default     = "hello@gmail.com"
}

variable "aws_route53_zone_name" {
  type        = string
  description = "Name of the zone to add records. Do not forget the trailing '.' - 'test.com.'"
  default     = "bioanalyzedev.com."
}

variable "aws_route53_record_name" {
  type        = string
  description = "Record name to add to aws_route_53. Must be a valid subdomain - www,app,etc"
  default     = "nginx"
}

variable "helm_release_name_ingress" {
  type = string
  default = "nginx"
}

variable "ingress_class" {
  type = string
  default = "nginx"
}

variable "install_ingress" {
  type = bool
}

variable "create_route53_record" {
  type = bool
  default = false
}

variable "airflow_helm_values_dir" {
  
}

variable "airflow_release_name" {
  
}
variable "install_airflow" {
  type = bool
  default = true
}

variable "airflow_enable_ssl" {
  type = bool
  default = false
}

variable "airflow_aws_route53_record_name" {
  type = string
  default = "" 
}

variable "airflow_aws_route53_zone_name" {
  type = string
  default = "" 
}

variable "airflow_use_external_db" {
  type = bool
  default = true
}

variable "airflow_helm_release_version" {
  type = string
  default = "11.0.8"
}

variable "airflow_password" {
  type = string
  default = "PASSWORD"
}

variable "airflow_helm_service_type" {
  type = string
  default = "ClusterIP"
}
