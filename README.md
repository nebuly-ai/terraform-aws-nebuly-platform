# Nebuly Platform (AWS)

Terraform module for provisioning Nebuly Platform resources on AWS.





## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.45.0 |


## Outputs

| Name | Description |
|------|-------------|
| <a name="output_eks_cluster_endpoint"></a> [eks\_cluster\_endpoint](#output\_eks\_cluster\_endpoint) | Endpoint for EKS control plane. |
| <a name="output_eks_cluster_get_credentials"></a> [eks\_cluster\_get\_credentials](#output\_eks\_cluster\_get\_credentials) | Command for getting the credentials for accessing the Kubernetes Cluster. |
| <a name="output_eks_cluster_name"></a> [eks\_cluster\_name](#output\_eks\_cluster\_name) | Kubernetes Cluster Name. |
| <a name="output_eks_cluster_security_group_id"></a> [eks\_cluster\_security\_group\_id](#output\_eks\_cluster\_security\_group\_id) | Security group ids attached to the cluster control plane. |
| <a name="output_eks_iam_role_arn"></a> [eks\_iam\_role\_arn](#output\_eks\_iam\_role\_arn) | The ARN of the EKS IAM role. |
| <a name="output_eks_service_accounts"></a> [eks\_service\_accounts](#output\_eks\_service\_accounts) | The service accounts that will able to assume the EKS IAM Role. |


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_eks_cluster_endpoint_public_access"></a> [eks\_cluster\_endpoint\_public\_access](#input\_eks\_cluster\_endpoint\_public\_access) | Indicates whether or not the Amazon EKS public API server endpoint is enabled. | `bool` | n/a | yes |
| <a name="input_eks_enable_cluster_creator_admin_permissions"></a> [eks\_enable\_cluster\_creator\_admin\_permissions](#input\_eks\_enable\_cluster\_creator\_admin\_permissions) | Indicates whether or not to add the cluster creator (the identity used by Terraform) as an administrator via access entry. | `bool` | `true` | no |
| <a name="input_eks_kubernetes_version"></a> [eks\_kubernetes\_version](#input\_eks\_kubernetes\_version) | Specify which Kubernetes release to use. | `string` | n/a | yes |
| <a name="input_eks_managed_node_group_defaults"></a> [eks\_managed\_node\_group\_defaults](#input\_eks\_managed\_node\_group\_defaults) | The default settings of the EKS managed node groups. | <pre>object({<br>    ami_type = string<br>  })</pre> | <pre>{<br>  "ami_type": "AL2_x86_64"<br>}</pre> | no |
| <a name="input_eks_managed_node_groups"></a> [eks\_managed\_node\_groups](#input\_eks\_managed\_node\_groups) | The managed node groups of the EKS cluster. | <pre>map(object({<br>    instance_types = set(string)<br>    min_size       = number<br>    max_size       = number<br>    desired_size   = optional(number)<br>  }))</pre> | <pre>{<br>  "gpu-a100": {<br>    "desired_size": 0,<br>    "instance_types": [<br>      "p4d.24xlarge"<br>    ],<br>    "max_size": 1,<br>    "min_size": 0<br>  },<br>  "workers": {<br>    "desired_size": 3,<br>    "instance_types": [<br>      "r5.xlarge"<br>    ],<br>    "max_size": 3,<br>    "min_size": 3<br>  }<br>}</pre> | no |
| <a name="input_eks_service_accounts"></a> [eks\_service\_accounts](#input\_eks\_service\_accounts) | The service accounts that will able to assume the EKS IAM Role. | <pre>list(object({<br>    name : string<br>    namespace : string<br>  }))</pre> | <pre>[<br>  {<br>    "name": "nebuly",<br>    "namespace": "nebuly"<br>  },<br>  {<br>    "name": "nebuly",<br>    "namespace": "default"<br>  }<br>]</pre> | no |
| <a name="input_region"></a> [region](#input\_region) | The region where to provision the resources. | `string` | n/a | yes |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | The prefix that will be used for generating resource names. | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | The IDs of the subnets to attach to the Platform resources. | `set(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Common tags that will be applied to all resources. | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID of the VPC to use. | `string` | n/a | yes |

## Resources


- data source.aws_caller_identity.current (/terraform-docs/data.tf#2)
- data source.aws_region.current (/terraform-docs/data.tf#3)
- data source.aws_security_group.default (/terraform-docs/data.tf#15)
- data source.aws_subnets.default (/terraform-docs/data.tf#9)
- data source.aws_vpc.default (/terraform-docs/data.tf#6)
