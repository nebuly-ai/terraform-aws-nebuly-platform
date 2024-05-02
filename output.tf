### ----------- EKS ----------- ###
output "eks_service_accounts" {
  description = "The service accounts that will able to assume the EKS IAM Role."
  value       = var.eks_service_accounts
}
output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}
output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane"
  value       = module.eks.cluster_security_group_id
}
output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}
output "cluster_get_credentials" {
  description = "Command for getting the credentials for accessing the Kubernetes Cluster"
  value       = "aws eks --region ${var.region} update-kubeconfig --name ${module.eks.cluster_name}"
}
output "cluster_role_arn" {
  value = module.iam_eks_role.iam_role_arn
}
