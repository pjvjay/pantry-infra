variable "subscription_id" {
  type        = string
  description = "Azure subscription ID."
  default     = "00000000-0000-0000-0000-000000000000"
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group holding the shared AKS + Key Vault."
  default     = "my-resource-group"
}

variable "aks_name" {
  type        = string
  description = "Existing AKS cluster (provisioned by the-platform-layer)."
  default     = "my-aks-cluster"
}

variable "key_vault_name" {
  type        = string
  description = "Existing Key Vault the cluster's ESO ClusterSecretStore reads from."
  default     = "my-key-vault"
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
