# Nebuly Platform on AWS

Terraform module for provisioning Nebuly Platform resources on AWS.





## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.45.0 |


## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | Endpoint for EKS control plane |
| <a name="output_cluster_get_credentials"></a> [cluster\_get\_credentials](#output\_cluster\_get\_credentials) | Command for getting the credentials for accessing the Kubernetes Cluster |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Kubernetes Cluster Name |
| <a name="output_cluster_role_arn"></a> [cluster\_role\_arn](#output\_cluster\_role\_arn) | n/a |
| <a name="output_cluster_security_group_id"></a> [cluster\_security\_group\_id](#output\_cluster\_security\_group\_id) | Security group ids attached to the cluster control plane |


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_access_key"></a> [aws\_access\_key](#input\_aws\_access\_key) | ## AWS Auth ### | `string` | n/a | yes |
| <a name="input_aws_secret_key"></a> [aws\_secret\_key](#input\_aws\_secret\_key) | n/a | `string` | n/a | yes |
| <a name="input_budget_monthly_usd"></a> [budget\_monthly\_usd](#input\_budget\_monthly\_usd) | Monthly budget, in Euro. | `string` | n/a | yes |
| <a name="input_budget_notification_receivers"></a> [budget\_notification\_receivers](#input\_budget\_notification\_receivers) | List of emails of the users that will receive budget notifications. | `set(string)` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | n/a | yes |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | ## General ### | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(string)` | `{}` | no |

## Resources


- data source.aws_caller_identity.current (/terraform-docs/data.tf#2)
- data source.aws_region.current (/terraform-docs/data.tf#3)
- data source.aws_security_group.default (/terraform-docs/data.tf#15)
- data source.aws_subnets.default (/terraform-docs/data.tf#9)
- data source.aws_vpc.default (/terraform-docs/data.tf#6)
