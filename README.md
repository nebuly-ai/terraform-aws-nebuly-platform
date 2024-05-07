# Nebuly Platform (AWS)

Terraform module for provisioning Nebuly Platform resources on AWS.





## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~>5.45 |
| <a name="provider_random"></a> [random](#provider\_random) | ~>3.6 |


## Outputs

| Name | Description |
|------|-------------|
| <a name="output_analytics_db"></a> [analytics\_db](#output\_analytics\_db) | Details of the analytics DB hosted on an RDS instance. |
| <a name="output_analytics_db_credentials"></a> [analytics\_db\_credentials](#output\_analytics\_db\_credentials) | Credentials for connecting with the analytics DB. |
| <a name="output_auth_db"></a> [auth\_db](#output\_auth\_db) | Details of the auth DB hosted on an RDS instance. |
| <a name="output_auth_db_credentials"></a> [auth\_db\_credentials](#output\_auth\_db\_credentials) | Credentials for connecting with the auth DB. |
| <a name="output_eks_cluster_endpoint"></a> [eks\_cluster\_endpoint](#output\_eks\_cluster\_endpoint) | Endpoint for EKS control plane. |
| <a name="output_eks_cluster_get_credentials"></a> [eks\_cluster\_get\_credentials](#output\_eks\_cluster\_get\_credentials) | Command for getting the credentials for accessing the Kubernetes Cluster. |
| <a name="output_eks_cluster_name"></a> [eks\_cluster\_name](#output\_eks\_cluster\_name) | Kubernetes Cluster Name. |
| <a name="output_eks_cluster_security_group_id"></a> [eks\_cluster\_security\_group\_id](#output\_eks\_cluster\_security\_group\_id) | Security group ids attached to the cluster control plane. |
| <a name="output_eks_iam_role_arn"></a> [eks\_iam\_role\_arn](#output\_eks\_iam\_role\_arn) | The ARN of the EKS IAM role. |
| <a name="output_eks_service_accounts"></a> [eks\_service\_accounts](#output\_eks\_service\_accounts) | The service accounts that will able to assume the EKS IAM Role. |
| <a name="output_openai_api_key_secret_name"></a> [openai\_api\_key\_secret\_name](#output\_openai\_api\_key\_secret\_name) | The name of the secret storing the OpenAI API Key. |
| <a name="output_s3_bucket_ai_models"></a> [s3\_bucket\_ai\_models](#output\_s3\_bucket\_ai\_models) | The details of the bucket used as model registry for storing the AI Models |


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_eks_cluster_endpoint_public_access"></a> [eks\_cluster\_endpoint\_public\_access](#input\_eks\_cluster\_endpoint\_public\_access) | Indicates whether or not the Amazon EKS public API server endpoint is enabled. | `bool` | n/a | yes |
| <a name="input_eks_enable_cluster_creator_admin_permissions"></a> [eks\_enable\_cluster\_creator\_admin\_permissions](#input\_eks\_enable\_cluster\_creator\_admin\_permissions) | Indicates whether or not to add the cluster creator (the identity used by Terraform) as an administrator via access entry. | `bool` | `true` | no |
| <a name="input_eks_kubernetes_version"></a> [eks\_kubernetes\_version](#input\_eks\_kubernetes\_version) | Specify which Kubernetes release to use. | `string` | n/a | yes |
| <a name="input_eks_managed_node_group_defaults"></a> [eks\_managed\_node\_group\_defaults](#input\_eks\_managed\_node\_group\_defaults) | The default settings of the EKS managed node groups. | <pre>object({<br>    ami_type = string<br>  })</pre> | <pre>{<br>  "ami_type": "AL2_x86_64"<br>}</pre> | no |
| <a name="input_eks_managed_node_groups"></a> [eks\_managed\_node\_groups](#input\_eks\_managed\_node\_groups) | The managed node groups of the EKS cluster. | <pre>map(object({<br>    instance_types = set(string)<br>    min_size       = number<br>    max_size       = number<br>    desired_size   = optional(number)<br>  }))</pre> | <pre>{<br>  "gpu-a100": {<br>    "desired_size": 0,<br>    "instance_types": [<br>      "p4d.24xlarge"<br>    ],<br>    "max_size": 1,<br>    "min_size": 0<br>  },<br>  "workers": {<br>    "desired_size": 3,<br>    "instance_types": [<br>      "r5.xlarge"<br>    ],<br>    "max_size": 3,<br>    "min_size": 3<br>  }<br>}</pre> | no |
| <a name="input_eks_service_accounts"></a> [eks\_service\_accounts](#input\_eks\_service\_accounts) | The service accounts that will able to assume the EKS IAM Role. | <pre>list(object({<br>    name : string<br>    namespace : string<br>  }))</pre> | <pre>[<br>  {<br>    "name": "nebuly",<br>    "namespace": "nebuly"<br>  },<br>  {<br>    "name": "nebuly",<br>    "namespace": "default"<br>  }<br>]</pre> | no |
| <a name="input_openai_api_key"></a> [openai\_api\_key](#input\_openai\_api\_key) | The API Key used for authenticating with OpenAI. | `string` | n/a | yes |
| <a name="input_rds_analytics_instance_type"></a> [rds\_analytics\_instance\_type](#input\_rds\_analytics\_instance\_type) | The instance type of the RDS instance hosting the analytics DB. | `string` | `"db.m7g.xlarge"` | no |
| <a name="input_rds_analytics_storage"></a> [rds\_analytics\_storage](#input\_rds\_analytics\_storage) | Storage settings of the analytics DB. | <pre>object({<br>    allocated_gb : number<br>    max_allocated_gb : number<br>    type : string<br>    iops : optional(number, null)<br>  })</pre> | <pre>{<br>  "allocated_gb": 32,<br>  "max_allocated_gb": 128,<br>  "type": "gp2"<br>}</pre> | no |
| <a name="input_rds_auth_instance_type"></a> [rds\_auth\_instance\_type](#input\_rds\_auth\_instance\_type) | The instance type of the RDS instance hosting the auth DB. | `string` | `"t4g.small"` | no |
| <a name="input_rds_auth_storage"></a> [rds\_auth\_storage](#input\_rds\_auth\_storage) | Storage settings of the auth DB. | <pre>object({<br>    allocated_gb : number<br>    max_allocated_gb : number<br>    type : string<br>    iops : optional(number, null)<br>  })</pre> | <pre>{<br>  "allocated_gb": 20,<br>  "max_allocated_gb": 32,<br>  "type": "gp2"<br>}</pre> | no |
| <a name="input_rds_availability_zone"></a> [rds\_availability\_zone](#input\_rds\_availability\_zone) | The availabilty zone of the RDS instances. | `string` | `null` | no |
| <a name="input_rds_backup_retention_period"></a> [rds\_backup\_retention\_period](#input\_rds\_backup\_retention\_period) | The retention period, in days, of the daily backups. | `number` | `14` | no |
| <a name="input_rds_backup_window"></a> [rds\_backup\_window](#input\_rds\_backup\_window) | Description: The daily time range (in UTC) during which automated backups are created if they are enabled. Example: '09:46-10:16'. Must not overlap with maintenance\_window. | `string` | `"03:00-06:00"` | no |
| <a name="input_rds_db_username"></a> [rds\_db\_username](#input\_rds\_db\_username) | The username to connect with the Postgres RDS databases. | `string` | `"nebulyadmin"` | no |
| <a name="input_rds_maintenance_window"></a> [rds\_maintenance\_window](#input\_rds\_maintenance\_window) | The window to perform maintenance in. Syntax: 'ddd:hh24:mi-ddd:hh24:mi'. Eg: 'Mon:00:00-Mon:03:00'. | `string` | `"Mon:00:00-Mon:03:00"` | no |
| <a name="input_rds_multi_availability_zone_enabled"></a> [rds\_multi\_availability\_zone\_enabled](#input\_rds\_multi\_availability\_zone\_enabled) | If True, provision the RDS instances on multiple availability zones. | `bool` | `true` | no |
| <a name="input_rds_postgres_family"></a> [rds\_postgres\_family](#input\_rds\_postgres\_family) | The PostgreSQL family to use for the RDS instances. | `string` | `"postgres16"` | no |
| <a name="input_rds_postgres_version"></a> [rds\_postgres\_version](#input\_rds\_postgres\_version) | The PostgreSQL version to use for the RDS instances. | `string` | `"16"` | no |
| <a name="input_region"></a> [region](#input\_region) | The region where to provision the resources. | `string` | n/a | yes |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | The prefix that will be used for generating resource names. | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | The IDs of the subnets to attach to the Platform resources. | `set(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Common tags that will be applied to all resources. | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID of the VPC to use. | `string` | n/a | yes |

## Resources


- resource.aws_iam_role_policy_attachment.ai_models__eks_reader (/terraform-docs/main.tf#288)
- resource.aws_s3_bucket.ai_models (/terraform-docs/main.tf#284)
- resource.aws_secretsmanager_secret.openai_api_key (/terraform-docs/main.tf#273)
- resource.aws_secretsmanager_secret.rds_analytics_credentials (/terraform-docs/main.tf#101)
- resource.aws_secretsmanager_secret.rds_auth_credentials (/terraform-docs/main.tf#180)
- resource.aws_secretsmanager_secret_version.openai_api_key (/terraform-docs/main.tf#276)
- resource.aws_secretsmanager_secret_version.rds_analytics_password (/terraform-docs/main.tf#104)
- resource.aws_secretsmanager_secret_version.rds_auth_password (/terraform-docs/main.tf#183)
- resource.random_password.rds_analytics (/terraform-docs/main.tf#96)
- resource.random_password.rds_auth (/terraform-docs/main.tf#175)
- resource.random_string.secrets_suffix (/terraform-docs/main.tf#26)
- data source.aws_caller_identity.current (/terraform-docs/data.tf#2)
- data source.aws_region.current (/terraform-docs/data.tf#3)
- data source.aws_security_group.default (/terraform-docs/data.tf#15)
- data source.aws_subnets.default (/terraform-docs/data.tf#9)
- data source.aws_vpc.default (/terraform-docs/data.tf#6)
