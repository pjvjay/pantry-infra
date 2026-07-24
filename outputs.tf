output "db_password_secret_name" {
  description = "Key Vault entry the gitops ExternalSecrets reference."
  value       = azurerm_key_vault_secret.pantry_db_password.name
}

output "root_application" {
  description = "The ArgoCD root Application seeded by this stack."
  value       = "pantry-root (namespace argocd)"
}

output "app_url" {
  description = "Where the app lands once ArgoCD converges (path prefix on the cluster's ingress host)."
  value       = "https://<your-cluster-ingress-host>/pantry/"
}
