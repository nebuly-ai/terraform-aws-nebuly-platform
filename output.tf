### ----------- EKS ----------- ###
output "eks_service_accounts" {
  description = "The service accounts that will able to assume the EKS IAM Role."
  value       = var.eks_service_accounts
}
output "eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane."
  value       = module.eks.cluster_endpoint
}
output "eks_cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane."
  value       = module.eks.cluster_security_group_id
}
output "eks_cluster_name" {
  description = "Kubernetes Cluster Name."
  value       = module.eks.cluster_name
}
output "eks_cluster_get_credentials" {
  description = "Command for getting the credentials for accessing the Kubernetes Cluster."
  value       = "aws eks --region ${var.region} update-kubeconfig --name ${module.eks.cluster_name}"
}
output "eks_iam_role_arn" {
  description = "The ARN of the EKS IAM role."
  value       = module.eks_iam_role.iam_role_arn
}




### ----------- Postgres (RDS) ----------- ###
output "analytics_db" {
  description = "Details of the analytics DB hosted on an RDS instance."
  value = {
    arn                  = module.rds_postgres_analytics.db_instance_arn
    instance_address     = module.rds_postgres_analytics.db_instance_address
    instance_endpoint    = module.rds_postgres_analytics.db_instance_endpoint
    username             = module.rds_postgres_analytics.db_instance_username
    password_secret_name = aws_secretsmanager_secret.rds_analytics_credentials.name
  }
}
output "analytics_db_credentials" {
  description = "Credentials for connecting with the analytics DB."
  value = {
    username = module.rds_postgres_analytics.db_instance_username
    password = random_password.rds_analytics.result
  }
  sensitive = true
}
output "auth_db" {
  description = "Details of the auth DB hosted on an RDS instance."
  value = {
    arn                  = module.rds_postgres_auth.db_instance_arn
    instance_address     = module.rds_postgres_auth.db_instance_address
    instance_endpoint    = module.rds_postgres_auth.db_instance_endpoint
    username             = module.rds_postgres_auth.db_instance_username
    password_secret_name = aws_secretsmanager_secret.rds_auth_credentials.name
  }
}
output "auth_db_credentials" {
  description = "Credentials for connecting with the auth DB."
  value = {
    username = module.rds_postgres_auth.db_instance_username
    password = random_password.rds_auth.result
  }
  sensitive = true
}


### ----------- External Secrets ----------- ###
output "openai_api_key_secret_name" {
  description = "The name of the secret storing the OpenAI API Key."
  value       = aws_secretsmanager_secret.openai_api_key.name
}


### ----------- S3 Storage ----------- ###
output "s3_bucket_ai_models" {
  description = "The details of the bucket used as model registry for storing the AI Models"
  value = {
    name : aws_s3_bucket.ai_models.id
    domain_name : aws_s3_bucket.ai_models.bucket_domain_name
    arn : aws_s3_bucket.ai_models.arn
  }
}


### ----------- Networking ----------- ###
output "eks_load_balancer_security_group" {
  description = "The security group linked with the EKS load balancer."
  value       = aws_security_group.eks_load_balancer
}


### ----------- Auth ----------- ###
output "admin_user_password" {
  description = "The password of the initial admin user of the platform."
  value       = random_password.admin_user_password.result
  sensitive   = true
}
output "admin_user_password_secret_name" {
  description = "The name of the secret containing the password of the initial admin user of the platform."
  value       = aws_secretsmanager_secret.admin_user_password.name
}
output "auth_jwt_key_secret_name" {
  description = "The name of the secret containing the SSL Key used for generating JWTs."
  value       = aws_secretsmanager_secret.auth_jwt_key.name
}




# ------ Deploy ------ #
#output "helm_values" {
#  value       = local.helm_values
#  sensitive   = true
#  description = <<EOT
#  The `values.yaml` file for installing Nebuly with Helm.
#
#  The default standard configuration is used, which uses Nginx as ingress controller and exposes the application to the Internet. This configuration can be customized according to specific needs.
#  EOT
#}
output "secret_provider_class" {
  value       = local.secret_provider_class
  sensitive   = true
  description = "The `secret-provider-class.yaml` file to make Kubernetes reference the secrets stored in the Key Vault."
}

