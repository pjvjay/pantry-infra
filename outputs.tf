output "db_password_secret_name" {
  description = "Key Vault entry the gitops ExternalSecrets reference."
  value       = azurerm_key_vault_secret.pantry_db_password.name
}

output "root_application" {
  description = "The ArgoCD root Application seeded by this stack."
  value       = "pantry-root (namespace argocd)"
}

output "app_url" {
  description = "Where the app lands once ArgoCD converges."
  value       = "https://lifeguide-dev-67c717e5.canadacentral.cloudapp.azure.com/pantry/"
}
