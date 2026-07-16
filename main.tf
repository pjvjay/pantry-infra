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
# Shared platform (AKS, ArgoCD install, ingress-nginx, cert-manager,
# CNPG operator, External Secrets Operator) is provisioned by
# lifeguide-infra and only *referenced* here via data sources —
# this stack can't break it.
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
