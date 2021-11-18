<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 1.2 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 2.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_helm"></a> [helm](#provider\_helm) | n/a |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | n/a |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | >= 2.2 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_aws_user"></a> [aws\_user](#module\_aws\_user) | cloudposse/iam-system-user/aws | 0.22.5 |
| <a name="module_bioanalyze_ingress"></a> [bioanalyze\_ingress](#module\_bioanalyze\_ingress) | dabble-of-devops-bioanalyze/eks-bitnami-nginx-ingress/aws | >= 0.1.0 |
| <a name="module_helm_release_airflow"></a> [helm\_release\_airflow](#module\_helm\_release\_airflow) | dabble-of-devops-bioanalyze/eks-bitnami-apache-airflow/aws | n/a |
| <a name="module_rds_cluster_aurora"></a> [rds\_cluster\_aurora](#module\_rds\_cluster\_aurora) | cloudposse/rds-cluster/aws | n/a |
| <a name="module_s3_bucket"></a> [s3\_bucket](#module\_s3\_bucket) | cloudposse/s3-bucket/aws | n/a |
| <a name="module_terraform_state_backend"></a> [terraform\_state\_backend](#module\_terraform\_state\_backend) | cloudposse/tfstate-backend/aws | n/a |
| <a name="module_this"></a> [this](#module\_this) | cloudposse/label/null | 0.25.0 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_user_policy.s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user_policy) | resource |
| [aws_iam_user_policy.secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user_policy) | resource |
| [aws_route53_record.bioanalyze-app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_secretsmanager_secret.db_secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.db-pass-val](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [helm_release.bioanalyze-app](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [null_resource.create_merged_file](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.sleep_bioanalyze_app_update](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_password.password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_string.computed_values](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [aws_elb.bioanalyze-app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/elb) | data source |
| [aws_elb.bioanalyze_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/elb) | data source |
| [aws_iam_policy_document.bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_route53_zone.bioanalyze-app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [kubernetes_service.bioanalyze-app](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/service) | data source |
| [kubernetes_service.bioanalyze_ingress](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/service) | data source |


## Usage

For a complete example, see [examples/complete](examples/complete).

For automated tests of the complete example using [bats](https://github.com/bats-core/bats-core) and [Terratest](https://github.com/gruntwork-io/terratest) (which tests and deploys the example on AWS), see [test](test).

This example creates: terraform state backend, S3 bucket for user resources, two AWS RDS Aurora Postgresql databases, AWS Secrets manager to store 
databese secters, iam user to wit access to created resources.  

```hcl
      module "registration" {
          source = "./registration"
          enabled = true
          name    = "clienta-org"
          namespace = ""
          subnets = ["subnet-*", "subnet-*"]
          vpc_id = "vpc-*"
          databases = {
              "airflow" = {
                  name    = "clienta-org-airflow"
                  cluster_size              = 2,
                  create_random_db_password = true,
                  instance_type             = "db.t3.medium",
                  security_groups           = [],
                  retention_period          = 5,
                  backup_window             = "07:00-09:00",
                  admin_user                = "admin"
              },
              "bioanalyze" = {
                  name    = "clienta-org-bioanalyze"
                  cluster_size              = 2,
                  create_random_db_password = true,
                  instance_type             = "db.t3.medium",
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

```


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_tag_map"></a> [additional\_tag\_map](#input\_additional\_tag\_map) | Additional key-value pairs to add to each map in `tags_as_list_of_maps`. Not added to `tags` or `id`.<br>This is for some rare cases where resources want additional configuration of tags<br>and therefore take a list of maps with tag key, value, and additional configuration. | `map(string)` | `{}` | no |
| <a name="input_airflow_aws_route53_record_name"></a> [airflow\_aws\_route53\_record\_name](#input\_airflow\_aws\_route53\_record\_name) | n/a | `string` | `""` | no |
| <a name="input_airflow_aws_route53_zone_name"></a> [airflow\_aws\_route53\_zone\_name](#input\_airflow\_aws\_route53\_zone\_name) | n/a | `string` | `""` | no |
| <a name="input_airflow_enable_ssl"></a> [airflow\_enable\_ssl](#input\_airflow\_enable\_ssl) | n/a | `bool` | `false` | no |
| <a name="input_airflow_helm_release_version"></a> [airflow\_helm\_release\_version](#input\_airflow\_helm\_release\_version) | n/a | `string` | `"11.0.8"` | no |
| <a name="input_airflow_helm_service_type"></a> [airflow\_helm\_service\_type](#input\_airflow\_helm\_service\_type) | n/a | `string` | `"ClusterIP"` | no |
| <a name="input_airflow_helm_values_dir"></a> [airflow\_helm\_values\_dir](#input\_airflow\_helm\_values\_dir) | n/a | `any` | n/a | yes |
| <a name="input_airflow_password"></a> [airflow\_password](#input\_airflow\_password) | n/a | `string` | `"PASSWORD"` | no |
| <a name="input_airflow_release_name"></a> [airflow\_release\_name](#input\_airflow\_release\_name) | n/a | `any` | n/a | yes |
| <a name="input_airflow_use_external_db"></a> [airflow\_use\_external\_db](#input\_airflow\_use\_external\_db) | n/a | `bool` | `true` | no |
| <a name="input_attributes"></a> [attributes](#input\_attributes) | ID element. Additional attributes (e.g. `workers` or `cluster`) to add to `id`,<br>in the order they appear in the list. New attributes are appended to the<br>end of the list. The elements of the list are joined by the `delimiter`<br>and treated as a single ID element. | `list(string)` | `[]` | no |
| <a name="input_aws_route53_record_name"></a> [aws\_route53\_record\_name](#input\_aws\_route53\_record\_name) | Record name to add to aws\_route\_53. Must be a valid subdomain - www,app,etc | `string` | `"nginx"` | no |
| <a name="input_aws_route53_zone_name"></a> [aws\_route53\_zone\_name](#input\_aws\_route53\_zone\_name) | Name of the zone to add records. Do not forget the trailing '.' - 'test.com.' | `string` | `"bioanalyzedev.com."` | no |
| <a name="input_context"></a> [context](#input\_context) | Single object for setting entire context at once.<br>See description of individual variables for details.<br>Leave string and numeric variables as `null` to use default value.<br>Individual variable settings (non-null) override settings in context object,<br>except for attributes, tags, and additional\_tag\_map, which are merged. | `any` | <pre>{<br>  "additional_tag_map": {},<br>  "attributes": [],<br>  "delimiter": null,<br>  "descriptor_formats": {},<br>  "enabled": true,<br>  "environment": null,<br>  "id_length_limit": null,<br>  "label_key_case": null,<br>  "label_order": [],<br>  "label_value_case": null,<br>  "labels_as_tags": [<br>    "unset"<br>  ],<br>  "name": null,<br>  "namespace": null,<br>  "regex_replace_chars": null,<br>  "stage": null,<br>  "tags": {},<br>  "tenant": null<br>}</pre> | no |
| <a name="input_create_route53_record"></a> [create\_route53\_record](#input\_create\_route53\_record) | n/a | `bool` | `false` | no |
| <a name="input_databases"></a> [databases](#input\_databases) | n/a | `map(any)` | n/a | yes |
| <a name="input_delimiter"></a> [delimiter](#input\_delimiter) | Delimiter to be used between ID elements.<br>Defaults to `-` (hyphen). Set to `""` to use no delimiter at all. | `string` | `null` | no |
| <a name="input_descriptor_formats"></a> [descriptor\_formats](#input\_descriptor\_formats) | Describe additional descriptors to be output in the `descriptors` output map.<br>Map of maps. Keys are names of descriptors. Values are maps of the form<br>`{<br>   format = string<br>   labels = list(string)<br>}`<br>(Type is `any` so the map values can later be enhanced to provide additional options.)<br>`format` is a Terraform format string to be passed to the `format()` function.<br>`labels` is a list of labels, in order, to pass to `format()` function.<br>Label values will be normalized before being passed to `format()` so they will be<br>identical to how they appear in `id`.<br>Default is `{}` (`descriptors` output will be empty). | `any` | `{}` | no |
| <a name="input_enable_ssl"></a> [enable\_ssl](#input\_enable\_ssl) | Enable SSL Support? | `bool` | `true` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources | `bool` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | ID element. Usually used for region e.g. 'uw2', 'us-west-2', OR role 'prod', 'staging', 'dev', 'UAT' | `string` | `null` | no |
| <a name="input_helm_release_chart"></a> [helm\_release\_chart](#input\_helm\_release\_chart) | helm release chart for BioAnalyze deployment | `string` | `"nginx"` | no |
| <a name="input_helm_release_create_namespace"></a> [helm\_release\_create\_namespace](#input\_helm\_release\_create\_namespace) | n/a | `bool` | `true` | no |
| <a name="input_helm_release_name"></a> [helm\_release\_name](#input\_helm\_release\_name) | helm release name | `string` | `"bioanalyze-app"` | no |
| <a name="input_helm_release_name_ingress"></a> [helm\_release\_name\_ingress](#input\_helm\_release\_name\_ingress) | n/a | `string` | `"nginx"` | no |
| <a name="input_helm_release_namespace"></a> [helm\_release\_namespace](#input\_helm\_release\_namespace) | helm release namespace for BioAnalyze deployment | `string` | `"default"` | no |
| <a name="input_helm_release_repository"></a> [helm\_release\_repository](#input\_helm\_release\_repository) | helm release chart repository for BioAnalyze deployment | `string` | `"https://charts.bitnami.com/bitnami"` | no |
| <a name="input_helm_release_values_dir"></a> [helm\_release\_values\_dir](#input\_helm\_release\_values\_dir) | Directory to put rendered values template files or additional keys. Should be helm\_charts/{helm\_release\_name} | `string` | `"helm_charts"` | no |
| <a name="input_helm_release_values_file"></a> [helm\_release\_values\_file](#input\_helm\_release\_values\_file) | File to put additional values for helm release | `string` | `""` | no |
| <a name="input_helm_release_values_service_port"></a> [helm\_release\_values\_service\_port](#input\_helm\_release\_values\_service\_port) | Service port to set for exposing the nginx service | `string` | `"80"` | no |
| <a name="input_helm_release_values_service_type"></a> [helm\_release\_values\_service\_type](#input\_helm\_release\_values\_service\_type) | Service type to set for exposing the airflow service. The default is to use the ClusterIP and an ingress. Alternative is to use a LoadBalancer, but this only recommended for testing. | `string` | `"ClusterIP"` | no |
| <a name="input_helm_release_version"></a> [helm\_release\_version](#input\_helm\_release\_version) | helm release version for BioAnalyze deployment | `string` | `"9.5.13"` | no |
| <a name="input_helm_release_wait"></a> [helm\_release\_wait](#input\_helm\_release\_wait) | n/a | `bool` | `true` | no |
| <a name="input_id_length_limit"></a> [id\_length\_limit](#input\_id\_length\_limit) | Limit `id` to this many characters (minimum 6).<br>Set to `0` for unlimited length.<br>Set to `null` for keep the existing setting, which defaults to `0`.<br>Does not affect `id_full`. | `number` | `null` | no |
| <a name="input_ingress_class"></a> [ingress\_class](#input\_ingress\_class) | n/a | `string` | `"nginx"` | no |
| <a name="input_install_airflow"></a> [install\_airflow](#input\_install\_airflow) | n/a | `bool` | `true` | no |
| <a name="input_install_ingress"></a> [install\_ingress](#input\_install\_ingress) | n/a | `bool` | n/a | yes |
| <a name="input_label_key_case"></a> [label\_key\_case](#input\_label\_key\_case) | Controls the letter case of the `tags` keys (label names) for tags generated by this module.<br>Does not affect keys of tags passed in via the `tags` input.<br>Possible values: `lower`, `title`, `upper`.<br>Default value: `title`. | `string` | `null` | no |
| <a name="input_label_order"></a> [label\_order](#input\_label\_order) | The order in which the labels (ID elements) appear in the `id`.<br>Defaults to ["namespace", "environment", "stage", "name", "attributes"].<br>You can omit any of the 6 labels ("tenant" is the 6th), but at least one must be present. | `list(string)` | `null` | no |
| <a name="input_label_value_case"></a> [label\_value\_case](#input\_label\_value\_case) | Controls the letter case of ID elements (labels) as included in `id`,<br>set as tag values, and output by this module individually.<br>Does not affect values of tags passed in via the `tags` input.<br>Possible values: `lower`, `title`, `upper` and `none` (no transformation).<br>Set this to `title` and set `delimiter` to `""` to yield Pascal Case IDs.<br>Default value: `lower`. | `string` | `null` | no |
| <a name="input_labels_as_tags"></a> [labels\_as\_tags](#input\_labels\_as\_tags) | Set of labels (ID elements) to include as tags in the `tags` output.<br>Default is to include all labels.<br>Tags with empty values will not be included in the `tags` output.<br>Set to `[]` to suppress all generated tags.<br>**Notes:**<br>  The value of the `name` tag, if included, will be the `id`, not the `name`.<br>  Unlike other `null-label` inputs, the initial setting of `labels_as_tags` cannot be<br>  changed in later chained modules. Attempts to change it will be silently ignored. | `set(string)` | <pre>[<br>  "default"<br>]</pre> | no |
| <a name="input_letsencrypt_email"></a> [letsencrypt\_email](#input\_letsencrypt\_email) | Email to use for https setup. Not needed unless enable\_ssl | `string` | `"hello@gmail.com"` | no |
| <a name="input_name"></a> [name](#input\_name) | ID element. Usually the component or solution name, e.g. 'app' or 'jenkins'.<br>This is the only ID element not also included as a `tag`.<br>The "name" tag is set to the full `id` string. There is no tag with the value of the `name` input. | `string` | `null` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | ID element. Usually an abbreviation of your organization name, e.g. 'eg' or 'cp', to help ensure generated IDs are globally unique | `string` | `null` | no |
| <a name="input_path"></a> [path](#input\_path) | Path in which to create the user | `string` | `"/"` | no |
| <a name="input_regex_replace_chars"></a> [regex\_replace\_chars](#input\_regex\_replace\_chars) | Terraform regular expression (regex) string.<br>Characters matching the regex will be removed from the ID elements.<br>If not set, `"/[^a-zA-Z0-9-]/"` is used to remove all characters other than hyphens, letters and digits. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS Region | `string` | `"us-east-1"` | no |
| <a name="input_s3_versioning"></a> [s3\_versioning](#input\_s3\_versioning) | Enable versioning for user resources S3 bucket | `bool` | `true` | no |
| <a name="input_stage"></a> [stage](#input\_stage) | ID element. Usually used to indicate role, e.g. 'prod', 'staging', 'source', 'build', 'test', 'deploy', 'release' | `string` | `null` | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | n/a | `list` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `{'BusinessUnit': 'XYZ'}`).<br>Neither the tag keys nor the tag values will be modified by this module. | `map(string)` | `{}` | no |
| <a name="input_tenant"></a> [tenant](#input\_tenant) | ID element \_(Rarely used, not included by default)\_. A customer identifier, indicating who this instance of a resource is for | `string` | `null` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | n/a | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aurora_endpoints"></a> [aurora\_endpoints](#output\_aurora\_endpoints) | n/a |
| <a name="output_aws_elb_bioanalyze_app"></a> [aws\_elb\_bioanalyze\_app](#output\_aws\_elb\_bioanalyze\_app) | n/a |
| <a name="output_bioanalyze_endpoint_lb"></a> [bioanalyze\_endpoint\_lb](#output\_bioanalyze\_endpoint\_lb) | n/a |
| <a name="output_db_secrets"></a> [db\_secrets](#output\_db\_secrets) | n/a |
| <a name="output_helm_release_airflow"></a> [helm\_release\_airflow](#output\_helm\_release\_airflow) | n/a |
| <a name="output_s3_bucket"></a> [s3\_bucket](#output\_s3\_bucket) | n/a |
| <a name="output_secret_access_key"></a> [secret\_access\_key](#output\_secret\_access\_key) | n/a |
| <a name="output_user"></a> [user](#output\_user) | n/a |
| <a name="output_user_access_key_id"></a> [user\_access\_key\_id](#output\_user\_access\_key\_id) | n/a |
<!-- END_TF_DOCS -->
