variable "subscription_id" {
  type        = string
  description = "Azure subscription ID hosting the target cluster."
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group holding the AKS cluster + Key Vault."
}

variable "aks_name" {
  type        = string
  description = "Existing AKS cluster to deploy onto (see README for the platform prerequisites it must satisfy)."
}

variable "key_vault_name" {
  type        = string
  description = "Existing Key Vault that the cluster's External Secrets Operator ClusterSecretStore reads from."
}

variable "gitops_repo_url" {
  type        = string
  description = "GitOps repo the pantry root Application watches."
  default     = "https://github.com/pjvjay/pantry-gitops.git"
}

variable "gitops_target_revision" {
  type        = string
  description = "Branch or tag ArgoCD tracks."
  default     = "main"
}
