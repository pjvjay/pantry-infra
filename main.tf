# ============================================================
# pantry-infra — Terraform bootstrap for the pantry-platform demo
#
# Division of labor (GitOps best practice):
#
#   Terraform (this repo)      owns cloud-side + the GitOps SEED:
#     - the pantry-db-password Key Vault entry
#     - the ArgoCD root Application (one manifest)
#
#   pantry-gitops (ArgoCD)     owns everything in-cluster:
#     - namespaces, ExternalSecrets, CNPG Cluster,
#       Deployments, Services, Ingress, migration Job
#
# The target cluster is a PREREQUISITE, referenced via data sources
# only — this stack never creates or mutates it. It must already run
# the platform layer listed in the README (ArgoCD, ingress-nginx,
# cert-manager, CloudNativePG operator, External Secrets Operator
# with a ClusterSecretStore named "azure-key-vault").
# ============================================================

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_name
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_key_vault" "kv" {
  name                = var.key_vault_name
  resource_group_name = data.azurerm_resource_group.rg.name
}
