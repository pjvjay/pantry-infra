variable "subscription_id" {
  type        = string
  description = "Azure subscription ID."
  default     = "67c717e5-eaca-4f7d-9495-8b65ff376823"
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group holding the shared AKS + Key Vault."
  default     = "rg-therealpj92-0374"
}

variable "aks_name" {
  type        = string
  description = "Existing AKS cluster (provisioned by lifeguide-infra)."
  default     = "lifeguide-dev-aks"
}

variable "key_vault_name" {
  type        = string
  description = "Existing Key Vault the cluster's ESO ClusterSecretStore reads from."
  default     = "lifeguide-dev-kv-67c717e5"
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
