module "registration" {
    source = "../.."
    enabled = true
    name    = "clienta-org"
    namespace = ""
    subnets = ["subnet-*", "subnet-*"]
    vpc_id = "vpc-*"
    context = module.this.context
    databases = {
        "airflow" = {
            name    = "clienta-org-airflow"
            cluster_size              = 2,
            create_random_db_password = true,
            instance_type             = "db.t2.small",
            security_groups           = [],
            retention_period          = 5,
            backup_window             = "07:00-09:00",
            admin_user                = "admin"
        },
        "bioanalyze" = {
            name    = "clienta-org-bioanalyze"
            cluster_size              = 2,
            create_random_db_password = true,
            instance_type             = "db.t2.small",
            security_groups           = [],
            retention_period          = 5,
            backup_window             = "07:00-09:00",
            admin_user                = "admin"
        }
    } 
    enable_ssl = true
    install_ingress = true
    helm_release_values_service_type = "LoadBalancer"
    create_route53_record = true
}
